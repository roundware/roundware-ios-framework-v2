//
//  AssetFilter.swift
//  RWFramework
//
//  Created by Taylor Snead on 7/31/18.
//  Copyright © 2018 Roundware. All rights reserved.
//

import Foundation
import Promises

/// Filter applied to all assets at the playlist building stage
protocol AssetFilter {
    /// @return true to keep the given asset
    func keep(_ asset: Asset, playlist: Playlist) -> Bool
}

/// Filter applied to assets as candidates for a specific track
protocol TrackFilter {
    /// @return true to keep the given asset
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> Bool
}


/// Keep an asset if it's nearby or if it is timed to play now.
/// TODO: Really, we need to prioritize timed assets above nearby ones, so returning some kind of priority here might be best. <0 means don't keep, 0 = top priority

struct AnyFilters: AssetFilter {
    let filters: [AssetFilter]
    init(_ filters: [AssetFilter]) {
        self.filters = filters
    }
    func keep(_ asset: Asset, playlist: Playlist) -> Bool {
        return filters.contains { it in
            it.keep(asset, playlist: playlist)
        }
    }
}

struct AllFilters: AssetFilter {
    let filters: [AssetFilter]
    init(_ filters: [AssetFilter]) {
        self.filters = filters
    }
    func keep(_ asset: Asset, playlist: Playlist) -> Bool {
        return !filters.contains { it in
            !it.keep(asset, playlist: playlist)
        }
    }
}


class TimedAssetFilter: AssetFilter {
    private var timedAssets: [TimedAsset]? = nil

    func keep(_ asset: Asset, playlist: Playlist) -> Bool {
        if timedAssets == nil {
            // load the timed assets
            do {
                timedAssets = try await(RWFramework.sharedInstance.apiGetTimedAssets([:]))
            } catch {
                return true
            }
        }
        // keep assets that are slated to start now or before
        //      AND hasn't been played before
        let now = Int(Date().timeIntervalSince(playlist.startTime))
        return timedAssets!.reduce(true) { res, it in
            return res && it.start <= now && playlist.userAssetData[it.assetId] == nil
        }
    }
}

class LocationFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist) -> Bool {
        let opts = playlist.currentParams!
        if let loc = asset.location {
            let dist = opts.location.distance(from: loc)
            return dist >= Double(opts.minDist) && dist <= Double(opts.maxDist)
        }
        return true
    }
}


class AngleFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist) -> Bool {
        let opts = playlist.currentParams!
        if let loc = asset.location {
            if (opts.angularWidth <= 359) {
                let angle = Float(opts.location.bearingToLocationDegrees(loc))
                let lower = opts.heading - opts.angularWidth
                let upper = opts.heading + opts.angularWidth
                
                if (lower < 0) {
                    // wedge spans from just above zero to below it.
                    // Check between lower...360 and 0...upper
                    return ((360 + lower)...360).contains(angle)
                        || (0...upper).contains(angle)
                } else if (upper >= 360) {
                    // wedge spans from just below 360 to above it.
                    // Check between lower...360 and 0...upper
                    return (lower...360).contains(angle)
                        || (0...(upper - 360)).contains(angle)
                } else {
                    return angle >= lower
                        && angle <= upper
                }
            }
        }
        return true
    }
}


class LengthFilter: TrackFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> Bool {
        return track.duration.contains(Float(asset.length))
    }
}
