
import Foundation
import CoreLocation
import GEOSwift
import AVFoundation
import Repeat

/**
 A polygonal geographic zone within which an ambient audio stream broadcasts continuously to listeners. Speakers can overlap, causing their audio to be mixed together accordingly.
 Volume attenuation happens linearly over a specified distance from the edge of the Speaker’s defined zone.
 */
public class Speaker: Codable {
    private static let fadeDuration: Float = 3.0
    private static let fadeDeltaTime: Float = 0.05
    private static let syncOverSeconds: Double = 2.0
    private static let acceptableSyncError: Double = 0.1
    
    let id: Int
    let url: String
    let backupUrl: String
    let attenuationDistance: Double

    private let minVolume: Float
    private let maxVolume: Float
    var volume: ClosedRange<Float> { return minVolume...maxVolume }

    let shape: Geometry
    let attenuationBorder: Geometry
    
    private var lazyPlayer: AVPlayer? = nil
    private var hasPlayer: Bool {
        return lazyPlayer != nil
    }
    private var player: AVPlayer {
        if lazyPlayer == nil {
            lazyPlayer = AVPlayer(url: URL(string: url)!)
        }
        return lazyPlayer!
    }
    private lazy var attenuationShape: Geometry = {
        if case let .lineString(x) = attenuationBorder {
            return .polygon(Polygon(exterior: try! Polygon.LinearRing(points: x.points)))
        } else {
            // We don't know how to handle other shapes.
            return try! attenuationBorder.convexHull()
        }
    }()
    private var looper: Any? = nil
    private var fadeTimer: Repeater? = nil
    private lazy var syncTimer: Repeater = {
        return .every(.seconds(Speaker.syncOverSeconds)) { timer in
            // Don't mess with a paused speaker.
            if !self.hasPlayer || self.player.timeControlStatus == .paused {
                return
            }
            
            let sessionTime = RWFramework.sharedInstance.playlist.totalPlayedTime
            let isWayOff = self.isPlayerTimeWayOff(sessionTime: sessionTime)
            if isWayOff || self.isPlayerTimeAround(sessionTime: sessionTime) {
                // Reset the play rate to normal.
                if self.player.rate != 1.0 {
                    self.player.rate = 1.0
                }
                if isWayOff {
                    self.syncTime(sessionTime)
                }
            } else {
                // Slightly speed up or slow down the player to bring it into sync.
                let syncOffset = sessionTime - self.player.currentTime().seconds
                self.player.rate = Float(1.0 + (syncOffset / Speaker.syncOverSeconds))
            }
        }
    }()
    private var ignoringUpdates: Bool = false
    private var volumeTarget: Float = 0.0


    enum CodingKeys: String, CodingKey {
        case id
        case shape
        case url = "uri"
        case backupUrl = "backupuri"
        case minVolume = "minvolume"
        case maxVolume = "maxvolume"
        case attenuationDistance = "attenuation_distance"
        case attenuationBorder = "attenuation_border"
    }
}

extension Speaker {
    private static var shouldSync: Bool {
        return RWFrameworkConfig.getConfigValueAsBool("sync_speakers")
    }
    
    private func isPlayerTimeAround(sessionTime timeSinceStart: TimeInterval) -> Bool {
        let acceptableRange = (timeSinceStart - Speaker.acceptableSyncError)...(timeSinceStart + Speaker.acceptableSyncError)
        return acceptableRange.contains(player.currentTime().seconds)
    }
    
    private func isPlayerTimeWayOff(sessionTime timeSinceStart: TimeInterval) -> Bool {
        return abs(timeSinceStart - player.currentTime().seconds) > Speaker.syncOverSeconds / 2
    }
    
    func contains(_ point: CLLocation) -> Bool {
        return try! point.toWaypoint().isWithin(shape)
    }
    
    private func attenuationShapeContains(_ point: CLLocation) -> Bool {
        return try! point.toWaypoint().isWithin(attenuationShape)
    }
    
    public func distance(to loc: CLLocation) -> Double {
        let pt = loc.toWaypoint()
        if try! pt.isWithin(shape) {
            return 0.0
        } else {
            return shape.distanceInMeters(to: loc)
        }
    }
    
    private func attenuationRatio(at loc: CLLocation) -> Double {
        let distToInnerShape = attenuationBorder.distanceInMeters(to: loc)
        return 1 - (distToInnerShape / attenuationDistance)
    }
    
