//
//  AudioTrack.swift
//  RWFramework
//
//  Created by Taylor Snead on 7/17/18.
//  Copyright © 2018 Roundware. All rights reserved.
//

import Foundation
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
    let tags: [Int]?
    let bannedDuration: Double
    let startWithSilence: Bool
    
    var playlist: Playlist? = nil
    var previousAsset: Asset? = nil
    var currentAsset: Asset? = nil
    var state: TrackState? = nil

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
        repeatRecordings: Bool,
        tags: [Int]?,
        bannedDuration: Double,
        startWithSilence: Bool
    ) {
        self.id = id
        self.volume = volume
        self.duration = duration
        self.deadAir = deadAir
        self.fadeInTime = fadeInTime
        self.fadeOutTime = fadeOutTime
        self.repeatRecordings = repeatRecordings
        self.tags = tags
        self.bannedDuration = bannedDuration
        self.startWithSilence = startWithSilence
    }
}

extension AudioTrack {
    static func from(data: Data) throws -> [AudioTrack] {
        let items = try JSON(data: data).array!
        return items.map { item in
            let it = item.dictionary!
            return AudioTrack(
                id: it["id"]!.int!,
                volume: (it["minvolume"]!.float!)...(it["maxvolume"]!.float!),
                duration: (it["minduration"]!.float!)...(it["maxduration"]!.float!),
                deadAir: (it["mindeadair"]!.float!)...(it["maxdeadair"]!.float!),
                fadeInTime: (it["minfadeintime"]!.float!)...(it["maxfadeintime"]!.float!),
                fadeOutTime: (it["minfadeouttime"]!.float!)...(it["maxfadeouttime"]!.float!),
                repeatRecordings: it["repeatrecordings"]?.bool ?? false,
                tags: it["tag_filters"]?.array?.map { $0.int! },
                bannedDuration: it["banned_duration"]?.double ?? 600,
                startWithSilence: it["start_with_silence"]?.bool ?? true
            )
        }
    }

    private func setDynamicPan(at assetLoc: CLLocation, _ params: StreamParams) {
        player.position = assetLoc.toAudioPoint(relativeTo: params.location)
    }
    
    func updateParams(_ params: StreamParams) {
        if let assetLoc = currentAsset?.location {
            setDynamicPan(at: assetLoc, params)
        }
    }
    
    /// Plays the next optimal asset nearby.
    /// @arg premature True if skipping the current asset, rather than fading at the end of it.
    func playNext(premature: Bool = true) {
        // Can't fade out if playing the first asset
        if (premature) {
            transition(to: FadingOut(
                track: self,
                asset: currentAsset!,
                duration: Double(fadeOutTime.lowerBound)
            ))
        } else {
            // Just fade in for the first asset or at the end of an asset
            fadeInNextAsset()
        }
    }
    
    /// Downloads and starts playing the currently selected asset
    private func loadNextAsset(start: Double? = nil, for duration: Double? = nil) throws {
        // Download asset into memory
        print("downloading asset")
        let remoteUrl = URL(string: currentAsset!.file)!
            .deletingPathExtension()
            .appendingPathExtension("mp3")
        
        let data = try Data(contentsOf: remoteUrl)
        print("asset downloaded as \(remoteUrl.lastPathComponent)")
        // have to write to file...
        // Write it to the cache folder so we can easily clean up later.
        let documentsDir = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        // Remove file of last played asset
        if let prev = previousAsset {
            let fileName = URL(string: prev.file)!
                .deletingPathExtension()
                .appendingPathExtension("mp3")
                .lastPathComponent
            
            let prevAssetUrl = documentsDir.appendingPathComponent(fileName)
            try FileManager.default.removeItem(at: prevAssetUrl)
        }
        
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
            if let params = playlist?.currentParams {
                updateParams(params)
            }
        }

        if let params = self.playlist?.currentParams {
            self.updateParams(params)
        }
    }
    
    func pause() {
        state?.pause()
    }
    
    func resume() {
        if let state = state {
            state.resume()
        } else if self.startWithSilence {
            holdSilence()
        } else {
            fadeInNextAsset()
        }
    }
    
    func transition(to state: TrackState) {
        self.state?.finish()
        self.state = state
        state.start()
    }
    
    func holdSilence() {
        transition(to: DeadAir(track: self))
    }
    
    /// - returns: if an asset has been chosen and started
    func fadeInNextAsset() {
        if let next = self.playlist?.next(forTrack: self) {
            previousAsset = currentAsset
            currentAsset = next
            
            let activeRegionLength = Double(next.activeRegion.upperBound - next.activeRegion.lowerBound)
            let minDuration = min(Double(self.duration.lowerBound), activeRegionLength)
            let maxDuration = min(Double(self.duration.upperBound), activeRegionLength)
            let duration = (minDuration...maxDuration).random()
            let latestStart = Double(next.activeRegion.upperBound) - duration
            let start = (Double(next.activeRegion.lowerBound)...latestStart).random()
            
            // load the asset file
            do {
                try loadNextAsset(start: start, for: duration)
            } catch {
                print(error)
                playNext()
                return
            }
            
            transition(to: FadingIn(
                track: self,
                asset: next,
                assetDuration: duration
            ))
        } else if !(self.state is WaitingForAsset) {
            transition(to: WaitingForAsset(track: self))
        }
    }
}


/**
 Common sequence of states:
 Silence => FadingIn => PlayingAsset => FadingOut => Silence
 */
protocol TrackState {
    func start()
    func finish()
    func pause()
    func resume()
}

private class TimedTrackState: TrackState {
    private(set) var timeLeft: Double
    private(set) var timer: Timer? = nil
    private var lastResume = Date()
    
