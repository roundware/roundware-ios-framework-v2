//
//  AudioTrack.swift
//  RWFramework
//
//  Created by Taylor Snead on 7/17/18.
//  Copyright © 2018 Roundware. All rights reserved.
//

import Foundation
import StreamingKit

/// An AudioTrack has a set of parameters determining how its audio is played.
/// Assets are provided by the Playlist, so they must match any geometric parameters.
/// There can be an arbitrary number of audio tracks playing at once
/// When one needs an asset, it simply grabs the next available matching one from the Playlist.
public class AudioTrack: NSObject, STKAudioPlayerDelegate {
    let id: Int
    let volume: ClosedRange<Float>
    let duration: ClosedRange<Float>
    let deadAir: ClosedRange<Float>
    let fadeInTime: ClosedRange<Float>
    let fadeOutTime: ClosedRange<Float>
    let repeatRecordings: Bool
    private let player = STKAudioPlayer(options: {
        var opts = STKAudioPlayerOptions()
        opts.enableVolumeMixer = true
        return opts
    }())
    var playlist: Playlist? = nil
    var currentAsset: Asset? = nil
    private var nextAsset: Asset? = nil
    private var fadeTimer: Timer? = nil
    private var currentAssetDuration: Float? = nil
    private var fadeOutTimer: Timer? = nil
    
    init(
        id: Int,
        volume: ClosedRange<Float>,
        duration: ClosedRange<Float>,
        deadAir: ClosedRange<Float>,
        fadeInTime: ClosedRange<Float>,
        fadeOutTime: ClosedRange<Float>,
        repeatRecordings: Bool
    ) {
        self.id = id
        self.volume = volume
        self.duration = duration
        self.deadAir = deadAir
        self.fadeInTime = fadeInTime
        self.fadeOutTime = fadeOutTime
        self.repeatRecordings = repeatRecordings
    }
    
    
    static func from(data: Data) throws -> [AudioTrack] {
        let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
        
        let items = json as! [AnyObject]
        return items.map { obj in
            let it = obj as! [String: AnyObject]
            return AudioTrack(
                id: it["id"] as! Int,
                volume: (it["minvolume"] as! Float)...(it["maxvolume"] as! Float),
                duration: (it["minduration"] as! Float)...(it["maxduration"] as! Float),
                deadAir: (it["mindeadair"] as! Float)...(it["maxdeadair"] as! Float),
                fadeInTime: (it["minfadeintime"] as! NSNumber).floatValue...(it["maxfadeintime"] as! NSNumber).floatValue,
                fadeOutTime: (it["minfadeouttime"] as! NSNumber).floatValue...(it["maxfadeouttime"] as! NSNumber).floatValue,
                repeatRecordings: it["repeatrecordings"] as! Bool
            )
        }
    }
    
    
    public func audioPlayer(_ audioPlayer: STKAudioPlayer, didStartPlayingQueueItemId queueItemId: NSObject) {
        fadeIn()
    }
    