    func volume(at point: CLLocation) -> Float {
        if attenuationShapeContains(point) {
            // The "attenuation shape" is the inner area where volume should be maxed out.
            return volume.upperBound
        } else if contains(point) {
            // The "shape" is the outer area where the speaker should play at variable loudness.
            let range = volume.difference
            return volume.lowerBound + range * Float(attenuationRatio(at: point))
        } else {
            // Outside the "shape" is where the speaker should be at minimum volume.
            return volume.lowerBound
        }
    }
    
    /**
     - returns: whether we're within range of the speaker
    */
    @discardableResult
    func updateVolume(at point: CLLocation, timeSinceStart: TimeInterval) -> Float {
        let vol = self.volume(at: point)
        return self.updateVolume(vol, timeSinceStart: timeSinceStart)
    }
    
    private func setupSyncTimer() {
        if Speaker.shouldSync {
            syncTimer.start()
        }
    }
    
    private func pauseSyncTimer() {
        if !Speaker.shouldSync {
            return
        }
        
        syncTimer.pause()
        if hasPlayer && !player.rate.isZero && player.rate != 1.0 {
            player.rate = 1.0
        }
    }

    private func syncTime(_ timeSinceStart: TimeInterval) {
        if Speaker.shouldSync {
            let t = abs(timeSinceStart)
            let timescale = self.player.currentItem?.asset.duration.timescale ?? 100000
            if t > 0.01 {
                self.player.seek(to: CMTime(seconds: t, preferredTimescale: timescale))
            }
        }
    }
    
    @discardableResult
    func updateVolume(_ vol: Float, timeSinceStart: TimeInterval) -> Float {
        if self.ignoringUpdates {
            return self.volumeTarget
        }
        
        if vol > 0.001 {
            // Only loop non-synced speakers
            if Speaker.shouldSync {
                player.actionAtItemEnd = .none
            } else {
                looper = looper ?? NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { [weak self] _ in
                    self?.player.seek(to: CMTime.zero)
                    self?.player.play()
                }
            }
            
            // make sure this speaker is playing if it needs to be audible
            if player.rate.isZero && RWFramework.sharedInstance.isPlaying {
                self.resume(timeSinceStart)
            }
        }
        
        if abs(vol - self.volumeTarget) > 0.02 {
            self.volumeTarget = vol
            if fadeTimer?.state != .running {
                let totalDiff = self.volumeTarget - player.volume
                fadeTimer?.removeAllObservers(thenStop: true)
                fadeTimer = .every(.seconds(Double(Speaker.fadeDeltaTime))) { timer in
                    if self.player.volume > 0.001 && self.player.rate.isZero && RWFramework.sharedInstance.isPlaying {
                        self.resume(RWFramework.sharedInstance.playlist.totalPlayedTime)
                    }
                    
                    let currDiff = self.volumeTarget - self.player.volume
                    if currDiff.sign != totalDiff.sign || abs(currDiff) < 0.05 {
                        // we went just enough or too far
                        self.player.volume = self.volumeTarget
                        
                        if self.player.volume < 0.001 {
                            // we can't hear it anymore, so pause it.
                            self.player.pause()
                        }
                        timer.removeAllObservers(thenStop: true)
                    } else {
                        self.player.volume += totalDiff * Speaker.fadeDeltaTime / Speaker.fadeDuration
                    }
                }
            }
        }
        
        return vol
    }
    
    func resume(_ timeSinceStart: TimeInterval? = nil) {
        // Resuming a speaker implies coming back from a fully stopped state.
        // This allows us to easily reset the session.
        ignoringUpdates = false
        setupSyncTimer()
        if volumeTarget > 0.0 && player.rate.isZero {
            if let t = timeSinceStart {
                syncTime(t)
            }
            player.play()
            RWFramework.sharedInstance.playlist.triggerSessionStart()
        }
    }
    
    func pause() {
        if volumeTarget > 0.0 && hasPlayer {
            player.pause()
        }
        pauseSyncTimer()
    }
    
    public func fadeOutAndStop(for fadeDuration: Float) {
        self.ignoringUpdates = true
        if volumeTarget > 0.0 {
            volumeTarget = 0.0
            let totalDiff = -player.volume
            fadeTimer?.removeAllObservers(thenStop: true)
            fadeTimer = .every(.seconds(Double(Speaker.fadeDeltaTime))) { timer in
                if self.player.volume < 0.01 {
                    // we went just enough or too far
                    self.player.volume = 0.0
                    // we can't hear it anymore, so pause it.
                    self.player.pause()
                    self.pauseSyncTimer()
                    timer.removeAllObservers(thenStop: true)
                    print("speaker concluded")
                } else {
                    self.player.volume += totalDiff * Speaker.fadeDeltaTime / fadeDuration
                }
            }
        }
    }
}
