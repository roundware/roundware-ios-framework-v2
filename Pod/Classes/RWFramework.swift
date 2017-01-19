
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

let _RWFrameworkSharedInstance = RWFramework()
import Foundation

#if swift(>=3.0)
    typealias HashTable<ObjectType: AnyObject> = NSHashTable<ObjectType>
#else
    struct HashTable<ObjectType: AnyObject> {

    private let _table = NSHashTable.weakObjectsHashTable()

    static func weakObjects() -> HashTable<ObjectType> {
    return HashTable<ObjectType>()
    }

    var count: Int {
    return _table.count
    }

    func member(object: ObjectType?) -> ObjectType? {
    return _table.member(object) as? ObjectType
    }

    func add(object: ObjectType?) {
    _table.addObject(object)
    }

    func remove(object: ObjectType?) {
    _table.removeObject(object)
    }

    func removeAllObjects() {
    _table.removeAllObjects()
    }

    var allObjects: [ObjectType] {
    return unsafeBitCast(_table.allObjects, [ObjectType].self)
    }

    var anyObject: ObjectType? {
    return _table.anyObject as? ObjectType
    }

    func contains(object: ObjectType?) -> Bool {
    return _table.containsObject(object)
    }
    }

    extension HashTable: SequenceType {

    func generate() -> NSFastGenerator {
    return _table.objectEnumerator().generate()
    }
    }

    extension HashTable: CustomStringConvertible {

    var description: String {
    var string = "\(self.dynamicType) {\n"
    _table.allObjects.enumerate().forEach { idx, obj in
    string += "[\(idx)] \(obj)\n"
    }
    string += "}"
    return string
    }
    }
#endif

public class RWFramework: NSObject {

// MARK: Properties

    /// A list of delegates that conform to RWFrameworkProtocol (see RWFrameworkProtocol.swift)
    //TODO
//    public var delegates: NSHashTable = NSHashTable.weakObjectsHashTable()
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
            self.player?.currentItem?.addObserver(self, forKeyPath: "timedMetadata", options: NSKeyValueObservingOptions.new, context: nil)
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
            let data = NSKeyedArchiver.archivedData(withRootObject: newValue) as AnyObject
            RWFrameworkConfig.setConfigValue(key: "mediaArray", value: data, group: RWFrameworkConfig.ConfigGroup.Client)
        }
        didSet {
            rwUpdateApplicationIconBadgeNumber(count: mediaArray.count)
        }
    }

    // Flags
    var postUsersSucceeded = false
    var postSessionsSucceeded = false
    var getProjectsIdSucceeded = false
    var getProjectsIdTagsSucceeded = false {
        didSet {
            if getProjectsIdTagsSucceeded && requestStreamSucceeded {
//                timeToSendTheListenTags = true
            }
        }
    }
    var requestStreamInProgress = false
    var requestStreamSucceeded = false {
        didSet {
            if getProjectsIdTagsSucceeded && requestStreamSucceeded {
//                timeToSendTheListenTags = true
            }
        }
    }

//    var timeToSendTheListenTagsOnceToken: dispatch_once_t = 0
//    var timeToSendTheListenTags = false {
//        didSet {
//            if timeToSendTheListenTags {
//                dispatch_once(&timeToSendTheListenTagsOnceToken, { () -> Void in
////                    self.println("Submitting Listen Tags (timeToSendTheListenTags)")
////                    self.submitListenTags()
//                })
//            }
//        }
//    }

    // Timers (see RWFrameworkTimers.swift)
    var heartbeatTimer: Timer? = nil
    var audioTimer: Timer? = nil
    var uploadTimer: Timer? = nil

    // Media - Upload (see RWFrameworkMediaUploader.swift)
    var uploaderActive: Bool = true
    var uploaderUploading: Bool = false

    // Misc
    var reverse_domain = "org.roundware"

// MARK: - Main

    /// Returns the shared instance of the framework
    public class var sharedInstance: RWFramework {
        return _RWFrameworkSharedInstance
    }

    override init() {
        super.init()

        #if DEBUG
            println("RWFramework is running in debug mode")
        #endif

        mediaArray = loadMediaArray()
        rwUpdateApplicationIconBadgeNumber(count: mediaArray.count)

        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone // This is updated later once getProjectsIdSuccess is called
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = CLActivityType.fitness
        locationManager.pausesLocationUpdatesAutomatically = true

        addAudioInterruptionNotification()
    }

    deinit {
        self.player?.currentItem?.removeObserver(self, forKeyPath: "timedMetadata")
    }

    /// Start kicks everything else off - call this to start the framework running.
    /// Pass false for letFrameworkRequestWhenInUseAuthorizationForLocation if the caller would rather call requestWhenInUseAuthorizationForLocation() any time after rwGetProjectsIdSuccess is called.
    public func start(letFrameworkRequestWhenInUseAuthorizationForLocation: Bool = true) {
        if (!compatibleOS()) { println(object: "RWFramework requires iOS 8 or later"); return }
        if (!hostIsReachable()) { println(object: "RWFramework requires network connectivity"); return }

        self.letFrameworkRequestWhenInUseAuthorizationForLocation = letFrameworkRequestWhenInUseAuthorizationForLocation

        println(object: "start")
        apiPostUsers(device_id: UIDevice().identifierForVendor!.uuidString, client_type: UIDevice().model)

        //preflightRecording()
    }


    /// Call this if you know you are done with the framework
    public func end() {
        removeAllDelegates()
        println(object: "end")
    }


