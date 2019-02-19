//
//  RWFrameworkCoreLocation.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/5/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation
import CoreLocation

extension RWFramework: CLLocationManagerDelegate {

    /// This is called at app startup and also after permission has changed
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedAlways || status == CLAuthorizationStatus.authorizedWhenInUse {
            let geo_listen_enabled = RWFrameworkConfig.getConfigValueAsBool("geo_listen_enabled")
            if (geo_listen_enabled) {
                locationManager.startUpdatingLocation()
                updateStreamParams(range: nil, headingAngle: nil, angularWidth: nil)
            }
        }

        rwLocationManager(manager, didChangeAuthorizationStatus: status)
    }
    
    /// Update parameters to future stream requests
    public func updateStreamParams(
        range: ClosedRange<Double>?,
        headingAngle: Double?,
        angularWidth: Double?
    ) {
        if let r = range { 
            streamOptions["listener_range_min"] = r.lowerBound
            streamOptions["listener_range_max"] = r.upperBound
        }
        if let a = headingAngle { streamOptions["listener_heading"] = a }
        if let w = angularWidth { streamOptions["listener_width"] = w }
        
        playlist.updateParams(StreamParams(
            location: locationManager.location ?? lastRecordedLocation,
            minDist: streamOptions["listener_range_min"] as? Double,
            maxDist: streamOptions["listener_range_max"] as? Double,
            heading: streamOptions["listener_heading"] as? Double,
            angularWidth: streamOptions["listener_width"] as? Double
        ))
    }

    /// Called by the CLLocationManager when location has been updated
    public func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        captureLastRecordedLocation()

        let listen_enabled = RWFrameworkConfig.getConfigValueAsBool("listen_enabled")
        let geo_listen_enabled = RWFrameworkConfig.getConfigValueAsBool("geo_listen_enabled")
        if (listen_enabled && geo_listen_enabled) {
//             if (!requestStreamInProgress && !requestStreamSucceeded) {
// //                playlist.start()
//                 requestStreamSucceeded = true
//             } else {
                // if using range/directional listening, current param values should be inserted here
                // such that automatic location updates do not turn off range/directional listening by omitting required params
                playlist.updateParams(StreamParams(
                    location: locations[0],
                    minDist: streamOptions["listener_range_min"] as? Double,
                    maxDist: streamOptions["listener_range_max"] as? Double,
                    heading: streamOptions["listener_heading"] as? Double,
                    angularWidth: streamOptions["listener_width"] as? Double
                ))
            // }
        }

        // TODO: Set theme

        rwLocationManager(manager, didUpdateLocations: locations)
    }

    /// Called by the CLLocationManager when location update has failed
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        println("locationManager didFailWithError \(error)")
    }

    /// If you pass false for letFrameworkRequestWhenInUseAuthorizationForLocation in the framework's start() method then you can call method this anytime after rwGetProjectsIdSuccess is called in order to request in use location authorization from the user. This method returns true if the request will be made, false otherwise.
    public func requestWhenInUseAuthorizationForLocation() -> Bool {
        let geo_image_enabled = RWFrameworkConfig.getConfigValueAsBool("geo_image_enabled")
        let geo_listen_enabled = RWFrameworkConfig.getConfigValueAsBool("geo_listen_enabled")
        let geo_speak_enabled = RWFrameworkConfig.getConfigValueAsBool("geo_speak_enabled")
        let shouldMakeTheRequest = geo_listen_enabled || geo_speak_enabled || geo_image_enabled
        if (shouldMakeTheRequest) {
            locationManager.distanceFilter = RWFrameworkConfig.getConfigValueAsNumber("distance_filter_in_meters").doubleValue
            if CLLocationManager.authorizationStatus() == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
        }
        return shouldMakeTheRequest
    }

    /// Globally captures the most recent location
    func captureLastRecordedLocation() {
        lastRecordedLocation = locationManager.location!
    }
}
