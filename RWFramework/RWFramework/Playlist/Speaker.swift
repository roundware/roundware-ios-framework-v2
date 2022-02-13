
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
    
    let id: Int
    let url: String
    let backupUrl: String
    let attenuationDistance: Double

    private let minVolume: Float
    private let maxVolume: Float
    var volume: ClosedRange<Float> { return minVolume...maxVolume }

    let shape: Geometry
    let attenuationBorder: Geometry
    
    private var player: AVPlayer? = nil
    private var looper: Any? = nil
    private var fadeTimer: Repeater? = nil
    private var ignoringUpdates: Bool = false


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
    
    func contains(_ point: CLLocation) -> Bool {
        return try! point.toWaypoint().isWithin(shape)
    }
    
    private func attenuationShapeContains(_ point: CLLocation) -> Bool {
        return try! point.toWaypoint().isWithin(attenuationBorder.convexHull())
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
        print("distance to speaker \(id): \(distToInnerShape) m")
        return 1 - (distToInnerShape / attenuationDistance)
    }
    
    func volume(at point: CLLocation) -> Float {
        if attenuationShapeContains(point) {
            return volume.upperBound
        } else if contains(point) {
            let range = volume.difference
            return volume.lowerBound + range * Float(attenuationRatio(at: point))
        } else {
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

    func syncTime(_ timeSinceStart: TimeInterval) {
        if Speaker.shouldSync {
            let t = abs(timeSinceStart)
            let timescale = self.player?.currentItem?.asset.duration.timescale ?? 1000
            self.player?.seek(to: CMTime(seconds: t, preferredTimescale: timescale))
        }
    }
    
    @discardableResult
    func updateVolume(_ vol: Float, timeSinceStart: TimeInterval) -> Float {
        if self.ignoringUpdates {
            return self.player?.volume ?? vol
        }
        
        if vol > 0.05 {
            // definitely want to create the player if it needs volume
            if self.player == nil {
                player = AVPlayer(url: URL(string: url)!)

                // Only loop non-synced speakers
                if Speaker.shouldSync {
                    player?.actionAtItemEnd = .none
                } else {
                    looper = looper ?? NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player!.currentItem, queue: .main) { [weak self] _ in
                        self?.player?.seek(to: CMTime.zero)
                        self?.player?.play()
                    }
                }
            }
            // make sure this speaker is playing if it needs to be audible
            if player!.rate.isZero && RWFramework.sharedInstance.isPlaying {
                self.resume(timeSinceStart)
            }
        }
        
        fadeTimer?.removeAllObservers(thenStop: true)
        if let player = self.player, abs(vol - player.volume) > 0.02 {
            let totalDiff = vol - player.volume
            let delta: Float = 0.05
            fadeTimer = .every(.seconds(Double(delta))) { timer in
                let currDiff = vol - player.volume
                if currDiff.sign != totalDiff.sign || abs(currDiff) < 0.05 {
                    // we went just enough or too far
                    player.volume = vol
                    
                    if vol < 0.05 {
                        // we can't hear it anymore, so pause it.
                        player.pause()
                    } else if player.rate.isZero {
                        self.resume(timeSinceStart)
                    }
                    timer.removeAllObservers(thenStop: true)
                } else {
                    player.volume += totalDiff * delta / Speaker.fadeDuration
                }
            }
        }
        
        return vol
    }
    
    func resume(_ timeSinceStart: TimeInterval) {
        print("speaker resuming at \(timeSinceStart)")
        // Resuming a speaker implies coming back from a fully stopped state.
        // This allows us to easily reset the session.
        self.ignoringUpdates = false
        syncTime(timeSinceStart)
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    public func fadeOutAndStop(for fadeDuration: Float) {
        self.ignoringUpdates = true
        if let player = self.player {
            let totalDiff = -player.volume
            let delta: Float = 0.05
            fadeTimer = .every(.seconds(Double(delta))) { timer in
                if player.volume < 0.01 {
                    // we went just enough or too far
                    player.volume = 0.0
                    // we can't hear it anymore, so pause it.
                    player.pause()
                    timer.removeAllObservers(thenStop: true)
                } else {
                    player.volume += totalDiff * delta / fadeDuration
                }
            }
        }
    }
}
