//
//  RWFrameworkConfig.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/2/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation

open class RWFrameworkConfig {

    public enum ConfigGroup : CustomStringConvertible {
        case client
        case device
        case notifications
        case session
        case project
        case server
        case speakers
        case audioTracks

        public var description : String {
            switch self {
                case .client: return "client"
                case .device: return "device"
                case .notifications: return "notifications"
                case .session: return "session"
                case .project: return "project"
                case .server: return "server"
                case .speakers: return "speakers"
                case .audioTracks: return "audiotracks"
            }
        }
    }

    /// The plist defaults (embedding a struct to workaround no class variables)
    fileprivate struct DefaultsStruct { static var defaults: NSDictionary? = nil }

    /// RWFramework.plist defaults (consider using lazy here for get)
    class var defaults: NSDictionary? {
        get { return DefaultsStruct.defaults }
        set { DefaultsStruct.defaults = newValue }
    }

// MARK: set

    /// Passed JSON data, this function saves that data to NSUserDefaults
    open class func setConfigDataAsDictionary(_ data: Data, key: String) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)

            if var dict = json as? [String: AnyObject] {
                // Convert NSNull into empty strings so they can be written to NSUserDefaults properly
                for (k, v) in dict {
                    if (v is NSNull) {
                        dict[k] = "" as AnyObject?
                    }
                }
                UserDefaults.standard.set(dict, forKey: key)
            }

        }
        catch {
            print(error)
        }
    }

    /// Set a config value as a Bool in a particular group, creating it if it doesn't exist
    /// Group defaults to ConfigGroup.Client
    open class func setConfigValue(_ key: String, value: Bool, group: ConfigGroup = ConfigGroup.client) {
        var d = getConfigGroup(group)
        d[key] = NSNumber(value: value as Bool)
        setConfigGroup(group, value: d)
    }

    /// Set a config value as an NSNumber in a particular group, creating it if it doesn't exist
    /// Group defaults to ConfigGroup.Client
    open class func setConfigValue(_ key: String, value: NSNumber, group: ConfigGroup = ConfigGroup.client) {
        var d = getConfigGroup(group)
        d[key] = value
        setConfigGroup(group, value: d)
    }

    /// Set a config value as a String in a particular group, creating it if it doesn't exist
    /// Group defaults to ConfigGroup.Client
    open class func setConfigValue(_ key: String, value: String, group: ConfigGroup = ConfigGroup.client) {
        var d = getConfigGroup(group)
        d[key] = value as AnyObject?
        setConfigGroup(group, value: d)
    }

    /// Set a config value as an AnyObject in a particular group, creating it if it doesn't exist
    /// Group defaults to ConfigGroup.Client
    open class func setConfigValue(_ key: String, value: AnyObject, group: ConfigGroup = ConfigGroup.client) {
        var d = getConfigGroup(group)
        d[key] = value
        setConfigGroup(group, value: d)
    }

// MARK: get

    /// After the rwGetProjectsIdSuccess delegate method is sent you can call this method to get the project data
    open class func getConfigDataFromGroup(_ group: ConfigGroup = ConfigGroup.project) -> AnyObject? {
        return UserDefaults.standard.object(forKey: group.description) as AnyObject?
    }

    /// Get a config value as a Bool
    /// Group defaults to ConfigGroup.Project
    open class func getConfigValueAsBool(_ key: String, group: ConfigGroup = ConfigGroup.project) -> Bool {
        if let value: NSNumber = getConfigValue(key, group: group) as? NSNumber {
            return value.boolValue
        } else {
            return false
        }
    }

    /// Get a config value as an NSNumber
    /// Group defaults to ConfigGroup.Project
    open class func getConfigValueAsNumber(_ key: String, group: ConfigGroup = ConfigGroup.project) -> NSNumber {
        if let value: NSNumber = getConfigValue(key, group: group) as? NSNumber {
            return value
        } else {
            return 0 as NSNumber
        }
    }

    /// Get a config value as a String
    /// Group defaults to ConfigGroup.Project
    open class func getConfigValueAsString(_ key: String, group: ConfigGroup = ConfigGroup.project) -> String {
        if let value: String = getConfigValue(key, group: group) as? String {
            return value
        } else {
            return ""
        }
    }

    /// Get a config value as an AnyObject?
    /// This function searches the NSUserDefaults get_config data first
    /// and then falls back to searching the RWFramework.plist contents
    internal class func getConfigValue(_ key: String, group: ConfigGroup) -> AnyObject? {
        
        // First check NSUserDefaults for server-based configuration values
        if let g: [String:AnyObject] = UserDefaults.standard.object(forKey: group.description) as? [String:AnyObject] {
            if let v: AnyObject = g[key] {
                return v
            }
        }
        
        // Load the RWFramework.plist the first time we need to access it
        if defaults == nil {
            if let path = Bundle.main.path(forResource: "RWFramework", ofType: "plist"),
                let dict = NSDictionary(contentsOfFile: path) as? Dictionary<String, AnyObject> {
                RWFrameworkConfig.defaults = dict as NSDictionary
            }
        }

        // If nothing found, use local defaults
        if let defaults = self.defaults {
            if let value: AnyObject = defaults.value(forKey: key) as? AnyObject {
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
    internal class func getConfigGroup(_ group: ConfigGroup) -> [String:AnyObject] {
        if let value: [String:AnyObject] = UserDefaults.standard.object(forKey: group.description) as? [String : AnyObject] {
            return value
        } else {
            return [String:AnyObject]()
        }
        
//        var value: AnyObject? = UserDefaults.standard.object(forKey: group.description) as AnyObject
//        if value == nil {
//            value = [String:AnyObject]() as AnyObject
//        }
//        return value as! [String:AnyObject]
    }

    /// Set the entire group (usually after being edited)
    internal class func setConfigGroup(_ group: ConfigGroup, value: [String:AnyObject]) {
        UserDefaults.standard.set(value, forKey: group.description)
    }
}
