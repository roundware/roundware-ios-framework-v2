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
    let length: Float // in seconds
    let timestamp: Date
    let tags: [Int]
    let shape: [CGPoint]?
}

extension Asset {
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

            let shape = it["shape"] as? [String: AnyObject]
            let coords = shape?["coordinates"] as? [[[[Double]]]]
            // TODO: Handle actual multipolygons :)
            let coordsShape = coords?[0][0].map { p in
                CGPoint(x: p[0], y: p[1])
            }
            return Asset(
                id: it["id"] as! Int,
                location: location,
                file: it["file"] as! String,
                length: it["audio_length_in_seconds"] as! Float,
                timestamp: dateFormatter.date(from: it["created"] as! String)!,
                tags: it["tag_ids"] as! [Int],
                shape: coordsShape
            )
        }
    }
}

