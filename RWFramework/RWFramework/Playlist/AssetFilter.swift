//
//  AssetFilter.swift
//  RWFramework
//
//  Created by Taylor Snead on 7/31/18.
//  Copyright © 2018 Roundware. All rights reserved.
//

import Foundation
import Promises
import GEOSwift

/**
 The priority to place on an asset, or to discard it from use.
 Multiple assets with the same priority will be sorted by
 project-level ordering preferences.
 */
enum AssetPriority: Int {
    case discard = -1
    case highest = 0
    case normal = 100
    case lowest = 999
}

/// Filter applied to assets as candidates for a specific track
protocol AssetFilter {
    /// Determines whether the given asset should be played on a particular track.
    /// - returns: .discard to skip the asset, otherwise rank it
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority
}


/// Keep an asset if it's nearby or if it is timed to play now.
struct AnyAssetFilters: AssetFilter {
    var filters: [AssetFilter]
    init(_ filters: [AssetFilter]) {
        self.filters = filters
    }

    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        if filters.isEmpty {
            return .lowest
        }
        return filters.lazy
            .map { $0.keep(asset, playlist: playlist, track: track) }
            .first { $0 != .discard } ?? .discard
    }
}

struct AllAssetFilters: AssetFilter {
    var filters: [AssetFilter]
    init(_ filters: [AssetFilter]) {
        self.filters = filters
    }

    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        if filters.isEmpty {
            return .lowest
        }
        return filters.lazy
            .map { $0.keep(asset, playlist: playlist, track: track) }
            // short-circuit, only processing filters until one discards this asset.
            .prefix { $0 != .discard }
            // Use the highest priority given to this asset by one of the applied filters.
            .min { a, b in a.rawValue < b.rawValue } ?? .discard
    }
}

struct AnyTagsFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        // List of tags to listen for.
        guard let listenTags = RWFramework.sharedInstance.getListenIDsSet()
            else { return .lowest }

        let matches = asset.tags.contains { assetTag in
            listenTags.contains(assetTag) || track.tags.contains(assetTag)
        }
        // matching only by tag should be the least important filter.
        return matches ? .lowest : .discard
    }
}

struct AllTagsFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        // List of tags to listen for.
        guard let listenTags = RWFramework.sharedInstance.getListenIDsSet()
            else { return .lowest }

        let matches = asset.tags.allSatisfy { assetTag in
            listenTags.contains(assetTag) || track.tags.contains(assetTag)
        }

        return matches ? .lowest : .discard
    }
}

/**
 Plays an asset if the user is within range of it
 based on the current dynamic distance range.
 */
struct DistanceRangesFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        guard let params = playlist.currentParams,
              let loc = asset.location,
              let minDist = params.minDist,
              let maxDist = params.maxDist
            else { return .discard }

        let dist = params.location.distance(from: loc)
        if dist >= minDist && dist <= maxDist {
            return .normal
        } else {
            return .discard
        }
    }
}

/**
 Only plays an asset if the user is within the
 project-configured recording radius.
 */
struct DistanceFixedFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        guard let params = playlist.currentParams,
              let assetLoc = asset.location
            else { return .discard }

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
 Play an asset if the user is currently within its defined shape.
 */
struct AssetShapeFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        guard let params = playlist.currentParams,
              let shape = asset.shape
            else { return .discard }

        if shape.contains(params.location.toWaypoint()) {
            return .normal
        } else {
            return .discard
        }
    }
}

/**
 Play an asset if it's within the current angle range.
 */
struct AngleFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        guard let opts = playlist.currentParams,
              let loc = asset.location,
              let heading = opts.heading,
              let angularWidth = opts.angularWidth
            else { return .discard }


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
                // TODO: Only reject an asset until a certain time has passed?
                return .discard
            }
        } else {
            return .normal
        }
    }
}
