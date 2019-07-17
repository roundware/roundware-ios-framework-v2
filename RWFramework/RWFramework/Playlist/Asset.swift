
import Foundation
import CoreLocation
import SwiftyJSON
import GEOSwift

/**
 An individual piece of media contributed by a user or by project administrators.
 This currently only considers audio assets.
 */
public struct Asset {
    public let id: Int
    public let location: CLLocation?
    /// URL pointing to the associated media file, relative to the project server
    let file: String
    /// Duration of the asset in seconds
    let length: Double
    let createdDate: Date
    let tags: [Int]
    let shape: Geometry?
    let weight: Double
    let description: String
    /// Range of time within the associated file that this asset represents.
    let activeRegion: ClosedRange<Double>
}

extension Asset {
    static func from(data: Data) throws -> [Asset] {
        let items = try JSON(data: data)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale.init(identifier: "en_US_POSIX")

        return items.array?.compactMap { item in
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
            // We only need precision of seconds
            let createdString = item["created"].string!.replacingOccurrences(
                of: "\\.\\d+", with: "", options: .regularExpression
            )
            
            guard let id = item["id"].int,
                  let file = item["file"].string
                else { return nil }

            return Asset(
                id: id,
                location: location,
                file: file,
                length: item["audio_length_in_seconds"].double ?? 0,
                createdDate: dateFormatter.date(from: createdString)!,
                tags: item["tag_ids"].array!.map { $0.int! },
                shape: coordsShape,
                weight: item["weight"].double ?? 0,
                description: item["description"].string ?? "",
                activeRegion: (item["start_time"].double!)...(item["end_time"].double!)
            )
        } ?? []
    }
}

