//
//  Asset.swift
//  RWFramework
//
//  Created by Taylor Snead on 7/20/18.
//  Copyright © 2018 Roundware. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftyJSON

struct Asset {
    let id: Int
    let location: CLLocation?
    let file: String
    let length: Double // in seconds
    let createdDate: Date
    let tags: [Int]
    let shape: [CGPoint]?
    let weight: Double
    let description: String
}

extension Asset {
    static func from(data: Data) throws -> [Asset] {
        let items = try JSON(data: data)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale.init(identifier: "en_US_POSIX")

        return items.arrayValue.map { item in
            let location: CLLocation?
            if let lat = item["latitude"].double, let lng = item["longitude"].double {
                location = CLLocation(latitude: lat, longitude: lng)
            } else {
                location = nil
            }

            let coords = item["shape"]["coordinates"]
            // TODO: Handle actual multipolygons :)
            let coordsShape = coords[0][0].array?.map { p in
                CGPoint(x: p[0].doubleValue, y: p[1].doubleValue)
            }
            return Asset(
                id: item["id"].int!,
                location: location,
                file: item["file"].string!,
                length: item["audio_length_in_seconds"].double!,
                createdDate: dateFormatter.date(from: item["created"].string!)!,
                tags: item["tag_ids"].array!.map { $0.int! },
                shape: coordsShape,
                weight: item["weight"].double!,
                description: item["description"].string ?? ""
            )
        }
    }
}

