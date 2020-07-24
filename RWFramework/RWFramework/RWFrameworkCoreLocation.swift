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
            if geo_listen_enabled {
                locationManager.startUpdatingLocation()
                if let loc = locationManager.location {
                    lastRecordedLocation = loc
                }
                updateStreamParams()
            }
            
            // Only automatically pan by device heading if enabled in project config
            let pan_by_heading = RWFrameworkConfig.getConfigValueAsBool("pan_by_heading")
            if pan_by_heading {
                locationManager.startUpdatingHeading()
            }
        }

        rwLocationManager(manager, didChangeAuthorizationStatus: status)
    }
    
    /// Update parameters to future stream requests
    public func updateStreamParams(
        location: CLLocation? = nil,
        range: ClosedRange<Double>? = nil,
        headingAngle: Double? = nil,
        angularWidth: Double? = nil
    ) {
        if let loc = location {
            lastRecordedLocation = loc
        }
        streamOptions = StreamParams(
            location: location ?? streamOptions.location,
            minDist: range?.lowerBound ?? streamOptions.minDist,
            maxDist: range?.upperBound ?? streamOptions.maxDist,
            heading: headingAngle ?? streamOptions.heading,
            angularWidth: angularWidth ?? streamOptions.angularWidth
        )
        playlist.updateParams(streamOptions)
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
            // Send parameter update with the newly recorded location
            updateStreamParams()
        }

        rwLocationManager(manager, didUpdateLocations: locations)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        var headingAngle = newHeading.trueHeading
        
        // Use 'course' if the device is pitched up or down far enough.
        if let attitude = motionManager.deviceMotion?.attitude {
            let limit = 70.0.degreesToRadians
            if attitude.pitch > limit || attitude.pitch < -limit {
                headingAngle = lastRecordedLocation.course
            }
        }
        
        // Update the playlist with this new device heading
        updateStreamParams(headingAngle: headingAngle)
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
//                locationManager.requestWhenInUseAuthorization()
                locationManager.requestAlwaysAuthorization() // need Always auth for location to update in background
            }
        }
        return shouldMakeTheRequest
    }

    /// Globally captures the most recent location
    func captureLastRecordedLocation() {
        lastRecordedLocation = locationManager.location!
    }
}
