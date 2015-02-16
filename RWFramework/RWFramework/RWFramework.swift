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
import WebKit
import AVFoundation
import SystemConfiguration

private let _RWFrameworkSharedInstance = RWFramework()

public class RWFramework: NSObject {

// MARK: Properties

    /// A list of delegates that conform to RWFrameworkProtocol (see RWFrameworkProtocol.swift)
    public var delegates: NSHashTable = NSHashTable.weakObjectsHashTable()

    // Location (see RWFrameworkCoreLocation.swift)
    let locationManager: CLLocationManager = CLLocationManager()
    var lastRecordedLocation: CLLocation = CLLocation()
    var letFrameworkRequestWhenInUseAuthorizationForLocation = true

    // Audio - Stream (see RWFrameworkAudioPlayer.swift)
    var streamURL: NSURL? = nil
    var streamID = 0
    var player: AVPlayer? = nil {
        willSet {
            self.player?.currentItem?.removeObserver(self, forKeyPath: "timedMetadata")
        }
        didSet {
            self.player?.currentItem?.addObserver(self, forKeyPath: "timedMetadata", options: NSKeyValueObservingOptions.New, context: nil)
        }
    }
    /// True if the player (streamer) is currently playing (streaming)
    public var isPlaying = false

    // Audio - Record (see RWFrameworkAudioRecorder.swift)
    /// RWFrameworkAudioRecorder.swift calls code in RWFrameworkAudioRecorder.m to perform recording when true
    let useComplexRecordingMechanism = true
    var soundRecorder: AVAudioRecorder? = nil
    var soundPlayer: AVAudioPlayer? = nil

    // Media - Audio/Text/Image/Movie (see RWFrameworkMedia.swift)
    var mediaArray: Array<Media> = Array<Media>() {
        willSet {
            let data = NSKeyedArchiver.archivedDataWithRootObject(newValue)
            RWFrameworkConfig.setConfigValue("mediaArray", value: data, group: RWFrameworkConfig.ConfigGroup.Client)
        }
        didSet {
            rwUpdateApplicationIconBadgeNumber(mediaArray.count)
        }
    }

    // Flags
    var postUsersSucceeded = false
    var postSessionsSucceeded = false
    var getProjectsIdSucceeded = false
    var getProjectsIdTagsSucceeded = false {
        didSet {
            if getProjectsIdTagsSucceeded && requestStreamSucceeded {
                timeToSendTheListenTags = true
            }
        }
    }
    var requestStreamInProgress = false
    var requestStreamSucceeded = false {
        didSet {
            if getProjectsIdTagsSucceeded && requestStreamSucceeded {
                timeToSendTheListenTags = true
            }
        }
    }
    var timeToSendTheListenTagsOnceToken: dispatch_once_t = 0
    var timeToSendTheListenTags = false {
        didSet {
            if timeToSendTheListenTags {
                dispatch_once(&timeToSendTheListenTagsOnceToken, { () -> Void in
                    self.println("Submitting Listen Tags (timeToSendTheListenTags)")
                    self.submitListenTags()
                })
            }
        }
    }

    // Timers (see RWFrameworkTimers.swift)
    var heartbeatTimer: NSTimer? = nil
    var audioTimer: NSTimer? = nil
    var uploadTimer: NSTimer? = nil

    // Media - Upload (see RWFrameworkMediaUploader.swift)
    var uploaderActive: Bool = true
    var uploaderUploading: Bool = false

    // Misc
    var reverse_domain = "roundware.org" // This will be replaced once the config data is loaded

// MARK: - Main

    /// Returns the shared instance of the framework
    public class var sharedInstance: RWFramework {
        return _RWFrameworkSharedInstance
    }

    private override init() {
        super.init()

        #if DEBUG
            println("RWFramework is running in debug mode")
        #endif

        mediaArray = loadMediaArray()
        rwUpdateApplicationIconBadgeNumber(mediaArray.count)
        
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone // This is updated later once getProjectsIdSuccess is called
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = CLActivityType.Fitness
        locationManager.pausesLocationUpdatesAutomatically = true

        addAudioInterruptionNotification()
    }

    deinit {
        self.player?.currentItem?.removeObserver(self, forKeyPath: "timedMetadata")
    }

