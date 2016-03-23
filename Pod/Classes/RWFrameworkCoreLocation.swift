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

    /// This is called at framework startup and also after permission has changed
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedAlways || status == CLAuthorizationStatus.authorizedWhenInUse {
            let geo_listen_enabled = RWFrameworkConfig.getConfigValueAsBool(key: "geo_listen_enabled")
            if (geo_listen_enabled) {
                locationManager.startUpdatingLocation()
            }
        }

        rwLocationManager(manager: manager, didChangeAuthorizationStatus: status)
    }

    /// Called by the CLLocationManager when location has been updated
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // println("locationManager didUpdateLocations \(locations)")
        //TODO throttle?

        captureLastRecordedLocation()

        let listen_enabled = RWFrameworkConfig.getConfigValueAsBool(key: "listen_enabled")
        if (listen_enabled) {
            let geo_listen_enabled = RWFrameworkConfig.getConfigValueAsBool(key: "geo_listen_enabled")
            if (geo_listen_enabled && requestStreamInProgress == false && requestStreamSucceeded == false) {
                #if DEBUG
                    let fakeLocation: CLLocation = CLLocation(latitude: 1.0, longitude: 1.0)
                    apiPatchStreamsIdWithLocation(fakeLocation)
                #else
                    apiPatchStreamsIdWithLocation(newLocation: locations[0])
                #endif
            } else {
                apiPostStreams()
            }
        }

        rwLocationManager(manager: manager, didUpdateLocations: locations)
    }

    /// Called by the CLLocationManager when location update has failed
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        println(object: "locationManager didFailWithError \(error)")
    }

    /// If you pass false for letFrameworkRequestWhenInUseAuthorizationForLocation in the framework's start() method then you can call method this anytime after rwGetProjectsIdSuccess is called in order to request in use location authorization from the user. This method returns true if the request will be made, false otherwise.
    public func requestWhenInUseAuthorizationForLocation() -> Bool {
        let geo_image_enabled = RWFrameworkConfig.getConfigValueAsBool(key: "geo_image_enabled")
        let geo_listen_enabled = RWFrameworkConfig.getConfigValueAsBool(key: "geo_listen_enabled")
        let geo_speak_enabled = RWFrameworkConfig.getConfigValueAsBool(key: "geo_speak_enabled")
        let shouldMakeTheRequest = geo_listen_enabled || geo_speak_enabled || geo_image_enabled
        if (shouldMakeTheRequest) {
            locationManager.distanceFilter = RWFrameworkConfig.getConfigValueAsNumber(key: "distance_filter_in_meters").doubleValue
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
            
            if let thisLocation = locationManager.location {
                lastRecordedLocation = thisLocation
            } else {
                print("Last location unavailable")
            }
        #endif
    }
}