    init(duration: Double) {
        self.timeLeft = duration
    }
    
    func start() {
        resume()
    }
    func finish() {
        timer?.invalidate()
    }
    func goToNextState() {
    }
    func pause() {
        timer?.invalidate()
        timeLeft -= Date().timeIntervalSince(lastResume)
    }
    
    func setupTimer() -> Timer {
        return Timer.scheduledTimer(withTimeInterval: timeLeft, repeats: false) { _ in
            self.goToNextState()
        }
    }

    func resume() {
        lastResume = Date()
        timer = setupTimer()
    }
}

/// Silence between assets
private class DeadAir: TimedTrackState {
    private let track: AudioTrack
    
    init(track: AudioTrack) {
        self.track = track
        super.init(duration: Double(track.deadAir.random()))
    }
    
    override func resume() {
        super.resume()
        print("silence for \(timeLeft)s")
    }
    
    override func goToNextState() {
        self.track.fadeInNextAsset()
    }
}

/// Fading into the playing asset
private class FadingIn: TimedTrackState {
    private static let updateInterval = 0.075
    
    private let track: AudioTrack
    private let asset: Asset
    private let fullVolumeDuration: Double
    private let targetVolume: Float
    
    init(
        track: AudioTrack,
        asset: Asset,
        // total chosen duration of asset, including fade in and out
        assetDuration: Double
    ) {
        self.track = track
        self.asset = asset
        
        let fadeInDur = min(Double(track.fadeInTime.random()), assetDuration / 2)
        
        self.targetVolume = track.volume.random()
        
        // (total duration of asset) - (fade in duration)
        self.fullVolumeDuration = assetDuration - fadeInDur
        
        super.init(duration: fadeInDur)
    }
    
    override func setupTimer() -> Timer {
        return Timer.scheduledTimer(
            withTimeInterval: FadingIn.updateInterval,
            repeats: true
        ) { _ in
            if self.track.player.volume < self.targetVolume {
                let toAdd = FadingIn.updateInterval / self.timeLeft
                self.track.player.volume += Float(toAdd)
            } else {
                print("asset at full volume \(self.targetVolume)")
                self.track.player.volume = self.targetVolume
                self.goToNextState()
            }
        }
    }
    
    override func start() {
        track.player.volume = 0
        super.start()
    }
    
    override func resume() {
        super.resume()
        track.player.play()
        print("fading in for \(timeLeft)s, to volume \(targetVolume)")
    }
    
    override func pause() {
        super.pause()
        track.player.pause()
    }
    
    override func goToNextState() {
        track.transition(to: PlayingAsset(
            track: track,
            asset: asset,
            duration: fullVolumeDuration
        ))
    }
}


/// Fully faded in, playing an asset
private class PlayingAsset: TimedTrackState {
    private let track: AudioTrack
    private let asset: Asset
    private let fadeOutDuration: Double
    
    init(
        track: AudioTrack,
        asset: Asset,
        /// total duration of asset including fade out time
        duration: Double
    ) {
        self.track = track
        self.asset = asset
        fadeOutDuration = min(Double(track.fadeOutTime.random()), duration / 2)
        // duration of the asset excluding any fades
        let fullVolumeDuration = duration - fadeOutDuration
        super.init(duration: fullVolumeDuration)
    }
    
    override func pause() {
        super.pause()
        track.player.pause()
    }
    
    override func resume() {
        super.resume()
        track.player.play()
        print("playing for another \(timeLeft)s")
    }
    
    override func goToNextState() {
        track.transition(to: FadingOut(
            track: track,
            asset: asset,
            duration: fadeOutDuration
        ))
    }
}

/// Fading out of the playing asset
private class FadingOut: TimedTrackState {
    private static let updateInterval = 0.075
    
    private let track: AudioTrack
    private let asset: Asset
    
    init(
        track: AudioTrack,
        asset: Asset,
        duration: Double
    ) {
        self.track = track
        self.asset = asset
        super.init(duration: duration)
    }
    
    override func setupTimer() -> Timer {
        return Timer.scheduledTimer(
            withTimeInterval: FadingOut.updateInterval,
            repeats: true
        ) { _ in
            if self.track.player.volume > 0 {
                let toAdd = FadingOut.updateInterval / self.timeLeft
                self.track.player.volume -= Float(toAdd)
            } else {
                self.track.player.volume = 0
                self.goToNextState()
            }
        }
    }
    
    override func resume() {
        super.resume()
        track.player.play()
        print("fading out for \(timeLeft)s")
    }
    
    override func pause() {
        super.pause()
        track.player.pause()
    }
    
    override func goToNextState() {
        track.transition(to: DeadAir(track: track))
    }
}

/// Waiting for relevant assets to be available
private class WaitingForAsset: TimedTrackState {
    private static let updateInterval = 10.0 // seconds
    
    private let track: AudioTrack
    
    init(track: AudioTrack) {
        self.track = track
        super.init(duration: 0)
    }
    
    override func setupTimer() -> Timer {
        return Timer.scheduledTimer(
            withTimeInterval: WaitingForAsset.updateInterval,
            repeats: true
        ) { _ in
            // keep attempting to play the next asset
            self.track.fadeInNextAsset()
        }
    }
}


extension ClosedRange where Bound == Float {
    func random() -> Bound {
        return Bound.random(in: self)
    }
}
extension ClosedRange where Bound == Double {
    func random() -> Bound {
        return Bound.random(in: self)
    }
}

extension ClosedRange where Bound: Numeric {
    var difference: Bound {
        return upperBound - lowerBound
    }
}
