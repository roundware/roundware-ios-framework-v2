//
//  AssetFilter.swift
//  RWFramework
//
//  Created by Taylor Snead on 7/31/18.
//  Copyright © 2018 Roundware. All rights reserved.
//

import Foundation

protocol AssetFilter {
    /// @return true to keep the given asset
    func apply(playlist: Playlist, asset: Asset) -> Bool
}

class LocationFilter: AssetFilter {
    func apply(playlist: Playlist, asset: Asset) -> Bool {
        let opts = playlist.currentParams!
        if let loc = asset.location {
            let dist = opts.location.distance(from: loc)
            return dist >= Double(opts.minDist) && dist <= Double(opts.maxDist)
        }
        return true
    }
}

class AngleFilter: AssetFilter {
    func apply(playlist: Playlist, asset: Asset) -> Bool {
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
