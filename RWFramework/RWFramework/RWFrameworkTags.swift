//
//  RWFrameworkTags.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/12/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//
/*
 NOTE: This file has a complex implementation and a simplified implementation. The simplified implementation uses the
 UIConfig struct in order to get from the server exactly what is needed for display in one result rather than having
 to piece together tags, tag categories and UI groups. It is recommended that you use the simplified mechanism if at
 all possible unless you specifically need more control over the raw data from the server.
*/

import Foundation

extension RWFramework {

    // Tags
    
    public struct Relationship: Codable {
        public var id: Int?
        public var tag_id: Int?
        public var parent_id: Int?
    }
    
    public struct Location: Codable {
        public var type: String?
        // TODO
    }
    
    public struct Tag: Codable {
        public var id: Int
        public var value: String?
        public var description: String?
        public var data: String?
        public var filter: String?
        //public var location: [Location]? // TODO
        public var project_id: Int
        public var tag_category_id: Int
        public var description_loc: String?
        public var msg_loc: String?
        public var relationships: [Relationship]?
    }

    // UIGroups
    
    public struct UIItem: Codable {
        public var id: Int
        public var index: Int
        public var `default`: Bool // default is a keyword so include in `` to have it seen as not so
        public var active: Bool
        public var ui_group_id: Int?
        public var tag_id: Int?
        public var parent_id: Int?
    }
    
    public struct UIGroup: Codable {
        public var id: Int
        public var name: String?
        public var ui_mode: String?
        public var select: String?
        public var active: Bool
        public var index: Int
        public var header_text_loc: String?
        public var tag_category_id: Int
        public var project_id: Int
        public var ui_items: [UIItem]?
    }

    // TagCategories
    
    public struct TagCategory: Codable {
        public var id: Int
        public var name: String?
        public var data: String?
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
    
// MARK: UIGroups
    
