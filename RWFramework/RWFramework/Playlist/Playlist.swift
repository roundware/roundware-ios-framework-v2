//
//  Playlist.swift
//  RWFramework
//
//  Created by Robert Snead on 6/26/18.
//  Copyright © 2018 Roundware. All rights reserved.
//

import Foundation
import CoreLocation
import AVKit
import StreamingKit
import Promises

struct UserAssetData {
    let lastListen: Date
}

struct StreamParams {
    let location: CLLocation
    let minDist: Int
    let maxDist: Int
    let heading: Float
    let angularWidth: Float
}



class Playlist {
    // server communication
    private var lastUpdate: Date? = nil
    private var updateTimer: Timer? = nil
    private(set) var currentParams: StreamParams? = nil
    private(set) var startTime = Date()

    // assets and filters

    private var playlistFilter: AllAssetFilters
    private var trackFilters: [TrackFilter]
    private var allAssets = [Asset]()
    private var filteredAssets = [Asset]()
    private var currentAsset: Asset? = nil
    /// Map asset ID to data like last listen time.
    private(set) var userAssetData = [Int: UserAssetData]()
    
    // audio tracks, background and foreground
    private(set) var speakers = [Speaker]()
    private(set) var tracks = [AudioTrack]()

    init(filters: [AssetFilter], trackFilters: [TrackFilter]) {
        self.playlistFilter = AllAssetFilters(filters)
        self.trackFilters = trackFilters
    }
    
    func apply(filter: AssetFilter) {
        playlistFilter.filters.append(filter)
    }
    func apply(filter: TrackFilter) {
        self.trackFilters.append(filter)
    }
    
    func lastListenDate(for asset: Asset) -> Date? {
        return self.userAssetData[asset.id]?.lastListen
    }
    
    /// Prepares all the speakers for this project.
    private func updateSpeakers() {
        let rw = RWFramework.sharedInstance
        let projectId = RWFrameworkConfig.getConfigValueAsNumber("project_id")
        
        rw.apiGetSpeakers([
            "project_id": projectId.stringValue,
            "activeyn": "true"
        ]).then { speakers in
            self.speakers = speakers
            self.updateSpeakerVolumes()
        }.catch { err in }
    }
    
    /// Update the volumes of all speakers depending
    /// our proximity to each one.
    private func updateSpeakerVolumes() {
        if let params = self.currentParams {
            self.speakers.forEach { it in
                it.updateVolume(at: params.location)
            }
        }
    }
    
    /// Picks the next-up asset to play on the given track.
    /// Applies all the playlist-level and track-level filters to make the decision.
    func next(forTrack track: AudioTrack) -> Asset? {
        let filteredAssets = self.filteredAssets.filter { asset in
            !self.trackFilters.contains { filter in
                filter.keep(asset, playlist: self, track: track) < 0
            }
        }
        var next = filteredAssets.first { it in
            return userAssetData[it.id] == nil
        }
        // If we've heard them all, play the least recently played.
        if next == nil {
            next = filteredAssets.min { a, b in
                if let dataA = userAssetData[a.id], let dataB = userAssetData[b.id] {
                    // Previously listened to.
                    return dataA.lastListen < dataB.lastListen
                    //                    let timeAgo = userData.lastListen.timeIntervalSinceNow
                    //                    let bannedAge = 60.0 * 20.0 // assets listened within 20 minutes banned
                    //                    if timeAgo < bannedAge {
                    //                        return false
                    //                    }
                }
                return true
            }
        }
        
        if let next = next {
            userAssetData.updateValue(UserAssetData(lastListen: Date()), forKey: next.id)
        }
        print("picking asset: " + next.debugDescription)
        return next
    }
    
    /// Grab the list of `AudioTrack`s for the current project.
    private func updateTracks() {
        if (self.tracks.isEmpty) {
            let rw = RWFramework.sharedInstance
            let projectId = RWFrameworkConfig.getConfigValueAsNumber("project_id")
            
            rw.apiGetAudioTracks([
                "project_id": projectId.stringValue
            ]).then { data in
                print("assets: using " + data.count.description + " tracks")
                self.tracks = data
                self.tracks.forEach { it in
                    // TODO: Try to remove playlist dependency. Maybe pass into method?
                    it.playlist = self
                    it.playNext(premature: false)
                }
            }.catch { err in }
        } else {
            self.tracks.forEach { it in
                if it.currentAsset == nil {
                    it.playNext(premature: false)
                } else {
                    it.updateParams(currentParams!)
                }
            }
        }
    }
    
