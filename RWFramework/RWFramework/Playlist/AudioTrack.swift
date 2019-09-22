
import Foundation
import CoreLocation
import SceneKit
import AVKit
import Promises
import Repeat
import KeyedCodable

/**
 An AudioTrack has a set of parameters determining how its audio is played.
 Assets are provided by the Playlist, so they must match any geometric parameters.
 There can be an arbitrary number of audio tracks playing at once.
 When one needs an asset, it simply grabs the next available matching one from the Playlist.
 */
public class AudioTrack: Codable {
    let id: Int
    let repeatRecordings: Bool
    let tags: [Int]?
    let bannedDuration: Double = 600
    let startWithSilence: Bool = true
    /**
     Whether to fade out the playing asset if it gets filtered out.
     Also enables resuming that asset if it quickly passes the filters again.
     */
    let fadeOutWhenFiltered: Bool = true
    
    var playlist: Playlist? = nil
    var previousAsset: Asset? = nil
    var currentAsset: Asset? = nil
    var state: TrackState? = nil

    let player = AVAudioPlayerNode()

    // Bound fields that are accessible by combined ranges
    private let minVolume: Float
    private let maxVolume: Float
    var volume: ClosedRange<Float> { return minVolume...maxVolume }

    private let minDuration: Float
    private let maxDuration: Float
    var duration: ClosedRange<Float> { return minDuration...maxDuration }

    private let minDeadAir: Float
    private let maxDeadAir: Float
    var deadAir: ClosedRange<Float> { return minDeadAir...maxDeadAir }

    private let minFadeInTime: Float
    private let maxFadeInTime: Float
    var fadeInTime: ClosedRange<Float> { return minFadeInTime...maxFadeInTime }

    private let minFadeOutTime: Float
    private let maxFadeOutTime: Float
    var fadeOutTime: ClosedRange<Float> { return minFadeOutTime...maxFadeOutTime }

    enum CodingKeys: String, KeyedKey {
        case id
        case minVolume = "minvolume"
        case maxVolume = "maxvolume"
        case minDuration = "minduration"
        case maxDuration = "maxduration"
        case minDeadAir = "mindeadair"
        case maxDeadAir = "maxdeadair"
        case minFadeInTime = "minfadeintime"
        case maxFadeInTime = "maxfadeintime"
        case minFadeOutTime = "minfadeouttime"
        case maxFadeOutTime = "maxfadeouttime"
        case repeatRecordings = "repeatrecordings"
        case tags = "tag_filters"
        case bannedDuration = "banned_duration"
        case startWithSilence = "start_with_silence"
        case fadeOutWhenFiltered = "fadeout_when_filtered"
    }
}

extension AudioTrack {
    /// Amount of seconds to fade out when skipping an asset
    private static let skipFadeOutTime: Double = 1.0

    fileprivate func setDynamicPan(at assetLoc: CLLocation, _ params: StreamParams) {
        player.position = assetLoc.toAudioPoint(relativeTo: params.location)
    }
    
    func updateParams(_ params: StreamParams) {
        // Pan the audio based on user location relative to the current asset
        if let assetLoc = self.currentAsset?.location {
            self.setDynamicPan(at: assetLoc, params)
        }
        // Change in parameters may make more assets available
        if self.state is WaitingForAsset {
            self.fadeInNextAsset()
        }
        self.state?.onUpdate()
    }
    
    /// Plays the next optimal asset nearby.
    /// - Parameter premature: whether to fade out the current asset or just start the next one.
    func playNext() {
        if state?.canSkip == true {
            if let asset = currentAsset {
                transition(to: FadingOut(
                    track: self,
                    asset: asset,
                    duration: AudioTrack.skipFadeOutTime,
                    followedBy: nil
                ))
            } else {
                fadeInNextAsset()
            }
        }
    }

