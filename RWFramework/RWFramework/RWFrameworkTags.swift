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
    
    public struct UIGroupList : Codable {
        let ui_groups: [UIGroup]
    }

    // TagCategories
    
    public struct TagCategory: Codable {
        var id: Int
        var name: String?
        var data: String?
    }
    
// MARK: TagCategories

    public func getTagCategories() -> [TagCategory]? {
        do {
            if let data = UserDefaults.standard.object(forKey: "tagcategories") {
                let decoder = JSONDecoder()
                let tagcategories = try decoder.decode([TagCategory].self, from: data as! Data)
                return tagcategories;
            }
        }
        catch {
            print(error)
        }
        return nil
    }
    
    public func getFilteredTagCategories(_ ids: Array<Int>) -> [TagCategory]? {
        var result = [TagCategory]()
        let tagcategories = getTagCategories()
        for id in ids {
            let tagcategory = tagcategories?.filter { id == $0.id }
            result.append((tagcategory?.first)!)
        }
        return result
    }
    
    public func getFilteredTagCategoryNamesAndIDs(_ ids: Array<Int>) -> [[Int:String]]? {
        var result = [[Int:String]]()
        if let tagcategories = getFilteredTagCategories(ids) {
            for tagcategory in tagcategories {
                result.append([tagcategory.id: tagcategory.name!])
            }
        }
        return result
    }
    
// MARK: UIGroups

    public func getUIGroupList() -> UIGroupList? {
        do {
            if let data = UserDefaults.standard.object(forKey: "ui_groups") {
                let decoder = JSONDecoder()
                let uigrouplist = try decoder.decode(UIGroupList.self, from: data as! Data)
                return uigrouplist
            }
        }
        catch {
            print(error)
        }
        return nil
    }
    
    public func getUIGroups(_ ui_mode: String) -> [UIGroup]? {
        // Get groups
        if let uigrouplist = getUIGroupList() {
            
            // Create an empty array of groups that will be filled with all listen tags
            var groups = [UIGroup]()

            // Iterate groups for ui_mode of the passed in parameter
            for group in uigrouplist.ui_groups where group.ui_mode == ui_mode {
                groups.append(group)
            }
            
            guard groups.count > 0 else { return nil }
            groups.sort {
                return $0.index < $1.index
            }

            return groups
        }
        return nil
    }

    public func getUIGroupIDs(_ ui_mode: String) -> [Int]? {
        var ids = [Int]()
        if let uigroups = getUIGroups(ui_mode) {
            for uigroup in uigroups {
                ids.append(uigroup.tag_category_id)
            }
        }
        return ids
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
        if let uigrouplist = getUIGroupList(), let taglist = getTagList() {
            
            // Create an empty array of tags that will be filled with all ui_mode tags
            var tags = [Tag]()
            
            // Iterate groups for ui_mode of the passed in parameter
            for group in uigrouplist.ui_groups where group.ui_mode == ui_mode {
                
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
        if let uigrouplist = getUIGroupList(), let taglist = getTagList() {
            
            // Create an empty array of tags that will be filled with all ui_mode tags
            var tags = [Tag]()
            
            // Iterate groups for ui_mode of the passed in parameter
            for group in uigrouplist.ui_groups where group.ui_mode == ui_mode {
                
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
