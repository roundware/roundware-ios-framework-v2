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

class LoopAudio: NSObject, STKAudioPlayerDelegate {
    var current: String? = nil
    
    init(_ asset: String? = nil) {
        self.current = asset
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didStartPlayingQueueItemId queueItemId: NSObject) {
        if let c = current {
            audioPlayer.queue(c)
        }
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishBufferingSourceWithQueueItemId queueItemId: NSObject) {
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, stateChanged state: STKAudioPlayerState, previousState: STKAudioPlayerState) {
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishPlayingQueueItemId queueItemId: NSObject, with stopReason: STKAudioPlayerStopReason, andProgress progress: Double, andDuration duration: Double) {
        if let c = current {
            audioPlayer.queue(c)
        }
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, unexpectedError errorCode: STKAudioPlayerErrorCode) {
    }
}


class Playlist {
    // server communication
    private var lastUpdate: Date? = nil
    private var updateTimer: Timer? = nil
    private(set) var currentParams: StreamParams? = nil
    private(set) var startTime = Date()

    // assets and filters
    private var playlistFilters: [AssetFilter]
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
        self.playlistFilters = filters
        self.trackFilters = trackFilters
    }
    
    private func updateSpeakers() {
        let rw = RWFramework.sharedInstance
        let projectId = RWFrameworkConfig.getConfigValueAsNumber("project_id")
        
        rw.apiGetSpeakers([
            "project_id": projectId.stringValue,
            "activeyn": "true"
        ]).then { speakers in
            self.speakers = speakers
            self.playNearestSpeaker()
        }.catch { err in }
    }
    
    private func playNearestSpeaker() {
        // TODO: Blend all speakers that contain our location.
        if let params = self.currentParams {
            self.speakers.forEach { it in
                it.updateVolume(at: params.location)
            }
        }
    }
    
    func next(forTrack track: AudioTrack) -> Asset? {
        print("asset meta: " + userAssetData.description)
        let filteredAssets = self.filteredAssets.filter { asset in
            !self.trackFilters.contains { filter in
                !filter.keep(asset, playlist: self, track: track)
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
    
    
    private func updateTracks() {
        if (self.tracks.isEmpty) {
            let rw = RWFramework.sharedInstance
            let projectId = RWFrameworkConfig.getConfigValueAsNumber("project_id")
            
            rw.apiGetAudioTracks([
                "project_id": projectId.stringValue
            ]).then { data in
                self.tracks = data
                self.tracks.forEach { it in
                    // TODO: Try to remove playlist dependency. Maybe pass into method?
                    it.playlist = self
                    it.playNext()
                }
            }.catch { err in }
        } else {
            self.tracks.forEach { it in
                if it.currentAsset == nil {
                    it.playNext()
                } else {
                    it.updateParams(currentParams!)
                }
            }
        }
    }
    
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
        currentParams = opts
        let prevFiltered = filteredAssets
        
        playNearestSpeaker()
        
        // TODO: Time dependent assets.
        filteredAssets = allAssets.filter { item in
            !self.playlistFilters.contains { filter in
                !filter.keep(item, playlist: self)
            }
        }.sorted { a, b in
            if let locA = a.location, let locB = b.location {
                return locA.distance(from: opts.location) < locB.distance(from: opts.location)
            } else {
                return true
            }
        }
        
        // Clear data for assets we've moved away from.
        prevFiltered.forEach { a in
            if (!filteredAssets.contains { b in a.id == b.id }) {
                userAssetData.removeValue(forKey: a.id)
                self.tracks.first { it in
                    it.currentAsset?.id == a.id
                }?.playNext(premature: true)
            }
        }
        
        // Tell our tracks to grab audio if there's any new stuff
        self.updateTracks()
    }
    
    
    func start() {
        // Mark start of the session
        startTime = Date()
        
        // Start playing background music from speakers.
        updateSpeakers()
        
        // TODO: pre-iOS10 Timers using trigger function.
        if #available(iOS 10.0, *) {
            // Checks every couple minutes for newly published assets
            updateTimer = Timer(timeInterval: 5*60, repeats: true) { _ in
                self.updateAssets().then {
                    // TODO: Stop doing a full filter on every update.
                    if let opts = self.currentParams {
                        self.updateParams(opts)
                    }
                }
            }
        } else {
            // Fallback on earlier versions
        }
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


public extension CLLocation {
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
