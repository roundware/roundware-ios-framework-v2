
import Foundation
import Promises
import GEOSwift

/**
 The priority to place on an asset, or to discard it from use.
 Multiple assets with the same priority will be sorted by
 project-level ordering preferences.
 */
public enum AssetPriority: Int, CaseIterable {
    /// Discard the asset always
    case discard = -1

    /// Accept the asset only if not overridden by any other priority
    case neutral = 0

    case lowest = 1
    case normal = 100
    case highest = 999
}

/// Filter applied to assets as candidates for a specific track
public protocol AssetFilter {
    /// Determines whether the given asset should be played on a particular track.
    /// - returns: .discard to skip the asset, otherwise rank it
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority
    func onUpdateAssets(playlist: Playlist) -> Promise<Void>
}

extension AssetFilter {
    func onUpdateAssets(playlist: Playlist) -> Promise<Void> {
        return Promise(())
    }
}

/**
 Filter composed of multiple inner filters
 that accepts assets that pass one of these inner filters.
 */
struct AnyAssetFilters: AssetFilter {
    var filters: [AssetFilter]
    init(_ filters: [AssetFilter]) {
        self.filters = filters
    }

    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        if filters.isEmpty {
            return .lowest
        }
        let ranks = filters.lazy
            .map { $0.keep(asset, playlist: playlist, track: track) }
        return ranks.first { $0 != .discard && $0 != .neutral }
            ?? .discard
    }

    func onUpdateAssets(playlist: Playlist) -> Promise<Void> {
        return all(self.filters.map { $0.onUpdateAssets(playlist: playlist) })
            .then { _ -> Void in }
    }
}

/**
 Filter composed of multiple inner filters
 that accepts assets that pass every inner filter.
 */
struct AllAssetFilters: AssetFilter {
    var filters: [AssetFilter]
    init(_ filters: [AssetFilter]) {
        self.filters = filters
    }

    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        if filters.isEmpty {
            return .lowest
        }
        let ranks = filters.lazy
            .map { $0.keep(asset, playlist: playlist, track: track) }
        
        // If any filter discards the asset, then this discards
        if ranks.contains(where: { $0 == .discard }) {
            return .discard
        } else {
            // Otherwise, simply use the first returned priority
            // Ideally the first that isn't .neutral
            return ranks.first { $0 != .neutral } ?? ranks.first!
        }
    }

    func onUpdateAssets(playlist: Playlist) -> Promise<Void> {
        return all(self.filters.map { $0.onUpdateAssets(playlist: playlist) })
            .then { _ -> Void in }
    }
}

struct AnyTagsFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        // List of tag_ids to listen for.
        guard let listenTagIDs = RWFramework.sharedInstance.getSubmittableListenTagIDsSet()
            else { return .lowest }

        let matches = asset.tags.contains { assetTag in
            listenTagIDs.contains(assetTag)
        }
        // matching only by tag should be the least important filter.
        return matches ? .lowest : .discard
    }
}

struct AllTagsFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        // List of tag_ids to listen for.
        guard let listenTagIDs = RWFramework.sharedInstance.getSubmittableListenTagIDsSet()
            else { return .lowest }

        let matches = asset.tags.allSatisfy { assetTag in
            listenTagIDs.contains(assetTag)
        }

        return matches ? .lowest : .discard
    }
}

struct TrackTagsFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        guard let trackTags = track.tags,
              trackTags.count != 0
            else { return .lowest }
        
        let matches = asset.tags.contains { assetTag in
            trackTags.contains(assetTag)
        }
        
        return matches ? .lowest : .discard
    }
}

/**
 Accepts an asset if the user is within range of it
 based on the current dynamic distance range.
 */
struct DistanceRangesFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        guard playlist.project.geo_listen_enabled,
              let params = playlist.currentParams,
              let loc = asset.location,
              let minDist = params.minDist,
              let maxDist = params.maxDist
            else { return .neutral }

        let dist = params.location.distance(from: loc)
        if dist >= minDist && dist <= maxDist {
            return .normal
        } else {
            return .discard
        }
    }
}

/**
 Only accepts an asset if the user is within the
 project-configured recording radius.
 */
struct DistanceFixedFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        guard playlist.project.geo_listen_enabled,
              let params = playlist.currentParams,
              let assetLoc = asset.location
            else { return .neutral }

        let listenerLoc = params.location
        let maxListenDist = playlist.project.recording_radius
        if listenerLoc.distance(from: assetLoc) <= maxListenDist {
            return .normal
        } else {
            return .discard
        }
    }
}

/**
 Accept an asset if the user is currently within its defined shape.
 */
