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
            }
        }

        rwLocationManager(manager, didChangeAuthorizationStatus: status)
    }

    /// Called by the CLLocationManager when location has been updated
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // println("locationManager didUpdateLocations \(locations)")

        captureLastRecordedLocation()

        let listen_enabled = RWFrameworkConfig.getConfigValueAsBool("listen_enabled")
        if (listen_enabled) {
            let geo_listen_enabled = RWFrameworkConfig.getConfigValueAsBool("geo_listen_enabled")
            if (geo_listen_enabled && requestStreamInProgress == false && requestStreamSucceeded == false) {
                apiPostStreams()
            } else {
                #if DEBUG
//                    let fakeLocation: CLLocation = CLLocation(latitude: 1.0, longitude: 1.0)
//                    apiPatchStreamsIdWithLocation(fakeLocation)
                    let streamPatchOptions = ["listener_range_min": 0, "listener_range_max": 10000000, "listener_heading": 270.0, "listener_width": 0.0]
                    apiPatchStreamsIdWithLocation(locations[0] as? CLLocation, streamPatchOptions: streamPatchOptions)
                #else
                    let streamPatchOptions = ["listener_range_min": 0, "listener_range_max": 10000000, "listener_heading": 270.0, "listener_width": 0.0]
                    apiPatchStreamsIdWithLocation(locations[0] as? CLLocation, streamPatchOptions: streamPatchOptions)
                #endif
            }
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
        #if DEBUG
            let fakeLocation: CLLocation = CLLocation(latitude: 1.0, longitude: 1.0)
            lastRecordedLocation = fakeLocation
        #else
            lastRecordedLocation = locationManager.location!
        #endif
    }
}