// MARK: - AVAudioSession

    func addAudioInterruptionNotification() {
        NotificationCenter.default.addObserver(self,
            selector: "handleAudioInterruption:",
            name: NSNotification.Name.AVAudioSessionInterruption,
            object: nil)
    }

    func handleAudioInterruption(notification: NSNotification) {
        if notification.name != NSNotification.Name.AVAudioSessionInterruption
            || notification.userInfo == nil {
            return
        }
        var info = notification.userInfo!
        var intValue: UInt = 0
        (info[AVAudioSessionInterruptionTypeKey] as! NSValue).getValue(&intValue)
        if let type = AVAudioSessionInterruptionType(rawValue: intValue) {
            switch type {
            case .began:
                // interruption began
                println(object: "handleAudioInterruption began")
                pause()
                stopPlayback()
                stopRecording()
            case .ended:
                // interruption ended
                println(object: "handleAudioInterruption ended")
            }
        }
    }

// MARK: - Utilities

    /// Sets ProjectId in case you need to change it in the app
    public func setProjectId(project_id: String){
        RWFrameworkConfig.setConfigValue(key: "project_id", value: project_id)
        apiGetProjectsId(project_id: project_id, session_id: RWFrameworkConfig.getConfigValueAsNumber(key: "session_id", group: RWFrameworkConfig.ConfigGroup.Client).stringValue
        )
    }

    /// Returns true if the framework is running on a compatible OS
    func compatibleOS() -> Bool {
        let iOS8OrLater: Bool = ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 8, minorVersion: 0, patchVersion: 0))
        return iOS8OrLater
    }

    /// This method will try to call through to the delegate first, if not it will fall back (via rwUpdateStatus) to displaying an alert
    func alertOK(title: String, message: String) {
        rwUpdateStatus(message: title + ": " + message)
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
        //https://developer.apple.com/library/ios/technotes/tn2418/_index.html
        let language = NSLocale.preferredLanguages[0]
        let languageArr = language.characters.split{$0 == "-"}.map(String.init)
        return languageArr[0]
    }

    /// Convert a Double to a String but return an empty string if the Double is 0
    func doubleToStringWithZeroAsEmptyString(d: Double) -> String {
        return (d == 0) ? "" : d.description
    }

    /// println when debugging
    func println(object: Any) {
        debugPrint(object)
    }

    /// Generic logging method
    func log<T>(object: T) {
        println(object: object)
    }

    /// Log to server
    public func logToServer(event_type: String, data: String? = "") {
        apiPostEvents(event_type: event_type, data: data, success: { (data) -> Void in
            self.println(object: "LOGGED TO SERVER: \(event_type)")
        }) { (error) -> Void in
            self.println(object: "ERROR LOGGING TO SERVER \(error)")
        }
    }

    /// Return true if we have a network connection
    func hostIsReachable(ip_address: String = "8.8.8.8") -> Bool {
        if let host_name = ip_address.cString(using: String.Encoding.ascii) {
            let reachability  = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, host_name)
            var flags: SCNetworkReachabilityFlags = []
            if !SCNetworkReachabilityGetFlags(reachability!, &flags) {
                return false
            }

            let isReachable = flags.contains(.reachable)
            let needsConnection = flags.contains(.connectionRequired)
            return (isReachable && !needsConnection)
        }
        return false
    }

    /// Return debug information as plain text
    public func debugInfo() -> String {
        var s = ""

        let session_id = RWFrameworkConfig.getConfigValueAsNumber(key: "session_id", group: RWFrameworkConfig.ConfigGroup.Client).stringValue
        let latitude = doubleToStringWithZeroAsEmptyString(d: lastRecordedLocation.coordinate.latitude)
        let longitude = doubleToStringWithZeroAsEmptyString(d: lastRecordedLocation.coordinate.longitude)

        s += "session_id = \(session_id)\n"
        s += "latitude = \(latitude)\n"
        s += "longitude = \(longitude)\n"
        s += "queue items = \(mediaArray.count)\n"
        s += "uploaderActive = \(uploaderActive)\n"
        s += "uploaderUploading = \(uploaderUploading)\n"

        return s
    }

}
