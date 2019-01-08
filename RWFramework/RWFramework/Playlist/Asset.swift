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
import GEOSwift

struct Asset {
    let id: Int
    let location: CLLocation?
    let file: String
    let length: Double // in seconds
    let createdDate: Date
    let tags: [Int]
    let shape: Geometry?
    let weight: Double
    let description: String
}

extension Asset {
    static func from(data: Data) throws -> [Asset] {
        let items = try JSON(data: data)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale.init(identifier: "en_US_POSIX")

        return items.array!.map { item in
            let location: CLLocation?
            if let lat = item["latitude"].double, let lng = item["longitude"].double {
                location = CLLocation(latitude: lat, longitude: lng)
            } else {
                location = nil
            }

            var coordsShape: Geometry? = nil
            if let shape = item["shape"].dictionary, let coords = shape["coordinates"]![0][0].array {
                // TODO: Handle actual multi-polygons
                coordsShape = Polygon(shell: LinearRing(points: coords.map { p in
                    Coordinate(x: p[0].double!, y: p[1].double!)
                })!, holes: nil)
            }

            // Remove milliseconds from the creation date.
            let createdString = item["created"].string!.replacingOccurrences(
                of: "\\.\\d+", with: "", options: .regularExpression
            )

            return Asset(
                id: item["id"].int!,
                location: location,
                file: item["file"].string!,
                length: item["audio_length_in_seconds"].double ?? 0,
                createdDate: dateFormatter.date(from: createdString)!,
                tags: item["tag_ids"].array!.map { $0.int! },
                shape: coordsShape,
                weight: item["weight"].double ?? 0,
                description: item["description"].string ?? ""
            )
        }
    }
}