    /// Retrieve audio assets stored on the server.
    /// At the start of a session, gets all the assets.
    /// After that, only adds the assets uploaded since the last call of this function.
    private func updateAssets() -> Promise<Void> {
        let rw = RWFramework.sharedInstance
        let projectId = RWFrameworkConfig.getConfigValueAsNumber("project_id")
        
        var opts = [
            "project_id": projectId.stringValue,
            "media_type": "audio",
            "language": "en",
            "submitted": "true"
        ]
        // Only grab assets added since the last update
        if let date = lastUpdate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            dateFormatter.locale = Locale.init(identifier: "en_US_POSIX")
            opts["created__gte"] = dateFormatter.string(from: date)
        }
        
        return rw.apiGetAssets(opts).then { data -> () in
            self.lastUpdate = Date()
            self.allAssets.append(contentsOf: data)
            print("all assets: " + self.allAssets.description)
        }.catch { err in }
    }
    
    /// Framework should call this when stream parameters are updated.
    func updateParams(_ opts: StreamParams) {
        print("assets: updating params")
        self.currentParams = opts
        self.updateParams()
    }
    
    private func updateParams() {
        let prevFiltered = filteredAssets
        
        print("assets: updating speakers")
        updateSpeakerVolumes()
        
        filteredAssets = allAssets.lazy.map { item in
            (item, self.playlistFilter.keep(item, playlist: self))
        }.filter { (item, rank) in
            rank >= 0
        }.sorted { a, b in
            return a.1 < b.1
        }.map { x in x.0 }
        print("assets filtered: " + filteredAssets.description)
        
        // Clear data for assets we've moved away from.
        prevFiltered.forEach { a in
            if (!filteredAssets.contains { b in a.id == b.id }) {
                userAssetData.removeValue(forKey: a.id)
                // stop a playing asset if we move away from it.
               self.tracks.first { it in
                   it.currentAsset?.id == a.id
               }?.playNext(premature: true)
            }
        }
        
        // Tell our tracks to play any new assets.
        self.updateTracks()
    }
    
    /// Periodically check for newly published assets
    @objc private func heartbeat() {
        self.updateAssets().then {
            // Update filtered assets given any newly uploaded assets
            self.updateParams()
        }
    }
    
    /**
     * Retrieve tags to filter by for the current project.
     * Setup the speakers for background audio.
     * Retrieve the list of all assets and check for new assets every few minutes.
    **/
    func start() {
        // Mark start of the session
        startTime = Date()
        
        // Start playing background music from speakers.
        updateSpeakers()
        
        updateTimer = Timer(
            timeInterval: 5*60,
            target: self,
            selector: #selector(self.heartbeat),
            userInfo: nil,
            repeats: true
        )
        // Initial grab of assets and speakers.
        updateTimer?.fire()
    }
    
    func pause() {
        speakers.forEach { it in it.pause() }
        tracks.forEach { it in it.pause() }
    }
    
    func resume() {
        speakers.forEach { it in it.resume() }
        tracks.forEach { it in it.resume() }
    }
}


extension CLLocation {
    func bearingToLocationRadian(_ destinationLocation: CLLocation) -> Double {
        
        let lat1 = self.coordinate.latitude.degreesToRadians
        let lon1 = self.coordinate.longitude.degreesToRadians
        
        let lat2 = destinationLocation.coordinate.latitude.degreesToRadians
        let lon2 = destinationLocation.coordinate.longitude.degreesToRadians
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return radiansBearing
    }
    
    func bearingToLocationDegrees(_ destinationLocation: CLLocation) -> Double {
        return bearingToLocationRadian(destinationLocation).radiansToDegrees
    }
}

extension Double {
    var degreesToRadians: Double { return self * .pi / 180 }
    var radiansToDegrees: Double { return self * 180 / .pi }
}