    func replay() {
        if let curr = currentAsset {
            transition(to: FadingOut(
                track: self,
                asset: curr,
                duration: Double(fadeOutTime.random()),
                followedBy: LoadingState(track: self, asset: curr)
            ))
        } else if let prev = self.previousAsset {
            transition(to: LoadingState(track: self, asset: prev))
        }
    }
    
    func pause() {
        state?.pause()
    }
    
    func resume() {
        // The first time we hit play, consider whether the track
        // is configured to start with silence or an asset.
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
    
    /// - Returns: if an asset has been chosen and started
    func fadeInNextAsset() {
        transition(to: LoadingState(track: self))
    }
}


/**
 Common sequence of states:
 Silence => FadingIn => PlayingAsset => FadingOut => Silence
 */
protocol TrackState {
    var canSkip: Bool { get }
    func start()
    func finish()
    func pause()
    func resume()
    /// Called when the track experiences a parameter update (eg. changed location)
    func onUpdate()
}

/**
 Dummy state to represent the track while it loads up the next asset.
 */
private class LoadingState: TrackState {
    var canSkip: Bool { return false }

    private let track: AudioTrack
    private let asset: Asset?

    init(track: AudioTrack, asset: Asset? = nil) {
        self.track = track
        self.asset = asset
    }

    func start() {
        if let next = self.asset ?? track.playlist?.next(forTrack: track) {
            track.previousAsset = track.currentAsset
            track.currentAsset = next

            let activeRegionLength = Double(next.activeRegion.upperBound - next.activeRegion.lowerBound)
            let minDuration = min(Double(track.duration.lowerBound), activeRegionLength)
            let maxDuration = min(Double(track.duration.upperBound), activeRegionLength)
            let duration = (minDuration...maxDuration).random()
            let latestStart = Double(next.activeRegion.upperBound) - duration
            let start = (Double(next.activeRegion.lowerBound)...latestStart).random()

            track.player.stop()

            // load the asset file
            do {
                try loadNextAsset(start: start, for: duration)
            } catch {
                print(error)
                track.fadeInNextAsset()
                return
            }

            track.transition(to: FadingIn(
                track: track,
                asset: next,
                assetDuration: duration
            ))
        } else if !(track.state is WaitingForAsset) {
            track.currentAsset = nil
            track.transition(to: WaitingForAsset(track: track))
        }
    }
    func finish () {}
    func pause() {}
    func resume() {}
    func onUpdate() {}

    /// Downloads and starts playing the currently selected asset
    private func loadNextAsset(start: Double? = nil, for duration: Double? = nil) throws {
        // Download asset into memory
        print("downloading asset")
        let remoteUrl = URL(string: track.currentAsset!.file)!
            .deletingPathExtension()
            .appendingPathExtension("mp3")

        let data = try Data(contentsOf: remoteUrl)
        print("asset downloaded as \(remoteUrl.lastPathComponent)")
        // have to write to file...
        // Write it to the cache folder so we can easily clean up later.
        let documentsDir = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        // Remove file of last played asset
        if let prev = track.previousAsset {
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
            track.player.scheduleSegment(file, startingFrame: startFrame, frameCount: frameCount, at: nil)
        } else {
            track.player.scheduleFile(file, at: nil)
        }

        if let params = track.playlist?.currentParams, let loc = track.currentAsset?.location {
            track.setDynamicPan(at: loc, params)
        }
    }
}

private class TimedTrackState: TrackState {
    private(set) var timer: Repeater? = nil
    private var lastDuration: Double
    private var lastResume = Date()

    var canSkip: Bool { return true }

    var timeLeft: Double {
        if let timer = self.timer, timer.state.isRunning {
            // playing
            return lastDuration - Date().timeIntervalSince(lastResume)
        } else {
            // paused
            return lastDuration
        }
    }
    
    init(duration: Double) {
        self.lastDuration = duration
    }
    
    func start() {
        timer = setupTimer()
        resume()
    }

    func finish() {
        timer?.removeAllObservers(thenStop: true)
    }

