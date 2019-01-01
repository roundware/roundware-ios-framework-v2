//
//  AudioTrack.swift
//  RWFramework
//
//  Created by Taylor Snead on 7/17/18.
//  Copyright © 2018 Roundware. All rights reserved.
//

import Foundation
import StreamingKit
import SwiftyJSON
import CoreLocation
import SceneKit
import AVKit

/// An AudioTrack has a set of parameters determining how its audio is played.
/// Assets are provided by the Playlist, so they must match any geometric parameters.
/// There can be an arbitrary number of audio tracks playing at once
/// When one needs an asset, it simply grabs the next available matching one from the Playlist.
public class AudioTrack {
    let id: Int
    let volume: ClosedRange<Float>
    let duration: ClosedRange<Float>
    let deadAir: ClosedRange<Float>
    let fadeInTime: ClosedRange<Float>
    let fadeOutTime: ClosedRange<Float>
    let repeatRecordings: Bool
    var playlist: Playlist? = nil
    var currentAsset: Asset? = nil
//    private var nextAsset: Asset? = nil
    private var fadeTimer: Timer? = nil
//    private var currentAssetEnd: Double? = nil
    private var fadeOutTimer: Timer? = nil
    private var currentAssetDuration: Double? = nil
    private var lastResumeTime: Date? = nil
    private var currentProgress: Double? = nil

    let player = AVAudioPlayerNode()
    // SceneKit version
//    private var player: SCNAudioPlayer? = nil
//    let node: SCNNode = SCNNode()

    private var playerVolume: Float {
        get {
            return player.volume
//            if let mixer = player.audioNode as? AVAudioMixerNode {
//                return mixer.volume
//            }
//            return 0.0
        }
        set(value) {
            player.volume = value
//            if let mixer = player!.audioNode as? AVAudioMixerNode {
//                mixer.volume = value
//            }
        }
    }

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
}

extension AudioTrack {
    static func from(data: Data) throws -> [AudioTrack] {
        let items = try JSON(data: data).arrayValue
        return items.map { it in
            AudioTrack(
                id: it["id"].intValue,
                volume: (it["minvolume"].floatValue)...(it["maxvolume"].floatValue),
                duration: (it["minduration"].floatValue)...(it["maxduration"].floatValue),
                deadAir: (it["mindeadair"].floatValue)...(it["maxdeadair"].floatValue),
                fadeInTime: (it["minfadeintime"].floatValue)...(it["maxfadeintime"].floatValue),
                fadeOutTime: (it["minfadeouttime"].floatValue)...(it["maxfadeouttime"].floatValue),
                repeatRecordings: it["repeatrecordings"].bool ?? false
            )
        }
    }
    
