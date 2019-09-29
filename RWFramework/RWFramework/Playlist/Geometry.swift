import CoreLocation
import GEOSwift

struct ShapeData: Codable {
    let coordinates: [[Double]]
}

struct ShapeCollectionData: Codable {
    let coordinates: [[[Double]]]
}

extension CLLocation {
    func toWaypoint() -> Waypoint {
        return Waypoint(latitude: coordinate.latitude, longitude: coordinate.longitude)!
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
