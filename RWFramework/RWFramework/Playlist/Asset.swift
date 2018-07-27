//
//  Asset.swift
//  RWFramework
//
//  Created by Taylor Snead on 7/20/18.
//  Copyright © 2018 Roundware. All rights reserved.
//

import Foundation
import CoreLocation

struct Asset {
    let id: Int
    let location: CLLocation?
    let file: String
    let length: Int
    let timestamp: Date
    
    static func fromJson(_ data: Data) throws -> [Asset] {
        let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale.init(identifier: "en_US_POSIX")
        
        let items = json as! [AnyObject]
        return items.map { obj in
            let it = obj as! [String: AnyObject]
            return Asset(
                id: it["id"] as! Int,
                location: CLLocation(
                    latitude: it["latitude"] as! Double,
                    longitude: it["longitude"] as! Double
                ),
                file: it["file"] as! String,
                length: it["audio_length_in_seconds"] as! Int,
                timestamp: dateFormatter.date(from: it["created"] as! String)!
            )
        }
    }
}