    public func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishBufferingSourceWithQueueItemId queueItemId: NSObject) {
        
    }
    
    public func audioPlayer(_ audioPlayer: STKAudioPlayer, stateChanged state: STKAudioPlayerState, previousState: STKAudioPlayerState) {
    }
    
    public func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishPlayingQueueItemId queueItemId: NSObject, with stopReason: STKAudioPlayerStopReason, andProgress progress: Double, andDuration duration: Double) {
        holdSilence()
    }
    
    public func audioPlayer(_ audioPlayer: STKAudioPlayer, unexpectedError errorCode: STKAudioPlayerErrorCode) {
        
    }
    
    private func holdSilence() {
        player.pause()
        let time = TimeInterval(self.deadAir.random())
        if #available(iOS 10.0, *) {
            fadeTimer?.invalidate()
            fadeTimer = Timer.scheduledTimer(withTimeInterval: time, repeats: false) { _ in
                self.currentAsset = nil
                self.playNext(premature: false)
                self.player.resume()
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func updateParams(_ params: StreamParams) {
        // TODO: Pan based on user and asset positions
        if let asset = currentAsset, asset.location != nil {
            // scale volume based on the asset's distance from us
            // TODO: Confirm the ratio scaling. Should we be using the dynamic range or a project setting? Probably a setting.
            let dist = Float(asset.location!.distance(from: params.location))
            let distRange: ClosedRange<Float>
            if let maxDist = params.maxDist, let minDist = params.minDist {
                // if we have a custom distance range,
                // interpolate asset volume within that.
                distRange = Float(minDist)...Float(maxDist)
            } else {
                // otherwise, just use the default project distance to scale the asset volume
                distRange = 0...Float(playlist!.project.recording_radius)
            }
            let distRatio = (dist - distRange.lowerBound) / distRange.difference
            let clampedRatio = distRatio.clamp(to: 0...1)

            player.volume = volume.lowerBound + (distRatio * volume.difference)
        }
    }
    
    
    /// Plays the next optimal asset nearby.
    /// @arg premature True if skipping the current asset, rather than fading at the end of it.
    func playNext(premature: Bool = true) {
        self.player.delegate = self
        
        // Stop any timer set to fade at the natural end of an asset
        fadeTimer?.invalidate()
        
        // Can't fade out if playing the first asset
        if (premature) {
            fadeOut(forSeconds: fadeOutTime.lowerBound) {
                self.player.stop()
                self.playNext(premature: false)
                self.currentAssetDuration = nil
            }
        } else {
            // TODO: Start fade out a bit before an asset finishes playing?
            // Just fade in for the first asset or at the end of an asset
            queueNext()
        }
    }
    
    private func fadeIn(cb: @escaping () -> Void = {}) {
        // pick a random duration
        // start at a random position between start and end - duration
        let duration = self.duration.random()
        let latestStart = currentAsset!.length - duration
        let start = (0...latestStart).random()
        
        player.seek(toTime: Double(start))
        
        player.volume = 0.0
        let interval = 0.075 // seconds
        if #available(iOS 10.0, *) {
            let totalTime = fadeInTime.random()
            let target = volume.random()
            print("asset: fading in for " + totalTime.description)
            fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
                if self.player.volume < self.volume.upperBound {
                    self.player.volume += Float(interval) / totalTime
                } else {
                    self.player.volume = target
                    self.fadeTimer?.invalidate()
                    self.fadeTimer = nil
                    cb()
                }
            }
        } else {
            // Fallback on earlier versions
        }
        
        setupFadeEndTimer(endTime: start + duration)
    }
    
    private func fadeOut(forSeconds fadeTime: Float = 0, cb: @escaping () -> Void = {}) {
        let interval = 0.075 // seconds
        if #available(iOS 10.0, *) {
            var totalTime = fadeTime
            if (totalTime == 0) {
                totalTime = fadeOutTime.random()
            }
            print("asset: fade out for " + totalTime.description)
            fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
                if self.player.volume > 0.0 {
                    self.player.volume -= Float(interval) / totalTime
                } else {
                    self.player.volume = 0.0
                    self.fadeTimer?.invalidate()
                    self.fadeTimer = nil
                    cb()
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    /// Queues the next asset to play
    /// If there's nothing playing, immediately plays one and queues another.
    private func queueNext() {
        if let next = playlist!.next(forTrack: self) {
            player.queue(next.file)
            currentAsset = next
        }
    }
    
    func pause() {
        player.pause()
        fadeOutTimer?.invalidate()
    }
    
    func resume() {
        player.resume()
        setupFadeEndTimer()
    }

    private func setupFadeEndTimer(endTime: Float = 0) {
        // pick a fade-out length
        if currentAssetDuration == nil {
            var assetEndTime = endTime
            if assetEndTime == 0 {
                assetEndTime = currentAsset!.length
            }
            currentAssetDuration = assetEndTime - fadeOutTime.random()
        }
        let fadeDur = Double(currentAssetDuration!) - player.progress
        
        fadeOutTimer?.invalidate()
        if #available(iOS 10.0, *) {
            fadeOutTimer = Timer.scheduledTimer(withTimeInterval: fadeDur, repeats: false) { timer in
                self.fadeOut {
                    self.currentAssetDuration = nil
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
}

extension ClosedRange where Bound == Float {
    func random() -> Bound {
        return lowerBound + Bound(drand48()) * (upperBound - lowerBound)
    }
}

extension ClosedRange where Bound: Numeric {
    var difference: Bound {
        return upperBound - lowerBound
    }
}

extension Comparable {
    func clamp(to: ClosedRange<Self>) -> Self {
        return max(to.lowerBound, min(to.upperBound, self))
    }
}