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

public class Speaker {
    let id: Int
    let volume: ClosedRange<Float>
    let url: String
    let backupUrl: String
    let shape: [CGPoint]
    let attenuationShape: [CGPoint]
    let attenuationDistance: Int
    let player = STKAudioPlayer()

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
    }
    
    private func contains(_ point: CLLocation) -> Bool {
        let path = UIBezierPath()
        path.move(to: shape[0])
        for idx in 1...shape.count-1 {
            path.addLine(to: shape[idx])
        }
        path.close()
        let coord = point.coordinate
        return path.contains(CGPoint(x: coord.latitude, y: coord.longitude))
    }
    
    private func attenuationShapeContains(_ point: CLLocation) -> Bool {
        let path = UIBezierPath()
        path.move(to: attenuationShape[0])
        for idx in 1...attenuationShape.count-1 {
            path.addLine(to: attenuationShape[idx])
        }
        path.close()
        let coord = point.coordinate
        return path.contains(CGPoint(x: coord.latitude, y: coord.longitude))
    }
    
    private static func distance(shape: [CGPoint], _ loc: CLLocation) -> Double {
        // find distance to nearest point in the shape
        return shape.map { it in
            loc.distance(from:
                CLLocation(latitude: CLLocationDegrees(it.x), longitude: CLLocationDegrees(it.y))
            )
        }.min { a, b in a < b }!
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
    
    func updateVolume(at point: CLLocation) {
        let vol = self.volume(at: point)
        // TODO: Fading
        if vol <= 0.01 {
            if player.state == .playing {
                player.stop()
            }
        } else {
            player.volume = vol
            if player.state == .stopped {
                player.delegate = LoopAudio(url)
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
        let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale.init(identifier: "en_US_POSIX")
        
        let items = json as! [AnyObject]
        return items.map { obj in
            let it = obj as! [String: AnyObject]
            let boundary = ((it["boundary"] as! [String: AnyObject])["coordinates"] as! [AnyObject])[0] as! [[Double]]
            let attenBound = (it["attenuation_border"] as! [String: AnyObject])["coordinates"] as! [[Double]]
            return Speaker(
                id: it["id"] as! Int,
                volume: (it["minvolume"] as! Float)...(it["maxvolume"] as! Float),
                url: it["uri"] as! String,
                backupUrl: it["backupuri"] as! String,
                shape: boundary.map { it in CGPoint(x: it[0], y: it[1]) },
                attenuationShape: attenBound.map { it in CGPoint(x: it[0], y: it[1]) },
                attenuationDistance: it["attenuation_distance"] as! Int
            )
        }
    }
}
