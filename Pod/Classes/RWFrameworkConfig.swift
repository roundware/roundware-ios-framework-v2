//
//  RWFrameworkConfig.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/2/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation
import SwiftyJSON

public class RWFrameworkConfig {

    public enum ConfigGroup : CustomStringConvertible {
        case Client
        case Device
//        case Notifications
        case Session
        case Project
        case Server
        case Speakers
        case AudioTracks

        public var description : String {
            switch self {
                case .Client: return "client"
                case .Device: return "device"
//                case .Notifications: return "notifications"
                case .Session: return "session"
                case .Project: return "project"
                case .Server: return "server"
                case .Speakers: return "speakers"
                case .AudioTracks: return "audiotracks"
            }
        }
    }

    /// The plist defaults (embedding a struct to workaround no class variables)
    private struct DefaultsStruct { static var defaults: NSDictionary? = nil }

    /// RWFramework.plist defaults (consider using lazy here for get)
    class var defaults: NSDictionary? {
        get { return DefaultsStruct.defaults }
        set { DefaultsStruct.defaults = newValue }
    }

// MARK: set

    /// Passed JSON data, this function saves that data to NSUserDefaults
    public class func setConfigDataAsArrayOfDictionaries(data: NSData) {
        let array = JSON(data: data as Data) // JSON returned as an Array of Dictionarys
        for (_, dict): (String, JSON) in array {
            for (key, value): (String, JSON) in dict {
                UserDefaults.standard.set(value.object, forKey: key)
            }
        }
    }

    /// Passed JSON data, this function saves that data to NSUserDefaults
    public class func setConfigDataAsDictionary(data: NSData, key: String) {
        let dict = JSON(data: data as Data) // JSON returned as a Dictionary

        // Convert NSNull into empty strings so they can be written to NSUserDefaults properly
        var md = dict.object as! Dictionary<String, AnyObject>
        for (k, v) in md {
            if (v is NSNull) {
                md[k] = "" as AnyObject?
            }
        }

        UserDefaults.standard.set(md, forKey: key)
    }

    /// Set a config value as a Bool in a particular group, creating it if it doesn't exist
    /// Group defaults to ConfigGroup.Client
    public class func setConfigValue(key: String, value: Bool, group: ConfigGroup = ConfigGroup.Client) {
        var d = getConfigGroup(group: group)
        d[key] = NSNumber(value: value)
        setConfigGroup(group: group, value: d)
    }

    /// Set a config value as an NSNumber in a particular group, creating it if it doesn't exist
    /// Group defaults to ConfigGroup.Client
    public class func setConfigValue(key: String, value: NSNumber, group: ConfigGroup = ConfigGroup.Client) {
        var d = getConfigGroup(group: group)
        d[key] = value
        setConfigGroup(group: group, value: d)
    }

    /// Set a config value as a String in a particular group, creating it if it doesn't exist
    /// Group defaults to ConfigGroup.Client
    public class func setConfigValue(key: String, value: String, group: ConfigGroup = ConfigGroup.Client) {
        var d = getConfigGroup(group: group)
        d[key] = value as AnyObject?
        setConfigGroup(group: group, value: d)
    }

    /// Set a config value as an AnyObject in a particular group, creating it if it doesn't exist
    /// Group defaults to ConfigGroup.Client
    public class func setConfigValue(key: String, value: AnyObject, group: ConfigGroup = ConfigGroup.Client) {
        var d = getConfigGroup(group: group)
        d[key] = value
        setConfigGroup(group: group, value: d)
    }

// MARK: get

    /// After the rwGetProjectsIdSuccess delegate method is sent you can call this method to get the project data
    public class func getConfigDataFromGroup(group: ConfigGroup = ConfigGroup.Project) -> AnyObject? {
        return UserDefaults.standard.object(forKey: group.description) as AnyObject?
    }

    /// Get a config value as a Bool
    /// Group defaults to ConfigGroup.Project
    public class func getConfigValueAsBool(key: String, group: ConfigGroup = ConfigGroup.Project) -> Bool {
        if let value: AnyObject = getConfigValue(key: key, group: group) {
            return (value as! NSNumber).boolValue
        } else {
            return false
        }
    }

    /// Get a config value as an NSNumber
    /// Group defaults to ConfigGroup.Project
    public class func getConfigValueAsNumber(key: String, group: ConfigGroup = ConfigGroup.Project) -> NSNumber {
        if let value: AnyObject = getConfigValue(key: key, group: group) {
            return (value as! NSNumber)
        } else {
            return 0 as NSNumber
        }
    }

    /// Get a config value as a String
    /// Group defaults to ConfigGroup.Project
    public class func getConfigValueAsString(key: String, group: ConfigGroup = ConfigGroup.Project) -> String {
        if let value: AnyObject = getConfigValue(key: key, group: group) {
            return (value as! String)
        } else {
            return ""
        }
    }

    /// Get a config value as an AnyObject?
    /// This function searches the NSUserDefaults get_config data first
    /// and then falls back to searching the RWFramework.plist contents
    internal class func getConfigValue(key: String, group: ConfigGroup) -> AnyObject? {

        // First check NSUserDefaults for server-based configuration values
        if let g: AnyObject = UserDefaults.standard.object(forKey: group.description) as AnyObject? {
            if let v: AnyObject = g.value!(forKey: key) as AnyObject? {
                return v
            }
        }

        // Load the RWFramework.plist the first time we need to access it
        if defaults == nil {
            if let path = Bundle.main.path(forResource: "RWFramework", ofType: "plist"),
                let dict = NSDictionary(contentsOfFile: path) as? Dictionary<String, AnyObject> {
                    RWFrameworkConfig.defaults = dict as NSDictionary?
            }
        }

        // If nothing found, use local defaults
        if let defaults = self.defaults {
            if let value: AnyObject = defaults.value(forKey: key) as AnyObject? {
                return value
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

// MARK: group get/set

    /// Return the entire group as a Dictionary<String, String> (usually to be edited and set back.)
    /// Will return an empty Dictionary if one does not exist
    internal class func getConfigGroup(group: ConfigGroup) -> [String:AnyObject] {
        var value: AnyObject? = UserDefaults.standard.object(forKey: group.description) as AnyObject?
        if value == nil {
            value = [String:AnyObject]() as AnyObject?
        }
        return value as! [String:AnyObject]
    }

    /// Set the entire group (usually after being edited)
    internal class func setConfigGroup(group: ConfigGroup, value: [String:AnyObject]) {
        UserDefaults.standard.set(value, forKey: group.description)
    }
}