    func goToNextState() {
    }

    func pause() {
        timer?.pause()
        lastDuration -= Date().timeIntervalSince(lastResume)
    }

    func setupTimer() -> Repeater {
        return .once(after: .seconds(timeLeft)) { _ in
            self.goToNextState()
        }
    }

    func resume() {
        lastResume = Date()
        timer?.start()
    }

    func onUpdate() {
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

private class ResumableDeadAir: TimedTrackState {
    private let track: AudioTrack
    /// Last played track that can be resumed if eligible.
    private let asset: Asset
    private let remainingDurationOfAsset: Double

    init(track: AudioTrack, asset: Asset, remainingAssetTime: Double) {
        self.track = track
        self.asset = asset
        self.remainingDurationOfAsset = remainingAssetTime
        super.init(duration: Double(track.deadAir.upperBound))
    }

    override func start() {
        super.start()
        print("in resumable silence for \(self.timeLeft)")
    }

    override func goToNextState() {
        self.track.fadeInNextAsset()
    }

    override func onUpdate() {
        if track.playlist?.passesFilters(asset, forTrack: track) == true {
            print("resuming previous asset")
            track.transition(to: FadingIn(
                track: track,
                asset: asset,
                assetDuration: remainingDurationOfAsset
            ))
        }
    }
}

/// Fading into the playing asset
private class FadingIn: TimedTrackState {
    private static let updateInterval = 0.02
    
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
    
    override func setupTimer() -> Repeater {
        let toAdd = Float(FadingIn.updateInterval / self.timeLeft)
        return .every(.seconds(FadingIn.updateInterval)) { _ in
            if self.track.player.volume < self.targetVolume {
                self.track.player.volume += toAdd
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
        let fullVolumeDuration = duration - fadeOutDuration + 1.5
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
        // Tell the playlist we've finished the asset
        track.playlist?.recordFinishedPlaying(asset: asset)
        // and fade into the next one
        track.transition(to: FadingOut(
            track: track,
            asset: asset,
            duration: fadeOutDuration,
            followedBy: DeadAir(track: track)
        ))
    }

    override func onUpdate() {
        if track.fadeOutWhenFiltered && track.playlist?.passesFilters(asset, forTrack: track) == false {
            track.transition(to: FadingOut(
                track: track,
                asset: asset,
                duration: fadeOutDuration,
                followedBy: ResumableDeadAir(
                    track: track,
                    asset: asset,
                    remainingAssetTime: timeLeft
                )
            ))
        }
    }
}

/// Fading out of the playing asset
private class FadingOut: TimedTrackState {
    private static let updateInterval = 0.02
    
    private let track: AudioTrack
    private let asset: Asset
    private let followedBy: TrackState?

    override var canSkip: Bool { return false }
    
    init(
        track: AudioTrack,
        asset: Asset,
        duration: Double,
        followedBy: TrackState? = nil
    ) {
        self.track = track
        self.asset = asset
        self.followedBy = followedBy
        super.init(duration: duration)
    }
    
    override func setupTimer() -> Repeater {
        let toAdd = Float(FadingOut.updateInterval / self.timeLeft)
        return .every(.seconds(FadingOut.updateInterval)) { _ in
            if self.track.player.volume > 0 {
                self.track.player.volume -= toAdd
            } else {
                self.track.player.volume = 0
                self.track.player.pause()
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
        if let nextState = self.followedBy {
            track.transition(to: nextState)
        } else {
            self.track.fadeInNextAsset()
        }
    }
}

/// Waiting for relevant assets to be available
private class WaitingForAsset: TimedTrackState {
    private static let updateInterval = 10.0 // seconds
    
    private let track: AudioTrack

    override var canSkip: Bool { return false }
    
    init(track: AudioTrack) {
        self.track = track
        super.init(duration: 0)
    }
    
    override func setupTimer() -> Repeater {
        return .every(.seconds(WaitingForAsset.updateInterval)) { _ in
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
