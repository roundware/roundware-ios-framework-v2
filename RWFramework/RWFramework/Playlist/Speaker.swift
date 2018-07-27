//
//  Speaker.swift
//  RWFramework
//
//  Created by Taylor Snead on 7/20/18.
//  Copyright © 2018 Roundware. All rights reserved.
//

import Foundation
import CoreLocation


struct Speaker {
    let id: Int
    let volume: ClosedRange<Float>
    let url: String
    let backupUrl: String
    let shape: [CGPoint]
    let attenuationShape: [CGPoint]
    let attenuationDistance: Int
    
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
    
    func volume(at point: CLLocation) -> Float {
        if attenuationShapeContains(point) {
            return volume.upperBound
        } else if contains(point) {
            // TODO: Linearly attenuate instead of just averaging.
            return (volume.upperBound + volume.lowerBound) / 2
        } else {
            return volume.lowerBound
        }
    }
    
    static func fromJson(_ data: Data) throws -> [Speaker] {
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