    private func holdSilence() {
        let time = TimeInterval(self.deadAir.random())
        print("silence for \(time)")
        if #available(iOS 10.0, *) {
            fadeTimer?.invalidate()
            fadeTimer = Timer.scheduledTimer(withTimeInterval: time, repeats: false) { _ in
                self.playNext(premature: false)
            }
        } else {
            // Fallback on earlier versions
        }
    }

    private func setDynamicPan(at assetLoc: CLLocation, _ params: StreamParams) {
        // TODO: Confirm this is degrees
//        guard let heading = params.heading else { return }
//        print("heading = \(heading)")
//        var angle = params.location.angle(to: assetLoc).radiansToDegrees - heading
        player.position = assetLoc.toAudioPoint()
        print("asset is at position \(player.position)")
    }
    
    func updateParams(_ params: StreamParams) {
        if let assetLoc = currentAsset?.location {
            setDynamicPan(at: assetLoc, params)
        }
    }
    
    
    /// Plays the next optimal asset nearby.
    /// @arg premature True if skipping the current asset, rather than fading at the end of it.
    func playNext(premature: Bool = true) {
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
            // Just fade in for the first asset or at the end of an asset
            fadeIn()
        }
    }
    
    private func fadeIn(cb: @escaping () -> Void = {}) {
        if let next = playlist?.next(forTrack: self) {
            currentAsset = next

            // pick a random duration
            // start at a random position between start and end - duration
            let minDuration = min(Double(self.duration.lowerBound), currentAsset!.length)
            let maxDuration = min(Double(self.duration.upperBound), currentAsset!.length)
            let duration = (minDuration...maxDuration).random()
            let latestStart = currentAsset!.length - duration
            let start = (0.0...latestStart).random()

            print("picking start within \(0.0...latestStart): \(start)")
            print("picking duration within \(minDuration...maxDuration): \(duration)")
            print("start at \(start) in asset of \(currentAsset!.length) sec")

            do {
                try loadNextAsset(start: start, for: duration)
            } catch {
                print(error)
                currentAsset = nil
                return
            }

            updateParams(playlist!.currentParams!)

            playerVolume = 0.0
            let interval = 0.075 // seconds
            if #available(iOS 10.0, *) {
                let totalTime = fadeInTime.random()
                let target = volume.random()
                print("asset: fading in for \(totalTime) to volume \(target), play for \(duration)")
                fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
                    if self.playerVolume < self.volume.upperBound {
                        let toAdd = Float(interval) / totalTime
                        self.playerVolume += toAdd
                    } else {
                        self.playerVolume = target
                        self.fadeTimer?.invalidate()
                        self.fadeTimer = nil
                        self.setupFadeEndTimer(endTime: duration)
                        cb()
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        } else {
            currentAsset = nil
        }
    }
    
    private func fadeOut(forSeconds fadeTime: Float = 0, cb: @escaping () -> Void = {}) {
        let interval = 0.075 // seconds
        if #available(iOS 10.0, *) {
            var totalTime = fadeTime
            if (totalTime == 0) {
                totalTime = fadeOutTime.random()
            }
            print("asset: fade out for \(totalTime)")
            fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
                if self.playerVolume >= 0.1 {
                    self.playerVolume -= Float(interval) / totalTime
                } else {
                    self.playerVolume = 0.0
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
    private func loadNextAsset(start: Double? = nil, for duration: Double? = nil) throws {
//        if let next = playlist?.next(forTrack: self) {
//            player.queue(next.file)
//            if currentAsset == nil {
//                currentAsset = next
//            } else {
//                nextAsset = next
//            }
            
//            if let player = self.player {
//                node.removeAudioPlayer(player)
//            }

//            self.currentAsset = next

            // Download asset into memory
            print("downloading asset")

//            do {
                let remoteUrl = URL(string: currentAsset!.file)!
                let data = try Data(contentsOf: remoteUrl)
                print("asset downloaded as \(remoteUrl.lastPathComponent)")
                // have to write to file...
                // Write it to the cache folder so we can easily clean up later.
                let documentsDir = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let url = documentsDir.appendingPathComponent(remoteUrl.lastPathComponent)
                try data.write(to: url, options: .atomic)

                let file = try AVAudioFile(forReading: url)

                if let start = start, let duration = duration {
                    let startFrame = Int64(start * file.processingFormat.sampleRate)
                    let frameCount = UInt32(duration * file.processingFormat.sampleRate)
                    player.scheduleSegment(file, startingFrame: startFrame, frameCount: frameCount, at: nil)
                } else {
                    player.scheduleFile(file, at: nil)
                }

                if !player.isPlaying {
                    player.play()
                }
//            } catch {
//                print(error)
//            }

            // SceneKit version
//            let source = SCNAudioSource(url: url)!
//            source.shouldStream = false
//            source.isPositional = false
//            source.load()
//            node.runAction(SCNAction.playAudio(source, waitForCompletion: true))
//            self.player = SCNAudioPlayer(source: source)
//            node.addAudioPlayer(player!)
//        }
    }
    
    func pause() {
        player.pause()
        fadeOutTimer?.invalidate()
        if let prog = currentProgress, let lastResumeTime = lastResumeTime {
            currentProgress = prog + Date().timeIntervalSince(lastResumeTime)
        } else {
            currentProgress = Date().timeIntervalSince(lastResumeTime!)
        }
    }
    
    func resume() {
        player.play()
        setupFadeEndTimer()
    }

    /// @param endTime end time within the asset
    private func setupFadeEndTimer(endTime: Double = 0) {
        // pick a fade-out length
        var fadeDur = 0.0
        if endTime == 0 {
            // we have resumed
            let progressInSecs = self.currentProgress! / 1000.0
            print("current progress in asset: \(progressInSecs)")
            fadeDur = self.currentAssetDuration! - progressInSecs
        } else {
            // we're just starting the asset
            fadeDur = max(0.1, endTime - Double(self.fadeOutTime.random()))
            self.currentAssetDuration = fadeDur
        }
        lastResumeTime = Date()

        print("playing for another \(fadeDur) sec")
        
        fadeOutTimer?.invalidate()
        if #available(iOS 10.0, *) {
            fadeOutTimer = Timer.scheduledTimer(withTimeInterval: fadeDur, repeats: false) { timer in
                self.fadeOut {
                    self.currentAssetDuration = nil
                    self.currentAsset = nil
                    self.currentProgress = nil
                    self.holdSilence()
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
extension ClosedRange where Bound == Double {
    func random() -> Bound {
        return lowerBound + drand48() * difference
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

extension CLLocation {
    func angle(to destinationLocation: CLLocation) -> Double {
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
}
