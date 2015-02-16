//
//  RWFrameworkConfig.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/2/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation

public class RWFrameworkConfig {

    public enum ConfigGroup : Printable {
        case Client
        case Device
        case Notifications
        case Session
        case Project
        case Server
        case Speakers
        case AudioTracks

        public var description : String {
            switch self {
                case .Client: return "client"
                case .Device: return "device"
                case .Notifications: return "notifications"
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
        let array = JSON(data: data) // JSON returned as an Array of Dictionarys
        for (index: String, dict: JSON) in array {
            for (key: String, value: JSON) in dict {
                NSUserDefaults.standardUserDefaults().setObject(value.object, forKey: key)
            }
        }
    }

    /// Passed JSON data, this function saves that data to NSUserDefaults
    public class func setConfigDataAsDictionary(data: NSData, key: String) {
        let dict = JSON(data: data) // JSON returned as a Dictionary

        // Convert NSNull into empty strings so they can be written to NSUserDefaults properly
        var md = dict.object as! Dictionary<String, AnyObject>
        for (k, v) in md {
            if (v is NSNull) {
                md[k] = ""
            }
        }

        NSUserDefaults.standardUserDefaults().setObject(md, forKey: key)
    }

    /// Set a config value as a Bool in a particular group, creating it if it doesn't exist
    /// Group defaults to ConfigGroup.Client
    public class func setConfigValue(key: String, value: Bool, group: ConfigGroup = ConfigGroup.Client) {
        var d = getConfigGroup(group)
        d[key] = NSNumber(bool: value)
        setConfigGroup(group, value: d)
    }

    /// Set a config value as an NSNumber in a particular group, creating it if it doesn't exist
    /// Group defaults to ConfigGroup.Client
    public class func setConfigValue(key: String, value: NSNumber, group: ConfigGroup = ConfigGroup.Client) {
        var d = getConfigGroup(group)
        d[key] = value
        setConfigGroup(group, value: d)
    }

    /// Set a config value as a String in a particular group, creating it if it doesn't exist
    /// Group defaults to ConfigGroup.Client
    public class func setConfigValue(key: String, value: String, group: ConfigGroup = ConfigGroup.Client) {
        var d = getConfigGroup(group)
        d[key] = value
        setConfigGroup(group, value: d)
    }

    /// Set a config value as an AnyObject in a particular group, creating it if it doesn't exist
    /// Group defaults to ConfigGroup.Client
    public class func setConfigValue(key: String, value: AnyObject, group: ConfigGroup = ConfigGroup.Client) {
        var d = getConfigGroup(group)
        d[key] = value
        setConfigGroup(group, value: d)
    }

// MARK: get

    /// After the rwGetProjectsIdSuccess delegate method is sent you can call this method to get the project data
    public class func getConfigDataFromGroup(group: ConfigGroup = ConfigGroup.Project) -> AnyObject? {
        return NSUserDefaults.standardUserDefaults().objectForKey(group.description)
    }

    /// Get a config value as a Bool
    /// Group defaults to ConfigGroup.Project
    public class func getConfigValueAsBool(key: String, group: ConfigGroup = ConfigGroup.Project) -> Bool {
        if let value: AnyObject = getConfigValue(key, group: group) {
            return (value as! NSNumber).boolValue
        } else {
            return false
        }
    }

    /// Get a config value as an NSNumber
    /// Group defaults to ConfigGroup.Project
    public class func getConfigValueAsNumber(key: String, group: ConfigGroup = ConfigGroup.Project) -> NSNumber {
        if let value: AnyObject = getConfigValue(key, group: group) {
            return (value as! NSNumber)
        } else {
            return 0 as NSNumber
        }
    }

    /// Get a config value as a String
    /// Group defaults to ConfigGroup.Project
    public class func getConfigValueAsString(key: String, group: ConfigGroup = ConfigGroup.Project) -> String {
        if let value: AnyObject = getConfigValue(key, group: group) {
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
        if let g: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey(group.description) {
            if let v: AnyObject = g.valueForKey(key) {
                return v
            }
        }

        // Load the RWFramework.plist the first time we need to access it
        if defaults == nil {
            if let path = NSBundle.mainBundle().pathForResource("RWFramework", ofType: "plist"),
                dict = NSDictionary(contentsOfFile: path) as? Dictionary<String, AnyObject> {
                    RWFrameworkConfig.defaults = dict
            }
        }

        // If nothing found, use local defaults
        if let defaults = self.defaults {
            if let value: AnyObject = defaults.valueForKey(key) {
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
        var value: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey(group.description)
        if value == nil {
            value = [String:AnyObject]()
        }
        return value as! [String:AnyObject]
    }

    /// Set the entire group (usually after being edited)
    internal class func setConfigGroup(group: ConfigGroup, value: [String:AnyObject]) {
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: group.description)
    }
}