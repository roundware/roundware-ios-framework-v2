//
//  RWFramework.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 1/25/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import CoreMotion
import WebKit
import AVFoundation
import SystemConfiguration
import Promises

private let _RWFrameworkSharedInstance = RWFramework()

open class RWFramework: NSObject {

private lazy var __once: () = { () -> Void in
                    self.println("Submitting Listen Tags (timeToSendTheListenTags)")
                    self.submitListenIDsSetAsTags() //self.submitListenTags()
                }()

// MARK: Properties

    /// A list of delegates that conform to RWFrameworkProtocol (see RWFrameworkProtocol.swift)
    open var delegates: NSHashTable<AnyObject> = NSHashTable.weakObjects()

    let motionManager = CMMotionManager()
    
    // Location (see RWFrameworkCoreLocation.swift)
    let locationManager: CLLocationManager = CLLocationManager()
    var streamOptions = StreamParams(
        location: CLLocation(),
        minDist: nil,
        maxDist: nil,
        heading: nil,
        angularWidth: nil
    )
    var lastRecordedLocation: CLLocation {
        return self.streamOptions.location
    }
    var letFrameworkRequestWhenInUseAuthorizationForLocation = true

    public let playlist = Playlist(filters: [
        // Accept an asset if one of the following conditions is true
        AnyAssetFilters([
            // if an asset is scheduled to play right now
            TimedAssetFilter(),
            // If an asset has a shape and we AREN'T in it, reject entirely.
            AssetShapeFilter(),
            // if it has no shape, consider a fixed distance from it
            DistanceFixedFilter(),
            // or a user-specified distance range
            AllAssetFilters([DistanceRangesFilter(), AngleFilter()]),
        ]),
        // only repeat assets if there's no other choice
        TimedRepeatFilter(),
        // skip blocked assets and users
        BlockedAssetsFilter(),
        // all the tags on an asset must be in our list of tags to listen for
        AnyTagsFilter(),
        // if any track-level tag filters exist, apply them
        TrackTagsFilter(),
        DynamicTagFilter("_ten_most_recent_days", MostRecentFilter(days: 10))
    ], sortBy: [
        SortRandomly(),
        SortByLikes(),
    ])
    
    static let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .flexibleISO
        return dec
    }()
    
    static let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .formatted(.iso8601Full)
        return enc
    }()

    // Audio - Record (see RWFrameworkAudioRecorder.swift)
    /// RWFrameworkAudioRecorder.swift calls code in RWFrameworkAudioRecorder.m to perform recording when true
    let useComplexRecordingMechanism = false
    public var soundRecorder: AVAudioRecorder? = nil
    var soundPlayer: AVAudioPlayer? = nil

    // Media - Audio/Text/Image/Movie (see RWFrameworkMedia.swift)
    var mediaArray: Array<Media> = [Media]() {
        willSet {
            let data = NSKeyedArchiver.archivedData(withRootObject: newValue)
            RWFrameworkConfig.setConfigValue("mediaArray", value: data as AnyObject, group: RWFrameworkConfig.ConfigGroup.client)
        }
        didSet {
            rwUpdateApplicationIconBadgeNumber(mediaArray.count)
        }
    }

    // Flags
    var postSessionsSucceeded = false
    var getProjectsIdTagsSucceeded = false {
        didSet {
            if getProjectsIdTagsSucceeded {
                timeToSendTheListenTags = true
            }
        }
    }
    var getProjectsIdUIGroupsSucceeded = false
    var getTagCategoriesSucceeded = false
    var getUIConfigSucceeded = false
    var timeToSendTheListenTags = false {
        didSet {
            if timeToSendTheListenTags {
                _ = self.__once
            }
        }
    }

    // Timers (see RWFrameworkTimers.swift)
    var audioTimer: Timer? = nil
    var uploadTimer: Timer? = nil

    // Media - Upload (see RWFrameworkMediaUploader.swift)
    var uploaderActive: Bool = true
    var uploaderUploading: Bool = false

    // Misc
    var reverse_domain = "roundware.org" // This will be replaced once the config data is loaded

// MARK: - Main

    /// Returns the shared instance of the framework
    open class var sharedInstance: RWFramework {
        return _RWFrameworkSharedInstance
    }

    public override init() {
        super.init()

        #if DEBUG
            println("RWFramework is running in debug mode")
        #endif

        mediaArray = loadMediaArray()
        rwUpdateApplicationIconBadgeNumber(mediaArray.count)
        
        // setup location updates
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone // This is updated later once getProjectsIdSuccess is called
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = CLActivityType.fitness
        locationManager.pausesLocationUpdatesAutomatically = true

        addAudioInterruptionNotification()
    }

    /// Start kicks everything else off - call this to start the framework running.
    /// - Parameter letFrameworkRequestWhenInUseAuthorizationForLocation: false if the caller would rather call requestWhenInUseAuthorizationForLocation() any time after rwGetProjectsIdSuccess is called.
    open func start(_ letFrameworkRequestWhenInUseAuthorizationForLocation: Bool = true) {
        if (!compatibleOS()) {
            println("RWFramework requires iOS 8 or later")
        } else if (!hostIsReachable()) {
            println("RWFramework requires network connectivity")
        } else {
            self.letFrameworkRequestWhenInUseAuthorizationForLocation = letFrameworkRequestWhenInUseAuthorizationForLocation
            
            self.playlist.start()

            preflightRecording()
        }
    }

    /// Call this if you know you are done with the framework
    open func end() {
        removeAllDelegates()
        println("end")
    }


