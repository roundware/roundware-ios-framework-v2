
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
    let attenuationDistance: Int

    private let minVolume: Float
    private let maxVolume: Float
    var volume: ClosedRange<Float> { return minVolume...maxVolume }

    private let boundaryData: ShapeCollectionData
    lazy var shape: Geometry = {
        return GeometryCollection(geometries: boundaryData.coordinates.map { line in
            Polygon(shell: LinearRing(points: line.map { p in
                Coordinate(x: p[0], y: p[1])
            })!, holes: nil)!
        })!
    }()
    
    private let attenShapeData: ShapeData
    lazy var attenuationShape: Geometry = {
        return Polygon(shell: LinearRing(points: attenShapeData.coordinates.map { it in
            Coordinate(x: it[0], y: it[1])
        })!, holes: nil)!
    }()
    
    private var player: AVPlayer? = nil
    private var looper: Any? = nil
    private var fadeTimer: Repeater? = nil


    enum CodingKeys: String, CodingKey {
        case id
        case url = "uri"
        case backupUrl = "backupuri"
        case minVolume = "minvolume"
        case maxVolume = "maxvolume"
        case attenuationDistance = "attenuation_distance"
        case boundaryData = "boundary"
        case attenShapeData = "attenuation_border"
    }
}

extension Speaker {
    private func contains(_ point: CLLocation) -> Bool {
        return point.toWaypoint().within(shape)
    }
    
    private func attenuationShapeContains(_ point: CLLocation) -> Bool {
        return point.toWaypoint().within(attenuationShape)
    }
    
    public func distance(to loc: CLLocation) -> Double {
        return self.shape.distance(geometry: loc.toWaypoint())
    }
    
    private func attenuationRatio(at loc: CLLocation) -> Double {
        let nearestPoint = attenuationShape.nearestPoint(loc.toWaypoint())
        let nearestLocation = CLLocation(latitude: nearestPoint.y, longitude: nearestPoint.x)
        let distToInnerShape = nearestLocation.distance(from: loc)
        print("distance to speaker \(id): \(distToInnerShape) m")
        return 1 - (distToInnerShape / Double(attenuationDistance))
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
    func updateVolume(at point: CLLocation) -> Float {
        let vol = self.volume(at: point)
        
        if vol > 0.05 {
            // definitely want to create the player if it needs volume
            if self.player == nil {
                player = AVPlayer(url: URL(string: url)!)

                looper = looper ?? NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player!.currentItem, queue: .main) { [weak self] _ in
                    self?.player?.seek(to: CMTime.zero)
                    self?.player?.play()
                }
            }
            // make sure this speaker is playing if it needs to be audible
            if player!.rate == 0.0 && RWFramework.sharedInstance.isPlaying {
                player!.play()
            }
        }
        
        fadeTimer?.removeAllObservers(thenStop: true)
        if let player = self.player {
            let totalDiff = vol - player.volume
            let delta: Float = 0.075
            fadeTimer = .every(.seconds(Double(delta))) { timer in
                let currDiff = vol - player.volume
                if currDiff.sign != totalDiff.sign || abs(currDiff) < 0.05 {
                    // we went just enough or too far
                    player.volume = vol
                    
                    if vol < 0.05 {
                        // we can't hear it anymore, so pause it.
                        player.pause()
                    }
                    timer.removeAllObservers(thenStop: true)
                } else {
                    player.volume += totalDiff * delta / Speaker.fadeDuration
                }
            }
        }
        
        return vol
    }
    
    func resume() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
}
