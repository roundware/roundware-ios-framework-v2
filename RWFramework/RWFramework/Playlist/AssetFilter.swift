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
    /// Determines whether to keep an asset in the `Playlist` for any track.
    /// @return -1 to discard the asset, otherwise rank it where 0 is most important
    func keep(_ asset: Asset, playlist: Playlist) -> Int
}

/// Filter applied to assets as candidates for a specific track
protocol TrackFilter {
    /// Determines whether the given asset should be played on a particular track.
    /// @return -1 to discard the asset, otherwise rank it where 0 is most important
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> Int
}


/// Keep an asset if it's nearby or if it is timed to play now.
/// Really, we need to prioritize timed assets above nearby ones, so returning some kind of priority here might be best. <0 means don't keep, 0 = top priority, >0 = rank
/// Maybe an enum is our best bet here.

class AnyAssetFilters: AssetFilter {
    var filters: [AssetFilter]
    init(_ filters: [AssetFilter]) {
        self.filters = filters
    }
    func keep(_ asset: Asset, playlist: Playlist) -> Int {
        return filters.lazy
            .map { it in it.keep(asset, playlist: playlist) }
            .first { it in it >= 0 } ?? 1
    }
}

class AllAssetFilters: AssetFilter {
    var filters: [AssetFilter]
    init(_ filters: [AssetFilter]) {
        self.filters = filters
    }
    func keep(_ asset: Asset, playlist: Playlist) -> Int {
        return filters.lazy
            .map { it in it.keep(asset, playlist: playlist) }
            .min { a, b in a < b } ?? 1
    }
}

class TagsFilter: AssetFilter {
    /// List of tags to listen for.
    lazy var listenTags: [Int] =
        RWFramework.sharedInstance.getListenIDsSet()!.map { x in x }
    
    func keep(_ asset: Asset, playlist: Playlist) -> Int {
        print("listening for tags: " + listenTags.description)
        let matches = asset.tags.contains { assetTag in
            self.listenTags.contains { $0 == assetTag }
        }
        if (matches) {
            // matching only by tag should be the least important filter.
            return 999
        } else {
            return -1
        }
    }
}

class TimedAssetFilter: AssetFilter {
    private var timedAssets: [TimedAsset]? = nil

    func keep(_ asset: Asset, playlist: Playlist) -> Int {
        if timedAssets == nil {
            // load the timed assets
            do {
                timedAssets = try await(RWFramework.sharedInstance.apiGetTimedAssets([:]))
            } catch {
                return -1
            }
        }
        // keep assets that are slated to start now or in the past few minutes
        //      AND haven't been played before
        // Units: seconds
        let now = Int(Date().timeIntervalSince(playlist.startTime))
        let earliest = now - 60*2 // few minutes ago
        if (timedAssets!.contains { it in
            return it.assetId == asset.id &&
                it.start <= now &&
                it.start > earliest &&
                // it hasn't been played before.
                playlist.userAssetData[it.assetId] == nil
        }) {
            return 0
        }
        
        return -1
    }
}

class LocationFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist) -> Int {
        let opts = playlist.currentParams!
        if let loc = asset.location {
            let dist = opts.location.distance(from: loc)
            if (dist >= Double(opts.minDist) && dist <= Double(opts.maxDist)) {
                return 1
            }
        }
        return -1
    }
}


class AngleFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist) -> Int {
        let opts = playlist.currentParams!
        if let loc = asset.location {
            if (opts.angularWidth <= 359) {
                let angle = Float(opts.location.bearingToLocationDegrees(loc))
                let lower = opts.heading - opts.angularWidth
                let upper = opts.heading + opts.angularWidth
                
                if (lower < 0) {
                    // wedge spans from just above zero to below it.
                    // Check between lower...360 and 0...upper
                    if(((360 + lower)...360).contains(angle)
                        || (0...upper).contains(angle)) {
                        return 1
                    }
                } else if (upper >= 360) {
                    // wedge spans from just below 360 to above it.
                    // Check between lower...360 and 0...upper
                    if((lower...360).contains(angle)
                        || (0...(upper - 360)).contains(angle)) {
                        return 1
                    }
                } else {
                    if (angle >= lower
                        && angle <= upper) {
                        return 1
                    }
                }
            }
        }
        return -1
    }
}


class DurationFilter: TrackFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> Int {
        if track.duration.contains(Float(asset.length)) {
            return 1
        } else {
            return -1
        }
    }
}

/**
 *  Prevents assets from playing repeatedly if the track
 *  doesn't have `repeatRecordings` enabled.
 */
class RepeatFilter: TrackFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> Int {
        print("track repeats stuff? " + track.repeatRecordings.description)
        if track.repeatRecordings {
            return 999
        } else {
            if let lastListen = playlist.lastListenDate(for: asset) {
                // if this asset has been listened to at all, skip it.
                // TODO: Only reject an asset until a certain time has passed?
                return -1
            } else {
                return 1
            }
        }
    }
}