    /// Start kicks everything else off - call this to start the framework running.
    /// Pass false for letFrameworkRequestWhenInUseAuthorizationForLocation if the caller would rather call requestWhenInUseAuthorizationForLocation() any time after rwGetProjectsIdSuccess is called.
    public func start(letFrameworkRequestWhenInUseAuthorizationForLocation: Bool = true) {
        if (!compatibleOS()) { println("RWFramework requires iOS 8 or later"); return }
        if (!hostIsReachable()) { println("RWFramework requires network connectivity"); return }

        self.letFrameworkRequestWhenInUseAuthorizationForLocation = letFrameworkRequestWhenInUseAuthorizationForLocation

        println("start")
        apiPostUsers(UIDevice().identifierForVendor.UUIDString, client_type: UIDevice().model)

        preflightRecording()
    }

    /// Call this if you know you are done with the framework
    public func end() {
        removeAllDelegates()
        println("end")
    }


// MARK: - AVAudioSession

    func addAudioInterruptionNotification() {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "handleAudioInterruption:",
            name: AVAudioSessionInterruptionNotification,
            object: nil)
    }

    func handleAudioInterruption(notification: NSNotification) {
        if notification.name != AVAudioSessionInterruptionNotification
            || notification.userInfo == nil {
            return
        }
        var info = notification.userInfo!
        var intValue: UInt = 0
        (info[AVAudioSessionInterruptionTypeKey] as! NSValue).getValue(&intValue)
        if let type = AVAudioSessionInterruptionType(rawValue: intValue) {
            switch type {
            case .Began:
                // interruption began
                println("handleAudioInterruption began")
                pause()
                stopPlayback()
                stopRecording()
            case .Ended:
                // interruption ended
                println("handleAudioInterruption ended")
            }
        }
    }

// MARK: - Utilities

    /// Returns true if the framework is running on a compatible OS
    func compatibleOS() -> Bool {
        var iOS8OrLater: Bool = NSProcessInfo().isOperatingSystemAtLeastVersion(NSOperatingSystemVersion(majorVersion: 8, minorVersion: 0, patchVersion: 0))
        return iOS8OrLater
    }

    /// This method will try to call through to the delegate first, if not it will fall back (via rwUpdateStatus) to displaying an alert
    func alertOK(title: String, message: String) {
        rwUpdateStatus(title + ": " + message)
    }

    /// Shorthand for NSLocalizedString
    func LS(key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }

    /// Return the client string as "iPhone OS-8.3" or similar
    func clientSystem() -> String {
        let systemName = UIDevice().systemName
        let systemVersion = UIDevice().systemVersion
        return "\(systemName)-\(systemVersion)"
    }

    /// Return the preferred language of the device
    func preferredLanguage() -> String {
        return NSLocale.preferredLanguages()[0] as! String
    }

    /// Convert a Double to a String but return an empty string if the Double is 0
    func doubleToStringWithZeroAsEmptyString(d: Double) -> String {
        return (d == 0) ? "" : d.description
    }

    /// println when debugging
    func println(object: Any) {
        debugPrintln(object)
    }

    /// Generic logging method
    func log<T>(object: T) {
        println(object)
    }

    /// Log to server
    public func logToServer(event_type: String, data: String? = "") {
        apiPostEvents(event_type, data: data, success: { (data) -> Void in
            self.println("LOGGED TO SERVER: \(event_type)")
        }) { (error) -> Void in
            self.println("ERROR LOGGING TO SERVER \(error)")
        }
    }

    /// Return true if we have a network connection
    func hostIsReachable(ip_address: String = "8.8.8.8") -> Bool {
        if let host_name = ip_address.cStringUsingEncoding(NSASCIIStringEncoding) {
            let reachability  = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, host_name).takeRetainedValue()
            var flags: SCNetworkReachabilityFlags = 0
            if SCNetworkReachabilityGetFlags(reachability, &flags) == 0 {
                return false
            }
            let isReachable = (flags & UInt32(kSCNetworkFlagsReachable)) != 0
            let needsConnection = (flags & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
            return (isReachable && !needsConnection)
        }
        return false
    }

    /// Return debug information as plain text
    public func debugInfo() -> String {
        var s = ""

        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.Client).stringValue
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

}