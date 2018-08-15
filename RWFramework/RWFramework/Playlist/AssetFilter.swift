//
//  AssetFilter.swift
//  RWFramework
//
//  Created by Taylor Snead on 7/31/18.
//  Copyright © 2018 Roundware. All rights reserved.
//

import Foundation

/// Filter applied to all assets at the playlist building stage
protocol AssetFilter {
    /// @return true to keep the given asset
    func keep(_ asset: Asset, playlist: Playlist) -> Bool
}

/// Filter applied to assets as candidates for a specific track
protocol TrackFilter {
    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> Bool
}


/// Keep an asset if it's nearby or if it is timed to play now.
class FilterByTimeOrLocation: AssetFilter {
    private let timeFilter = TimedAssetFilter()
    private let locFilter = LocationFilter()
    func keep(_ asset: Asset, playlist: Playlist) -> Bool {
        return timeFilter.keep(asset, playlist)
            || locFilter.keep(asset, playlist)
    }
}


class TimedAssetFilter: AssetFilter {
    func keep(_ asset: Asset, playlist: Playlist) -> Bool {
        
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
                    // Check between lower...360 and 0...upper
                    return ((360 + lower)...360).contains(angle)
                        || (0...upper).contains(angle)
                } else if (upper >= 360) {
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
        return track.duration.contains(asset.length)
    }
}