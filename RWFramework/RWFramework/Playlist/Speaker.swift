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

public class Speaker {
    let id: Int
    let volume: ClosedRange<Float>
    let url: String
    let backupUrl: String
    let shape: [CGPoint]
    let attenuationShape: [CGPoint]
    let attenuationDistance: Int
    let player = STKAudioPlayer()
    let looper: LoopAudio

    init(
        id: Int,
        volume: ClosedRange<Float>,
        url: String,
        backupUrl: String,
        shape: [CGPoint],
        attenuationShape: [CGPoint],
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
    
    private func contains(_ point: CLLocation) -> Bool {
        let path = UIBezierPath.from(points: shape)
        let coord = point.coordinate
        return path.contains(CGPoint(x: coord.latitude, y: coord.longitude))
    }
    
    private func attenuationShapeContains(_ point: CLLocation) -> Bool {
        let path = UIBezierPath.from(points: attenuationShape)
        let coord = point.coordinate
        return path.contains(CGPoint(x: coord.latitude, y: coord.longitude))
    }
    
    private static func distance(shape: [CGPoint], _ loc: CLLocation) -> Double {
        // find distance to nearest point in the shape
        // TODO: Find distance to side, not vertex
        return shape.lazy.map { it in
            loc.distance(from: CLLocation(
                    latitude: CLLocationDegrees(it.x),
                    longitude: CLLocationDegrees(it.y)
            ))
        }.min()!
    }

    public func distance(to loc: CLLocation) -> Double {
        return Speaker.distance(shape: self.shape, loc)
    }
    
    private func attenuationRatio(at loc: CLLocation) -> Double {
        let dist = Speaker.distance(shape: shape, loc)
        let attenDist = Speaker.distance(shape: attenuationShape, loc)
        return dist / (dist + attenDist)
    }
    
    func volume(at point: CLLocation) -> Float {
        if attenuationShapeContains(point) {
            return volume.upperBound
        } else if contains(point) {
            // TODO: Linearly attenuate instead of just averaging.
            let range = volume.upperBound - volume.lowerBound
            return volume.lowerBound + range * Float(attenuationRatio(at: point))
        } else {
            return volume.lowerBound
        }
    }

    /**
     @return true if we're within range of the speaker
    */
    func updateVolume(at point: CLLocation) {
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
        
        let items = json.array!
        print(items.description)
//        return []
        return items.map { obj in
            let it = obj.dictionaryValue
            let boundary = it["boundary"]!["coordinates"][0].array!
            let attenBound = it["attenuation_border"]!["coordinates"].array!
            return Speaker(
                id: it["id"]!.int!,
                volume: it["minvolume"]!.number!.floatValue...it["maxvolume"]!.number!.floatValue,
                url: it["uri"]!.string!,
                backupUrl: it["backupuri"]!.string!,
                shape: boundary.map { it in
                    CGPoint(x: it[0].double!, y: it[1].double!)
                },
                attenuationShape: attenBound.map { it in
                    CGPoint(x: it[0].double!, y: it[1].double!)
                },
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
        return CGPoint(x: coordinate.latitude, y: coordinate.longitude)
    }
}