//
//  Asset.swift
//  RWFramework
//
//  Created by Taylor Snead on 7/20/18.
//  Copyright © 2018 Roundware. All rights reserved.
//

import Foundation
import CoreLocation

public class Asset {
    let id: Int
    let location: CLLocation?
    let file: String
    let length: Int
    let timestamp: Date
    let tags: [Int]

    init(
        id: Int,
        location: CLLocation?,
        file: String,
        length: Int,
        timestamp: Date,
        tags: [Int]
    ) {
        self.id = id
        self.location = location
        self.file = file
        self.length = length
        self.timestamp = timestamp
        self.tags = tags
    }
    
    static func from(data: Data) throws -> [Asset] {
        let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale.init(identifier: "en_US_POSIX")
        
        let items = json as! [AnyObject]
        return items.map { obj in
            let it = obj as! [String: AnyObject]
            let location: CLLocation?
            if let lat = it["latitude"], let lng = it["longitude"] {
                location = CLLocation(
                    latitude: lat as! Double,
                    longitude: lng as! Double
                )
            } else {
                location = nil
            }
            return Asset(
                id: it["id"] as! Int,
                location: location,
                file: it["file"] as! String,
                length: it["audio_length_in_seconds"] as! Int,
                timestamp: dateFormatter.date(from: it["created"] as! String)!,
                tags: it["tag_ids"] as! [Int]
            )
        }
    }
}


public class TimedAsset {
    let id: Int
    let assetId: Int
    let start: Int
    let end: Int

    init(
        id: Int,
        assetId: Int,
        start: Int,
        end: Int
    ) {
        self.id = id
        self.assetId = assetId
        self.start = start
        self.end = end
    }

    static func from(json data: Data) throws -> [TimedAsset] {
        let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)

        let items = json as! [AnyObject]
        return items.map { obj in 
            let it = obj as! [String: AnyObject]
            return TimedAsset(
                id: it["id"] as! Int,
                assetId: it["asset_id"] as! Int,
                start: it["start"] as! Int,
                end: it["end"] as! Int
            )
        }
    }
}
