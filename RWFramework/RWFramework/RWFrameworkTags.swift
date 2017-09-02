//
//  RWFrameworkTags.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/12/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation

extension RWFramework {

    // Tags
    
    struct Relationship: Codable {
        var id: Int?
        var tag_id: Int?
        var parent_id: Int?
    }
    
    struct Location: Codable {
        var type: String?
        // TODO
    }
    
    struct Tag: Codable {
        var id: Int
        var value: String?
        var description: String?
        var data: String?
        var filter: String?
        //var location: [Location]? // TODO
        var project_id: Int
        var tag_category_id: Int
        var description_loc: String?
        var msg_loc: String?
        var relationships: [Relationship]?
    }
    
    struct TagList : Codable {
        let tags: [Tag]
    }

    // UIGroups
    
    struct UIItem: Codable {
        var id: Int
        var index: Int
        var `default`: Bool // default is a keyword so include in `` to have it seen as not so
        var active: Bool
        var ui_group_id: Int?
        var tag_id: Int?
        var parent_id: Int?
    }
    
    struct UIGroup: Codable {
        var id: Int
        var name: String?
        var ui_mode: String?
        var select: String?
        var active: Bool
        var index: Int
        var header_text_loc: String?
        var tag_category_id: Int
        var project_id: Int
        var ui_items: [UIItem]?
    }
    
    struct UIGroupsList : Codable {
        let ui_groups: [UIGroup]
    }

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
//        return UserDefaults.standard.object(forKey: "tags_listen") as AnyObject?
//    }
//
//    /// Sets the array of dictionaries as listen information
//    public func setListenTags(_ value: AnyObject) {
//        UserDefaults.standard.set(value, forKey: "tags_listen")
//    }
//
//    /// Get the current values for the listen tags code
//    public func getListenTagsCurrent(_ code: String) -> AnyObject? {
//        let defaultsKeyName = "tags_listen_\(code)_current"
//        return UserDefaults.standard.object(forKey: defaultsKeyName) as AnyObject?
//    }
//
//    /// Set the current values for the listen tags code
//    public func setListenTagsCurrent(_ code: String, value: AnyObject) {
//        let defaultsKeyName = "tags_listen_\(code)_current"
//        UserDefaults.standard.set(value, forKey: defaultsKeyName)
//    }
//
//    /// Get all the current values for the listen tags
//    public func getAllListenTagsCurrent() -> AnyObject? {
//        var allListenTagsCurrentArray = [AnyObject]()
//        if let listenTagsArray = getListenTags() as! [[String:String]]? {
//            for d in listenTagsArray {
//                let code = d["code"]
//                if let tagsForCode = getListenTagsCurrent(code!) as! [AnyObject]? {
//                    allListenTagsCurrentArray += tagsForCode
//                }
//            }
//        }
//        return allListenTagsCurrentArray as AnyObject?
//    }
//
//    /// Get all the current values for the listen tags as a comma-separated string
    public func getAllListenTagsCurrentAsString() -> String {
//        var tag_ids = ""
//        if let allListenTagsArray = getAllListenTagsCurrent() as! NSArray? {
//            for tag in allListenTagsArray {
//                if (tag_ids != "") { tag_ids += "," }
//                tag_ids += (tag as AnyObject).description
//            }
//        }
//        return tag_ids
        return ""
    }

// MARK: Speak Tags

//    /// Returns an array of dictionaries of speak information
//    public func getSpeakTags() -> AnyObject? {
//        return UserDefaults.standard.object(forKey: "tags_speak") as AnyObject?
//    }
//
//    /// Sets the array of dictionaries of speak information
//    public func setSpeakTags(_ value: AnyObject) {
//        UserDefaults.standard.set(value, forKey: "tags_speak")
//    }
//
//    /// Get the current values for the speak tags code
//    public func getSpeakTagsCurrent(_ code: String) -> AnyObject? {
//        let defaultsKeyName = "tags_speak_\(code)_current"
//        return UserDefaults.standard.object(forKey: defaultsKeyName) as AnyObject?
//    }
//
//    /// Set the current values for the speak tags code
//    public func setSpeakTagsCurrent(_ code: String, value: AnyObject) {
//        let defaultsKeyName = "tags_speak_\(code)_current"
//        UserDefaults.standard.set(value, forKey: defaultsKeyName)
//    }
//
//    /// Get all the current values for the speak tags
//    public func getAllSpeakTagsCurrent() -> AnyObject? {
//        var allSpeakTagsCurrentArray = [AnyObject]()
//        if let speakTagsArray = getSpeakTags() as! [[String:String]]? {
//            for d in speakTagsArray {
//                let code = d["code"]
//                if let tagsForCode = getSpeakTagsCurrent(code!) as! [AnyObject]? {
//                    allSpeakTagsCurrentArray += tagsForCode
//                }
//            }
//        }
//        return allSpeakTagsCurrentArray as AnyObject?
//    }
//
//    /// Get all the current values for the speak tags as a comma-separated string
    public func getAllSpeakTagsCurrentAsString() -> String {
//        if let allSpeakTagsArray = getAllSpeakTagsCurrent() as! NSArray? {
//            var tags = ""
//            for tag in allSpeakTagsArray {
//                if (tags != "") { tags += "," }
//                tags += (tag as AnyObject).description
//            }
//            return tags
//        }
        return ""
    }

// MARK: submit tags

    /// Submit all current listen tags to the server
    public func submitListenTags() {
//        let tag_ids = getAllListenTagsCurrentAsString()
//        apiPatchStreamsIdWithTags(tag_ids)
    }

// MARK: edit tags

    /// Edit the Listen tags in a web view
    public func editListenTags() {
        editTags("tags_listen", title:LS("Listen Tags"))
    }

    /// Edit the Speak tags in a web view
    public func editSpeakTags() {
        editTags("tags_speak", title:LS("Speak Tags"))
    }

    /// Edit the Listen or Speak tags in a web view
    func editTags(_ type: String, title: String) {
        println("editing tags not yet supported but coming soon via WKWebView")
    }

}
