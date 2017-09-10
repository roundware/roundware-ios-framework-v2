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
    
    public func getAllListenTagsCurrent() -> [Tag]? {
        return getDefaultListenTags()
    }
    
    public func getAllListenTagsCurrentAsString() -> String {
        var s = ""
        if let tags = getAllListenTagsCurrent() {
            for tag in tags {
                if s.characters.count > 0 {
                    s += ","
                }
                s += "\(tag.id)"
            }
        }
        return s
    }

// MARK: Speak Tags

    public func getSpeakTags() -> [Tag]? {
        return getTags("speak")
    }

    public func getDefaultSpeakTags() -> [Tag]? {
        return getDefaultTags("speak")
    }

    public func getAllSpeakTagsCurrent() -> [Tag]? {
        return getDefaultSpeakTags()
    }
    
    public func getAllSpeakTagsCurrentAsString() -> String {
        var s = ""
        if let tags = getAllSpeakTagsCurrent() {
            for tag in tags {
                if s.characters.count > 0 {
                    s += ","
                }
                s += "\(tag.id)"
            }
        }
        return s
    }

// MARK: submit tags

    /// Submit all current listen tags to the server
    public func submitListenTags() {
        let tag_ids = getAllListenTagsCurrentAsString()
        apiPatchStreamsIdWithTags(tag_ids)
    }

}
