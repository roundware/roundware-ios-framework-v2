//
//  RWFrameworkTags.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/12/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation

extension RWFramework {

// MARK: get/set tags/values
/*
        var a: AnyObject? = getListenTags() // if needed to get various codes, etc.
        var b: AnyObject? = getListenTagsCurrent("gender")
        var ba = (b as? NSArray) as Array?
        if (ba != nil) {
            ba!.append(5)
            setListenTagsCurrent("gender", value: ba!)
        }
        var c: AnyObject? = getListenTagsCurrent("gender")
        println("\(b) \(c)")
*/

// MARK: Listen Tags

//    /// Returns an array of dictionaries of listen information
//    public func getListenTags() -> AnyObject? {
//        return NSUserDefaults.standardUserDefaults().objectForKey("tags_listen")
//    }
//
//    /// Sets the array of dictionaries as listen information
//    public func setListenTags(value: AnyObject) {
//        NSUserDefaults.standardUserDefaults().setObject(value, forKey: "tags_listen")
//    }
//
//    /// Get the current values for the listen tags code
//    public func getListenTagsCurrent(code: String) -> AnyObject? {
//        let defaultsKeyName = "tags_listen_\(code)_current"
//        return NSUserDefaults.standardUserDefaults().objectForKey(defaultsKeyName)
//    }
//
//    /// Set the current values for the listen tags code
//    public func setListenTagsCurrent(code: String, value: AnyObject) {
//        let defaultsKeyName = "tags_listen_\(code)_current"
//        NSUserDefaults.standardUserDefaults().setObject(value, forKey: defaultsKeyName)
//    }
//
//    /// Get all the current values for the listen tags
//    public func getAllListenTagsCurrent() -> AnyObject? {
//        var allListenTagsCurrentArray = [AnyObject]()
//        if let listenTagsArray = getListenTags() as! NSArray? {
//            for d in listenTagsArray {
//                let code = d["code"] as! String
//                if let tagsForCode = getListenTagsCurrent(code) as! [AnyObject]? {
//                    allListenTagsCurrentArray += tagsForCode
//                }
//            }
//        }
//        return allListenTagsCurrentArray
//    }
//
//    /// Get all the current values for the listen tags as a comma-separated string
//    public func getAllListenTagsCurrentAsString() -> String {
//        var tag_ids = ""
//        if let allListenTagsArray = getAllListenTagsCurrent() as! NSArray? {
//            for tag in allListenTagsArray {
//                if (tag_ids != "") { tag_ids += "," }
//                tag_ids += tag.description
//            }
//        }
//        return tag_ids
//    }

// MARK: Speak Tags

    /// Returns an array of dictionaries of speak information
    public func getSpeakTags() -> AnyObject? {
        return NSUserDefaults.standardUserDefaults().objectForKey("tags_speak")
    }

    /// Sets the array of dictionaries of speak information
    public func setSpeakTags(value: AnyObject) {
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: "tags_speak")
    }

    /// Get the current values for the speak tags code
    public func getSpeakTagsCurrent(code: String) -> AnyObject? {
        let defaultsKeyName = "tags_speak_\(code)_current"
        return NSUserDefaults.standardUserDefaults().objectForKey(defaultsKeyName)
    }

    /// Set the current values for the speak tags code
    public func setSpeakTagsCurrent(code: String, value: AnyObject) {
        let defaultsKeyName = "tags_speak_\(code)_current"
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: defaultsKeyName)
    }

    /// Get all the current values for the speak tags
    public func getAllSpeakTagsCurrent() -> AnyObject? {
        var allSpeakTagsCurrentArray = [AnyObject]()
        if let speakTagsArray = getSpeakTags() as! NSArray? {
            for d in speakTagsArray {
                let code = d["code"] as! String
                if let tagsForCode = getSpeakTagsCurrent(code) as! [AnyObject]? {
                    allSpeakTagsCurrentArray += tagsForCode
                }
            }
        }
        return allSpeakTagsCurrentArray
    }

    /// Get all the current values for the speak tags as a comma-separated string
    public func getAllSpeakTagsCurrentAsString() -> String {
        if let allSpeakTagsArray = getAllSpeakTagsCurrent() as! NSArray? {
            var tags = ""
            for tag in allSpeakTagsArray {
                if (tags != "") { tags += "," }
                tags += tag.description
            }
            return tags
        }
        return ""
    }

// MARK: submit tags

    /// Submit all current listen tags to the server
//    public func submitListenTags() {
//        let tag_ids = getAllListenTagsCurrentAsString()
//        apiPatchStreamsIdWithTags(tag_ids)
//    }
    
    public func submitTags(tagIdsAsString: String) {
        apiPatchStreamsIdWithTags(tagIdsAsString)
    }


// MARK: edit tags
//
//    /// Edit the Listen tags in a web view
//    public func editListenTags() {
//        editTags("tags_listen", title:LS("Listen Tags"))
//    }
//
//    /// Edit the Speak tags in a web view
//    public func editSpeakTags() {
//        editTags("tags_speak", title:LS("Speak Tags"))
//    }
//
//    /// Edit the Listen or Speak tags in a web view
//    func editTags(type: String, title: String) {
//        println("editing tags not yet supported but coming soon via WKWebView")
//    }

}