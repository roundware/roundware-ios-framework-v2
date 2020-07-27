
import Foundation
import CoreLocation
import GEOSwift

/**
 An individual piece of media contributed by a user or by project administrators.
 This currently only considers audio assets.
 */
public class Asset: Codable {
    public let id: Int
    public let tags: [Int]
    /// URL pointing to the associated media file, relative to the project server
    let file: String
    /// Duration of the asset in seconds
    let length: Double?
    let createdDate: Date
    let weight: Double
    let description: String
    let submitted: Bool?
    let shape: Geometry?
    private let longitude: Double?
    private let latitude: Double?
    private let startTime: Double?
    private let endTime: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case longitude
        case latitude
        case file
        case weight
        case description
        case submitted
        case shape
        case startTime = "start_time"
        case endTime = "end_time"
        case length = "audio_length_in_seconds"
        case tags = "tag_ids"
        case createdDate = "created"
    }
}

extension Asset {
    /// Range of time within the associated file that this asset represents.
    var activeRegion: ClosedRange<Double> {
        return (startTime ?? 0)...(endTime ?? length ?? 0)
    }
    
    public var location: CLLocation? {
        if let lat = self.latitude, let lng = self.longitude {
            return CLLocation(latitude: lat, longitude: lng)
        } else {
            return nil
        }
    }
}

public struct AssetPool: Codable {
    let assets: [Asset]
    let date: Date
}
