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
    
    public struct Relationship: Codable {
        var id: Int?
        var tag_id: Int?
        var parent_id: Int?
    }
    
    public struct Location: Codable {
        var type: String?
        // TODO
    }
    
    public struct Tag: Codable {
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
    
    public struct TagList : Codable {
        let tags: [Tag]
    }

    // UIGroups
    
    public struct UIItem: Codable {
        var id: Int
        var index: Int
        var `default`: Bool // default is a keyword so include in `` to have it seen as not so
        var active: Bool
        var ui_group_id: Int?
        var tag_id: Int?
        var parent_id: Int?
    }
    
    public struct UIGroup: Codable {
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
    
    public struct UIGroupsList : Codable {
        let ui_groups: [UIGroup]
    }

// MARK: UIGroups

    public func getUIGroupsList() -> UIGroupsList? {
        do {
            if let data = UserDefaults.standard.object(forKey: "ui_groups") {
                let decoder = JSONDecoder()
                let uigroupslist = try decoder.decode(UIGroupsList.self, from: data as! Data)
                return uigroupslist
            }
        }
        catch {
            print(error)
        }
        return nil
    }

// MARK: Tags

    public func getTagList() -> TagList? {
        do {
            if let data = UserDefaults.standard.object(forKey: "tags") {
                let decoder = JSONDecoder()
                let taglist = try decoder.decode(TagList.self, from: data as! Data)
                return taglist
            }
        }
        catch {
            print(error)
        }
        return nil
    }

    public func getTags(_ ui_mode: String) -> [Tag]? {
        // Get tags and groups
        if let uigroupslist = getUIGroupsList(), let taglist = getTagList() {
            
            // Create an empty array of tags that will be filled with all listen tags
            var tags = [Tag]()
            
            // Iterate groups for ui_mode of the passed in parameter
            for group in uigroupslist.ui_groups where group.ui_mode == ui_mode {
                
                // Verify that there are ui_items defined for any found group
                guard let ui_items = group.ui_items else { continue }
                
                // Iterate the ui_items
                for ui_item in ui_items {
                    
                    // Verify that there is a tag_id set for any found item
                    if let tag_id = ui_item.tag_id {
                        
                        // Find the tag with that tag_id
                        if let tag = taglist.tags.filter({$0.id == tag_id}).first {
                            tags.append(tag)
                        }
                    }
                }
            }
            guard tags.count > 0 else { return nil }
            return tags
        }
        return nil
    }
    
    public func getDefaultTags(_ ui_mode: String) -> [Tag]? {
        // Get tags and groups
        if let uigroupslist = getUIGroupsList(), let taglist = getTagList() {
            
            // Create an empty array of tags that will be filled with all listen tags
            var tags = [Tag]()
            
            // Iterate groups for ui_mode of the passed in parameter
            for group in uigroupslist.ui_groups where group.ui_mode == ui_mode {
                
                // Verify that there are ui_items defined for any found group
                guard let ui_items = group.ui_items else { continue }
                
                // Iterate the ui_items
                for ui_item in ui_items {
                    
                    // Verify that there is a tag_id set for any found item and that it is set to be a default
                    if let tag_id = ui_item.tag_id, ui_item.default == true {
                        
                        // Find the tag with that tag_id
                        if let tag = taglist.tags.filter({$0.id == tag_id}).first {
                            tags.append(tag)
                        }
                    }
                }
            }
            guard tags.count > 0 else { return nil }
            return tags
        }
        return nil
    }

// MARK: Listen Tags

    public func getListenTags() -> [Tag]? {
        return getTags("listen")
    }
    
    public func getDefaultListenTags() -> [Tag]? {
        return getDefaultTags("listen")
    }
    

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

    public func getSpeakTags() -> [Tag]? {
        return getTags("speak")
    }

    public func getDefaultSpeakTags() -> [Tag]? {
        return getDefaultTags("speak")
    }

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
