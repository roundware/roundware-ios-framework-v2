//
//  Speaker.swift
//  RWFramework
//
//  Created by Taylor Snead on 7/20/18.
//  Copyright © 2018 Roundware. All rights reserved.
//

import Foundation
import CoreLocation
import StreamingKit
import SwiftyJSON
import GEOSwift

public class Speaker {
    let id: Int
    let volume: ClosedRange<Float>
    let url: String
    let backupUrl: String
    let shape: Geometry
    let attenuationShape: Geometry
    let attenuationDistance: Int
    private let player = STKAudioPlayer()
    private let looper: LoopAudio

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
        self.looper = LoopAudio(url)
        player.stop()
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
//        let dist = self.distance(to: loc)
        let attenDist = loc.toWaypoint().distance(geometry: attenuationShape)
        return 1 - (attenDist / Double(attenuationDistance))
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
     @return true if we're within range of the speaker
    */
    func updateVolume(at point: CLLocation) -> Float {
        let vol = self.volume(at: point)
        print("speaker volume = \(vol)")
        // TODO: Fading
        if vol < 0.01 {
            if player.state != .stopped {
                player.delegate = nil
                player.stop()
            }
        } else {
            player.volume = vol
            if player.state == .stopped {
                player.delegate = looper
                player.play(url)
            }
        }
        return vol
    }
    
    func resume() {
        if player.state == .paused {
            player.resume()
        }
    }
    
    func pause() {
        if player.state == .playing {
            player.pause()
        }
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
            return Speaker(
                id: it["id"]!.int!,
                volume: it["minvolume"]!.float!...it["maxvolume"]!.float!,
                url: it["uri"]!.string!,
                backupUrl: it["backupuri"]!.string!,
                shape: GeometryCollection(geometries: boundary.map { line in
                    Polygon(shell: LinearRing(points: line.array!.map { p in
                        Coordinate(x: p[0].double!, y: p[1].double!)
                    })!, holes: nil)!
                })!,
                attenuationShape: Polygon(shell: LinearRing(points: attenBound.map { it in
                    Coordinate(x: it[0].double!, y: it[1].double!)
                })!, holes: nil)!,
                attenuationDistance: it["attenuation_distance"]!.int!
            )
        }
    }
}

extension UIBezierPath {
    static func from(points: [CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: points[0])
        for idx in 1..<points.count {
            path.addLine(to: points[idx])
        }
        path.close()
        return path
    }
}

extension CLLocation {
    func toCGPoint() -> CGPoint {
        return CGPoint(x: coordinate.longitude, y: coordinate.latitude)
    }
    func toWaypoint() -> Waypoint {
        return Waypoint(latitude: coordinate.latitude, longitude: coordinate.longitude)!
    }
    static func from(_ pt: CGPoint) -> CLLocation {
        return CLLocation(
            latitude: CLLocationDegrees(pt.y),
            longitude: CLLocationDegrees(pt.x)
        )
    }
}
