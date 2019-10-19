import CoreLocation
import GEOSwift
import AVFoundation

extension Geometry {
    func distanceInMeters(to loc: CLLocation) -> Double {
        let nearestPoint = try! self.nearestPoints(with: loc.toWaypoint())[0]
        let nearestLocation = CLLocation(latitude: nearestPoint.y, longitude: nearestPoint.x)
        return try! nearestLocation.distance(from: loc)
    }
}

extension CLLocation {
    func toWaypoint() -> Point {
        return Point(x: coordinate.longitude, y: coordinate.latitude)
    }

    func bearingToLocationRadian(_ destinationLocation: CLLocation) -> Double {
        let lat1 = self.coordinate.latitude.degreesToRadians
        let lon1 = self.coordinate.longitude.degreesToRadians
        
        let lat2 = destinationLocation.coordinate.latitude.degreesToRadians
        let lon2 = destinationLocation.coordinate.longitude.degreesToRadians
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return radiansBearing
    }
    
    func bearingToLocationDegrees(_ destinationLocation: CLLocation) -> Double {
        return bearingToLocationRadian(destinationLocation).radiansToDegrees
    }

    func toAudioPoint() -> AVAudio3DPoint {
        let coord = self.coordinate
        let mult = 1.0
        return AVAudio3DPoint(
            x: Float(coord.longitude * mult),
            y: 0.0,
            z: -Float(coord.latitude * mult)
        )
    }
    
    func toAudioPoint(relativeTo other: CLLocation) -> AVAudio3DPoint {
        let latCoord = CLLocation(latitude: self.coordinate.latitude, longitude: other.coordinate.longitude)
        let lngCoord = CLLocation(latitude: other.coordinate.latitude, longitude: self.coordinate.longitude)
        let latDist = latCoord.distance(from: other)
        let lngDist = lngCoord.distance(from: other)
        let latDir = (self.coordinate.latitude - other.coordinate.latitude).sign
        let latMult = latDir == .plus ? -1.0 : 1.0
        let lngDir = (self.coordinate.longitude - other.coordinate.longitude).sign
        let lngMult = lngDir == .plus ? 1.0 : -1.0
        let mult = 0.1
        return AVAudio3DPoint(
            x: Float(lngDist * lngMult * mult),
            y: 0.0,
            z: Float(latDist * latMult * mult)
        )
    }
}

extension Double {
    var degreesToRadians: Double { return self * .pi / 180 }
    var radiansToDegrees: Double { return self * 180 / .pi }
}

// Extensions on decimal ranges
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