    public func getUIGroups(_ ui_mode: String) -> [UIGroup]? {
        // Get groups
        do {
            if let data = UserDefaults.standard.object(forKey: "ui_groups") {
                let decoder = JSONDecoder()
                let uigrouplist = try decoder.decode([UIGroup].self, from: data as! Data)
                
                // Create an empty array of groups that will be filled with all listen tags
                var groups = [UIGroup]()

                // Iterate groups for ui_mode of the passed in parameter
                for group in uigrouplist where group.ui_mode == ui_mode {
                    groups.append(group)
                }
                
                guard groups.count > 0 else { return nil }
                groups.sort {
                    return $0.index < $1.index
                }

                return groups
            }
        }
        catch {
            print(error)
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
    
    public func getTags(_ ui_mode: String) -> [Tag]? {
        // Get tags and groups
        do {
            if let data = UserDefaults.standard.object(forKey: "tags") {
                let decoder = JSONDecoder()
                let taglist = try decoder.decode([Tag].self, from: data as! Data)
                let uigrouplist = getUIGroups(ui_mode)

                // Create an empty array of tags that will be filled with all ui_mode tags
                var tags = [Tag]()

                // Iterate groups for ui_mode of the passed in parameter
                for group in uigrouplist! where group.ui_mode == ui_mode {

                    // Verify that there are ui_items defined for any found group
                    guard let ui_items = group.ui_items else { continue }

                    // Iterate the ui_items
                    for ui_item in ui_items {

                        // Verify that there is a tag_id set for any found item
                        if let tag_id = ui_item.tag_id {

                            // Find the tag with that tag_id
                            if let tag = taglist.filter({$0.id == tag_id}).first {
                                tags.append(tag)
                            }
                        }
                    }
                }
                guard tags.count > 0 else { return nil }
                return tags
            }
        }
        catch {
            print(error)
        }
        return nil
    }
    
    public func getDefaultTags(_ ui_mode: String) -> [Tag]? {
        // Get tags and groups
        if let uigrouplist = getUIGroups(ui_mode), let taglist = getTags(ui_mode) {
            
            // Create an empty array of tags that will be filled with all ui_mode tags
            var tags = [Tag]()
            
            // Iterate groups for ui_mode of the passed in parameter
            for group in uigrouplist where group.ui_mode == ui_mode {
                
                // Verify that there are ui_items defined for any found group
                guard let ui_items = group.ui_items else { continue }
                
                // Iterate the ui_items
                for ui_item in ui_items {
                    
                    // Verify that there is a tag_id set for any found item and that it is set to be a default
                    if let tag_id = ui_item.tag_id, ui_item.default == true {
                        
                        // Find the tag with that tag_id
                        if let tag = taglist.filter({$0.id == tag_id}).first {
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

// MARK: Simplified
    
    public struct UIConfigItem: Codable {
        public var id: Int
        public var tag_id: Int
        public var parent_id: Int?
        public var default_state: Bool
        public var tag_display_text: String?
    }
    
    public struct UIConfigGroup: Codable {
        public var select: String?
        public var group_short_name: String?
        public var header_display_text: String?
        public var display_items: [UIConfigItem]
    }
    
    public struct UIConfig : Codable {
        public var speak: [UIConfigGroup]
        public var listen: [UIConfigGroup]
    }
    
    public func getUIConfig() -> UIConfig? {
        do {
            if let data = UserDefaults.standard.object(forKey: "uiconfig") {
                let decoder = JSONDecoder()
                let uiconfig = try decoder.decode(UIConfig.self, from: data as! Data)
                return uiconfig;
            }
        }
        catch {
            print(error)
        }
        return nil
    }
    
// MARK: --

    public func submitListenIDsSetAsTags(streamPatchOptions: [String: Any] = [:]) {
        // Tell the playlist that it can check for newly available assets
        self.updateStreamParams()
    }
    
    public func getListenTagIDFromID(_ id: Int) -> Int {
        if let uiconfig = getUIConfig() {
            for listen in uiconfig.listen {
                for item in listen.display_items {
                    if item.id == id {
                        return item.tag_id
                    }
                }
            }
        }
        return 0
    }
    
    public func getSubmittableListenIDsSetAsTags() -> String {
        var tag_ids: String = ""
        if let selectedIDs = getListenIDsSet() {
            for id in selectedIDs {
                let tag_id = getListenTagIDFromID(id)
                if tag_ids.count > 0 {
                    tag_ids += ","
                }
                tag_ids += "\(tag_id)"
            }
        }
        return tag_ids
    }
    
    public func getSubmittableListenTagIDsSet() -> Set<Int>? {
        var tag_ids: Set<Int> = []
        if let selectedIDs = getListenIDsSet() {
            for id in selectedIDs {
                let tag_id = getListenTagIDFromID(id)
                tag_ids.insert(tag_id)
            }
        }
        return tag_ids
    }

    public func getListenIDsSet() -> Set<Int>? {
        if let array = UserDefaults.standard.object(forKey: "listenIDsSet") as? Array<Int> {
            return Set(array)
        } else {
            if let uiconfig = getUIConfig() {
                var set = Set<Int>()
                for listen in uiconfig.listen {
                    for item in listen.display_items {
                        if item.default_state == true {
                            set.insert(item.id)
                        }
                    }
                }
                return set
            }
        }
        return nil
    }
    
    public func setListenIDsSet(_ ids: Set<Int>, streamPatchOptions: [String: Any] = [:]) {
        UserDefaults.standard.set(Array(ids), forKey: "listenIDsSet")
        UserDefaults.standard.synchronize()
        submitListenIDsSetAsTags(streamPatchOptions: streamPatchOptions)
    }
    
    public func getFilterListenIDsSet() -> Set<Int>? {
        if let array = UserDefaults.standard.object(forKey: "filterListenIDsSet") as? Array<Int> {
            return Set(array)
        } else {
            if let uiconfig = getUIConfig() {
                var set = Set<Int>()
                for listen in uiconfig.listen {
                    for item in listen.display_items {
                        if item.default_state == true {
                            set.insert(item.id)
                        }
                    }
                }
                return set
            }
        }
        return nil
    }
    
    public func setFilterListenIDsSet(_ ids: Set<Int>) {
        UserDefaults.standard.set(Array(ids), forKey: "filterListenIDsSet")
        UserDefaults.standard.synchronize()
    }

// MARK: --
    
    public func getSpeakTagIDFromID(_ id: Int) -> Int {
        if let uiconfig = getUIConfig() {
            for speak in uiconfig.speak {
                for item in speak.display_items {
                    if item.id == id {
                        return item.tag_id
                    }
                }
            }
        }
        return 0
    }

    public func getSubmittableSpeakIDsSetAsTags() -> String {
        var tag_ids: String = ""
        if let selectedIDs = getSpeakIDsSet() {
            for id in selectedIDs {
                let tag_id = getSpeakTagIDFromID(id)
                if tag_ids.count > 0 {
                    tag_ids += ","
                }
                tag_ids += "\(tag_id)"
            }
        }
        return tag_ids
    }

    public func getSpeakIDsSet() -> Set<Int>? {
        if let array = UserDefaults.standard.object(forKey: "speakIDsSet") as? Array<Int> {
            return Set(array)
        } else {
            if let uiconfig = getUIConfig() {
                var set = Set<Int>()
                for speak in uiconfig.speak {
                    for item in speak.display_items {
                        if item.default_state == true {
                            set.insert(item.id)
                        }
                    }
                }
                return set
            }
        }
        return nil
    }
    
    public func setSpeakIDsSet(_ ids: Set<Int>) {
        UserDefaults.standard.set(Array(ids), forKey: "speakIDsSet")
        UserDefaults.standard.synchronize()
    }
    
    public func getSpeakIDsDefaultSet() -> Set<Int>? {
        if let uiconfig = getUIConfig() {
            var set = Set<Int>()
            for speak in uiconfig.speak {
                for item in speak.display_items {
                    if item.default_state == true {
                        set.insert(item.id)
                    }
                }
            }
            return set
        }
        return nil
    }
    
// MARK: --
    
    public func getValidDisplayItems(_ group: [UIConfigGroup], index: Int, tags: Set<Int>) -> [UIConfigItem] {
        var display_items = [UIConfigItem]()
        for item in group[index].display_items {
            if item.parent_id == nil {
                display_items.append(item)
            } else {
                var previousIndex = index - 1
                if previousIndex < 0 { previousIndex = 0 }
                if let IDOfParentID = getIDOfDisplayItemParent(item, group: [group[previousIndex]]) {
                    if tags.contains(IDOfParentID) {
                        display_items.append(item)
                    }
                }
            }
        }
        return display_items
    }

    public func getIDOfDisplayItemParent(_ display_item: UIConfigItem, group: [UIConfigGroup]) -> Int? {
        for g in group {
            for item in g.display_items {
                if (item.id == display_item.parent_id) {
                    return item.id
                }
            }
        }
        return nil
    }
}
