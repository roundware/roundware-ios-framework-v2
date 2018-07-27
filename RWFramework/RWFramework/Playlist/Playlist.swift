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
    let current: String
    
    init(_ asset: String) {
        self.current = asset
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didStartPlayingQueueItemId queueItemId: NSObject) {
        audioPlayer.queue(current)
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishBufferingSourceWithQueueItemId queueItemId: NSObject) {
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, stateChanged state: STKAudioPlayerState, previousState: STKAudioPlayerState) {
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishPlayingQueueItemId queueItemId: NSObject, with stopReason: STKAudioPlayerStopReason, andProgress progress: Double, andDuration duration: Double) {
        audioPlayer.queue(current)
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, unexpectedError errorCode: STKAudioPlayerErrorCode) {
    }
}


class Playlist {
    private var allAssets = [Asset]()
    private var filteredAssets = [Asset]()
    private var currentAsset: Asset? = nil
    
    private var speakers = [Speaker]()
    private var currentSpeaker: Speaker? = nil
    
    private var tracks = [AudioTrack]()
    
    private var lastUpdate: Date? = nil
    private var updateTimer: Timer? = nil
    private var currentParams: StreamParams? = nil
    
    private let speakerPlayer = STKAudioPlayer()
    private var speakerLooper: LoopAudio? = nil
    private var startTime = Date()
    
    /// Map asset ID to data like last listen time.
    private var userAssetData = [Int: UserAssetData]()
    
    private func updateSpeakers() {
        let rw = RWFramework.sharedInstance
        let projectId = RWFrameworkConfig.getConfigValueAsNumber("project_id")
        
        rw.apiGetSpeakers([
            "project_id": projectId.stringValue,
            "activeyn": "true"
        ], success: { (data) in
            do {
                self.speakers = try Speaker.fromJson(data!)
                self.playNearestSpeaker()
            } catch {}
        }, failure: { err in })
    }
    
    private func playNearestSpeaker() {
        // TODO: Blend all speakers that contain our location.
        if let params = self.currentParams {
            if let nearest = self.speakers.first(where: { it in
                it.volume(at: params.location) > 0.0
            }) {
                if (self.currentSpeaker?.id != nearest.id) {
                    self.currentSpeaker = nearest
                    self.speakerLooper = LoopAudio(nearest.url)
                    self.speakerPlayer.delegate = self.speakerLooper
                    self.speakerPlayer.play(nearest.url)
                }
                self.speakerPlayer.volume = nearest.volume(at: params.location)
            } else {
                // TODO: Fade out!
                self.speakerLooper = nil
                self.speakerPlayer.delegate = nil // stop looping
                self.speakerPlayer.stop()
            }
        }
    }
    
    func next() -> Asset? {
        print("asset meta: " + userAssetData.description)
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
            ], success: { data in
                do {
                    self.tracks = try AudioTrack.fromJson(self, data!)
                    self.tracks.forEach { it in it.playNext() }
                } catch {}
            }, failure: { err in })
        } else {
            self.tracks.forEach { it in
                if it.currentAsset == nil {
                    it.playNext()
                }
            }
        }
    }
    
    private func updateAssets(_ cb: @escaping () -> Void = {}) {
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
        
        rw.apiGetAssets(opts, success: { (data) in
            self.lastUpdate = Date()
            do {
                self.allAssets.append(contentsOf: try Asset.fromJson(data!))
                print("all assets: " + self.allAssets.description)
            } catch {}
            cb()
        }, failure: { err in })
    }
    
    /// Framework should call this when stream parameters are updated.
    func updateParams(_ opts: StreamParams) {
        currentParams = opts
        let prevFiltered = filteredAssets
        
        playNearestSpeaker()
        
        filteredAssets = allAssets.filter { item in
            if let loc = item.location {
                let dist = opts.location.distance(from: loc)
                if (dist < Double(opts.minDist) || dist > Double(opts.maxDist)) {
                    print("filtered asset out by dist: " + dist.description)
                    return false
                }
                
                // TODO: Include calculations for overflow (1 being next to 359)
                if (opts.angularWidth <= 359) {
                    let angle = Float(opts.location.bearingToLocationDegrees(loc))
                    if angle < opts.heading - opts.angularWidth
                        || angle > opts.heading + opts.angularWidth {
                        return false
                    }
                }
            }
            
            // TODO: Time dependent assets.
            return true
        }.sorted { a, b in
            if let locA = a.location, let locB = b.location {
                return locA.distance(from: opts.location) < locB.distance(from: opts.location)
            } else {
                return true
            }
        }
        
        print("prev assets: " + prevFiltered.description)
        print("filtered assets: " + filteredAssets.description)
        
        // Clear data for assets we've moved away from.
        prevFiltered.forEach { a in
            if (!filteredAssets.contains { b in a.id == b.id }) {
                userAssetData.removeValue(forKey: a.id)
                self.tracks.first { it in
                    it.currentAsset?.id == a.id
                }?.playNext(premature: true)
                
                // TODO: Move this code to AudioTrack
                // If we've moved away from the current asset, fade it away.
//                if (a.id == self.currentAsset?.id) {
//                    self.playNext(premature: true)
//                }
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
                self.updateAssets {
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
        speakerPlayer.pause()
        tracks.forEach { it in it.pause() }
    }
    
    func resume() {
        speakerPlayer.resume()
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
