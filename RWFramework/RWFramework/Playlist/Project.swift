
import Foundation
import CoreLocation

struct Project: Codable {
    let id: Int
    let name: String

    /// Static maximum distance an asset can be heard from.
    let recording_radius: Double

    /// Url of audio stream for users out of range.
    let out_of_range_url: String

    /// Distance from a speakers edge that a user is out of range.
    let out_of_range_distance: Double

    /// Should assets be filtered by their location?
    let geo_listen_enabled: Bool

    let repeat_mode: String
    let ordering: String

    private let latitude: Double
    private let longitude: Double
}


extension Project {
    /// Central coordinates of the project for estimating if users are in range.
    var location: CLLocation {
        return CLLocation(
            latitude: self.latitude,
            longitude: self.longitude
        )
    }

    /// Time in seconds to wait between checking for newly published assets
    var asset_refresh_interval: Double {
        let defaultInterval = 3.0 * 60.0
        let num = RWFrameworkConfig.getConfigValue("asset_refresh_interval", group: .project) as? NSNumber
        return num?.doubleValue ?? defaultInterval
    }
}