// MARK: - AVAudioSession

    func addAudioInterruptionNotification() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(RWFramework.handleAudioInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil)
    }

    @objc func handleAudioInterruption(_ notification: Notification) {
        if notification.name != AVAudioSession.interruptionNotification
            || notification.userInfo == nil {
            return
        }
        var info = notification.userInfo!
        var intValue: UInt = 0
        (info[AVAudioSessionInterruptionTypeKey] as! NSValue).getValue(&intValue)
        if let type = AVAudioSession.InterruptionType(rawValue: intValue) {
            switch type {
            case .began:
                // interruption began
                println("handleAudioInterruption began")
                pause()
                stopPlayback()
                stopRecording()
            case .ended:
                // interruption ended
                println("handleAudioInterruption ended")
            }
        }
    }

// MARK: - Utilities

    /// Returns true if the framework is running on a compatible OS
    func compatibleOS() -> Bool {
        let iOS8OrLater: Bool = ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 8, minorVersion: 0, patchVersion: 0))
        return iOS8OrLater
    }

    /// This method will try to call through to the delegate first, if not it will fall back (via rwUpdateStatus) to displaying an alert
    func alertOK(_ title: String, message: String) {
        rwUpdateStatus(title + ": " + message)
    }

    /// Shorthand for NSLocalizedString
    func LS(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }

    /// Return the client string as "iOS 8.3" or similar
    func clientSystem() -> String {
        let systemName = UIDevice().systemName
        let systemVersion = UIDevice().systemVersion
        return "\(systemName) \(systemVersion)"
    }

    /// Return the preferred language of the device
    func preferredLanguage() -> String {
        let preferredLanguage = Locale.preferredLanguages[0] as String
        let arr = preferredLanguage.components(separatedBy: "-")
        if let deviceLanguage = arr.first {
            return deviceLanguage
        }
        return "en"
    }

    /// Convert a Double to a String but return an empty string if the Double is 0
    func doubleToStringWithZeroAsEmptyString(_ d: Double) -> String {
        return (d == 0) ? "" : d.description
    }

    /// println when debugging
    func println(_ object: Any) {
        debugPrint(object)
    }

    /// Generic logging method
    func log<T>(_ object: T) {
        println(object)
    }

    /// Log to server
    open func logToServer(_ event_type: String, data: String? = "") {
        apiPostEvents(event_type, data: data).then { data in
            self.println("LOGGED TO SERVER: \(event_type)")
        }.catch { error in
            self.println("ERROR LOGGING TO SERVER \(error)")
        }
    }

    /// Return true if we have a network connection
    func hostIsReachable(_ ip_address: String = "8.8.8.8") -> Bool {
        return true
// TODO: FIX
//        if let host_name = ip_address.cStringUsingEncoding(NSASCIIStringEncoding) {
//            let reachability  = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, host_name).takeRetainedValue()
//            var flags: SCNetworkReachabilityFlags = 0
//            if SCNetworkReachabilityGetFlags(reachability, &flags) == 0 {
//                return false
//            }
//            let isReachable = (flags & UInt32(kSCNetworkFlagsReachable)) != 0
//            let needsConnection = (flags & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
//            return (isReachable && !needsConnection)
//        }
//        return false
    }

    /// Return debug information as plain text
    open func debugInfo() -> String {
        var s = ""

        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.client).stringValue
        let latitude = doubleToStringWithZeroAsEmptyString(lastRecordedLocation.coordinate.latitude)
        let longitude = doubleToStringWithZeroAsEmptyString(lastRecordedLocation.coordinate.longitude)

        s += "session_id = \(session_id)\n"
        s += "latitude = \(latitude)\n"
        s += "longitude = \(longitude)\n"
        s += "queue items = \(mediaArray.count)\n"
        s += "uploaderActive = \(uploaderActive)\n"
        s += "uploaderUploading = \(uploaderUploading)\n"

        return s
    }
    
    /// Block a specific asset from being played again.
    /// Only works in practice if a `BlockedAssetFilter` is applied.
    public func block(assetId: Int) -> Promise<Void> {
        return apiPostAssetsIdVotes(
            assetId.description,
            vote_type: "block_asset"
        ).then { _ in
            self.playlist.updateFilterData()
        }
    }
    
    public func blockUser(assetId: Int) -> Promise<Void> {
        return apiPostAssetsIdVotes(
            assetId.description,
            vote_type: "block_user"
        ).then { _ in
            self.playlist.updateFilterData()
        }
    }
}

extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension JSONDecoder.DateDecodingStrategy {
    /// Attempts to decode dates with fractional seconds, then without.
    static let flexibleISO = custom {
        let container = try $0.singleValueContainer()
        let s = try container.decode(String.self)
        if let date = DateFormatter.iso8601Full.date(from: s) ?? DateFormatter.iso8601.date(from: s) {
            return date
        }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Invalid date: \(s)"
        )
    }
}
