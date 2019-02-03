//
//  Speaker.swift
//  RWFramework
//
//  Created by Taylor Snead on 7/20/18.
//  Copyright © 2018 Roundware. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftyJSON
import GEOSwift
import AVFoundation

public class Speaker {
    private static let fadeDuration: Float = 1.0
    
    let id: Int
    let volume: ClosedRange<Float>
    let url: String
    let backupUrl: String
    let shape: Geometry
    let attenuationShape: Geometry
    let attenuationDistance: Int
    private var player: AVPlayer? = nil
    private var looper: Any? = nil
    private var fadeTimer: Timer? = nil

    init(
        id: Int,
        volume: ClosedRange<Float>,
        url: String,
        backupUrl: String,
        shape: Geometry,
        attenuationShape: Geometry,
        attenuationDistance: Int
    ) {
        self.id = id
        self.volume = volume
        self.url = url
        self.backupUrl = backupUrl
        self.shape = shape
        self.attenuationShape = attenuationShape
        self.attenuationDistance = attenuationDistance
    }
}

extension Speaker {
    private func contains(_ point: CLLocation) -> Bool {
        return point.toWaypoint().within(shape)
    }
    
    private func attenuationShapeContains(_ point: CLLocation) -> Bool {
        return point.toWaypoint().within(attenuationShape)
    }
    
    private static func distance(shape: [CGPoint], _ loc: CLLocation) -> Double {
        // find distance to nearest point on the shape
        let geom = LinearRing(points: shape.map { Coordinate(x: Double($0.x), y: Double($0.y)) })!
        let pointGeom = Waypoint(
            latitude: loc.coordinate.latitude,
            longitude: loc.coordinate.longitude
        )!
        return geom.distance(geometry: pointGeom)
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
            // TODO: Linearly attenuate instead of just averaging.
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
        print("speaker volume = \(vol)")
        
        if vol > 0.05 {
            // definitely want to create the player if it needs volume
            if self.player == nil {
                player = AVPlayer(url: URL(string: url)!)
                player!.play()

                looper = looper ?? NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player!.currentItem, queue: .main) { [weak self] _ in
                    self?.player?.seek(to: CMTime.zero)
                    self?.player?.play()
                }
            }
        }
        
        fadeTimer?.invalidate()
        if let player = self.player {
            let totalDiff = vol - player.volume
            let delta: Float = 0.075
            fadeTimer = Timer.scheduledTimer(withTimeInterval: Double(delta), repeats: true) { timer in
                let currDiff = vol - player.volume
                if currDiff.sign != totalDiff.sign || abs(currDiff) < 0.05 {
                    // we went just enough or too far
                    player.volume = vol
                    
                    if vol < 0.05 {
                        // we can't hear it anymore, so pause it.
                        player.pause()
                    }
                    timer.invalidate()
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
    
    static func from(data: Data) throws -> [Speaker] {
        let json = try JSON(data: data)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale.init(identifier: "en_US_POSIX")

        return json.array!.map { obj in
            let it = obj.dictionaryValue
            let boundary = it["boundary"]!["coordinates"].array!
            let attenBound = it["attenuation_border"]!["coordinates"].array!
            let innerShape = Polygon(shell: LinearRing(points: attenBound.map { it in
                Coordinate(x: it[0].double!, y: it[1].double!)
            })!, holes: nil)!
            let outerShape = GeometryCollection(geometries: boundary.map { line in
                Polygon(shell: LinearRing(points: line.array!.map { p in
                    Coordinate(x: p[0].double!, y: p[1].double!)
                })!, holes: nil)!
            })!
            return Speaker(
                id: it["id"]!.int!,
                volume: it["minvolume"]!.float!...it["maxvolume"]!.float!,
                url: it["uri"]!.string!,
                backupUrl: it["backupuri"]!.string!,
                shape: outerShape,
                attenuationShape: innerShape,
                attenuationDistance: it["attenuation_distance"]!.int!
            )
        }
    }
}

extension CLLocation {
    func toWaypoint() -> Waypoint {
        return Waypoint(latitude: coordinate.latitude, longitude: coordinate.longitude)!
    }
}