struct AssetShapeFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        guard playlist.project.geo_listen_enabled,
              let params = playlist.currentParams,
              let shape = asset.shape
            else { return .neutral }

        if try! params.location.toWaypoint().isWithin(shape) {
            return .normal
        } else {
            return .discard
        }
    }
}

/**
 Accept an asset if it's within the current angle range.
 */
struct AngleFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        guard playlist.project.geo_listen_enabled,
              let opts = playlist.currentParams,
              let loc = asset.location,
              let heading = opts.heading,
              let angularWidth = opts.angularWidth
            else { return .neutral }

        // We can keep any asset if our angular width covers all space.
        if angularWidth > 359.0 {
            return .normal
        }

        let angle = opts.location.bearingToLocationDegrees(loc)
        let lower = heading - angularWidth
        let upper = heading + angularWidth

        if lower < 0 {
            // wedge spans from just above zero to below it.
            // Check between lower...360 and 0...upper
            if ((360 + lower)...360).contains(angle)
                || (0...upper).contains(angle) {
                return .normal
            }
        } else if upper >= 360 {
            // wedge spans from just below 360 to above it.
            // Check between lower...360 and 0...upper
            if (lower...360).contains(angle)
                || (0...(upper - 360)).contains(angle) {
                return .normal
            }
        } else if angle >= lower && angle <= upper {
            return .normal
        }

        return .discard
    }
}


/**
 Prevents assets from playing repeatedly if the track
 doesn't have `repeatRecordings` enabled.
 */
struct RepeatFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        if playlist.lastListenDate(for: asset) != nil {
            if track.repeatRecordings {
                // this track allows repeating an asset,
                // so go ahead and keep it, but after other stuff.
                return .lowest
            } else {
                // if this asset has been listened to at all, skip it.
                return .discard
            }
        } else {
            return .normal
        }
    }
}

/**
 Prevents assets from repeating until a certain time threshold has passed.
 */
struct TimedRepeatFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        if let listenDate = playlist.lastListenDate(for: asset) {
            let timeout = track.bannedDuration
            if Date().timeIntervalSince(listenDate) > timeout {
                return .lowest
            } else {
                return .discard
            }
        } else {
            return .normal
        }
    }
}

/**
 Skips assets that the user has blocked,
 or assets published by someone that the user has blocked.
 */
class BlockedAssetsFilter: AssetFilter {
    private var blockedAssets: BlockedAssets? = nil
    
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        guard let blocked = self.blockedAssets?.ids
            else { return .neutral }
        
        if blocked.contains(asset.id) {
            return .discard
        } else {
            return .normal
        }
    }

    func onUpdateAssets(playlist: Playlist) -> Promise<Void> {
        return RWFramework.sharedInstance.apiGetBlockedAssets().then { d -> Void in
            self.blockedAssets = try RWFramework.decoder.decode(BlockedAssets.self, from: d)
        }
    }

    private struct BlockedAssets: Codable {
        let ids: [Int]
        enum CodingKeys: String, CodingKey {
            case ids = "blocked_asset_ids"
        }
    }
}

/**
 Accept assets that pass an inner filter
 if the tag with a given filter key is enabled.
 */
struct DynamicTagFilter: AssetFilter {
    /// Mapping of dynamic filter name to tag id
    private static let tags = try! RWFramework.decoder.decode(
        [DynamicTag].self,
        from: UserDefaults.standard.data(forKey: "tags")!
    ).reduce(into: [String: [Int]]()) { acc, t in
        let key = t.filter
        acc[key] = (acc[key] ?? []) + [t.id]
    }
    
    private let key: String
    private let filter: AssetFilter

    init(_ key: String, _ filter: AssetFilter) {
        self.key = key
        self.filter = filter
    }

    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        // see if there are any tags using this filter
        if let tagIds = DynamicTagFilter.tags[self.key],
            // grab the list of enabled tags
            let enabledTagIds = RWFramework.sharedInstance.getSubmittableListenTagIDsSet(),
            // if any filter tags are enabled, apply the filter
            tagIds.contains(where: { enabledTagIds.contains($0) }) {
            return self.filter.keep(asset, playlist: playlist, track: track)
        } else {
            return .neutral
        }
    }

    private struct DynamicTag: Codable {
        let id: Int
        let filter: String
    }
}

/**
 Only pass assets created within the most recent given time range.
 `MostRecentFilter(days: 7)` accepts assets published within the last week.
 */
struct MostRecentFilter: AssetFilter {
    /// Oldest age of assets to accept.
    private let maxAge: TimeInterval
    
    init(days: Int) {
        self.maxAge = TimeInterval(days * 24 * 60 * 60)
    }
    
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        let timeSinceCreated = Date().timeIntervalSince(asset.createdDate)
        if timeSinceCreated > maxAge {
            return .discard
        } else {
            return .normal
        }
    }
}
