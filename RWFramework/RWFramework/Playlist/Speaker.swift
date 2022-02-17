
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
    
    let id: Int
    let url: String
    let backupUrl: String
    let attenuationDistance: Double

    private let minVolume: Float
    private let maxVolume: Float
    var volume: ClosedRange<Float> { return minVolume...maxVolume }

    let shape: Geometry
    let attenuationBorder: Geometry
    
    private lazy var player: AVPlayer = {
        return AVPlayer(url: URL(string: self.url)!)
    }()
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
        print("distance to speaker \(id): \(distToInnerShape) m")
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

    func syncTime(_ timeSinceStart: TimeInterval) {
        if Speaker.shouldSync && volumeTarget > 0.0 {
            let t = abs(timeSinceStart)
            let timescale = self.player.currentItem?.asset.duration.timescale ?? 1000
            self.player.seek(to: CMTime(seconds: t, preferredTimescale: timescale))
        }
    }
    
    @discardableResult
    func updateVolume(_ vol: Float, timeSinceStart: TimeInterval) -> Float {
        if self.ignoringUpdates {
            return self.player.volume
        }
        
        if vol > 0.05 {
            // Only loop non-synced speakers
            if Speaker.shouldSync {
                player.actionAtItemEnd = .none
            } else {
                looper = looper ?? NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { [weak self] _ in
                    self?.player.seek(to: CMTime.zero)
                    self?.player.play()
                }
            }
        }
        
        // make sure this speaker is playing if it needs to be audible
        if player.rate.isZero && RWFramework.sharedInstance.isPlaying {
            self.resume(timeSinceStart)
        }
        
        if abs(vol - self.volumeTarget) > 0.02 {
            self.volumeTarget = vol
            print("speaker \(self.id) target volume = \(vol)")
            if fadeTimer?.state != .running {
                let totalDiff = self.volumeTarget - player.volume
                fadeTimer?.removeAllObservers(thenStop: true)
                fadeTimer = .every(.seconds(Double(Speaker.fadeDeltaTime))) { timer in
                    let currDiff = self.volumeTarget - self.player.volume
                    if currDiff.sign != totalDiff.sign || abs(currDiff) < 0.05 {
                        // we went just enough or too far
                        self.player.volume = self.volumeTarget
                        
                        if self.player.volume < 0.05 {
                            // we can't hear it anymore, so pause it.
                            self.player.pause()
                        } else if self.player.rate.isZero {
                            self.resume(timeSinceStart)
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
    
    func resume(_ timeSinceStart: TimeInterval) {
        // Resuming a speaker implies coming back from a fully stopped state.
        // This allows us to easily reset the session.
        self.ignoringUpdates = false
        if volumeTarget > 0.0 && player.rate.isZero {
            print("speaker resuming at \(timeSinceStart)")
            syncTime(timeSinceStart)
            player.play()
        }
    }
    
    func pause() {
        if volumeTarget > 0.0 {
            player.pause()
        }
    }
    
    public func fadeOutAndStop(for fadeDuration: Float) {
        self.ignoringUpdates = true
        if volumeTarget > 0.0 {
            let totalDiff = -player.volume
            fadeTimer?.removeAllObservers(thenStop: true)
            fadeTimer = .every(.seconds(Double(Speaker.fadeDeltaTime))) { timer in
                if self.player.volume < 0.01 {
                    // we went just enough or too far
                    self.player.volume = 0.0
                    // we can't hear it anymore, so pause it.
                    self.player.pause()
                    timer.removeAllObservers(thenStop: true)
                } else {
                    self.player.volume += totalDiff * Speaker.fadeDeltaTime / fadeDuration
                }
            }
        }
    }
}
