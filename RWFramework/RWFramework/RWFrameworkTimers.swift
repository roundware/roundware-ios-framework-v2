//
//  RWFrameworkTimers.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/17/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation

extension RWFramework {

// MARK: - Heartbeat

    @objc func heartbeatTimer(_ timer: Timer) {
        if (requestStreamSucceeded == false) { return }

        let geo_listen_enabled = RWFrameworkConfig.getConfigValueAsBool("geo_listen_enabled")
        if (!geo_listen_enabled) ||
            (geo_listen_enabled && lastRecordedLocation.timestamp.timeIntervalSinceNow < -RWFrameworkConfig.getConfigValueAsNumber("gps_idle_interval_in_seconds").doubleValue) {
            apiPostStreamsIdHeartbeat()
        }
    }

    func startHeartbeatTimer() {
        DispatchQueue.main.async(execute: { () -> Void in
            let gps_idle_interval_in_seconds = RWFrameworkConfig.getConfigValueAsNumber("gps_idle_interval_in_seconds").doubleValue
            self.heartbeatTimer = Timer.scheduledTimer(timeInterval: gps_idle_interval_in_seconds, target:self, selector:#selector(RWFramework.heartbeatTimer(_:)), userInfo:nil, repeats:true)
        })
    }

// MARK: - Audio

    @objc func audioTimer(_ timer: Timer) {
        var percentage: Double = 0
        if !useComplexRecordingMechanism && isRecording() {
            let max_recording_length = RWFrameworkConfig.getConfigValueAsNumber("max_recording_length").doubleValue
            percentage = soundRecorder!.currentTime/max_recording_length
            soundRecorder!.updateMeters()
            rwRecordingProgress(percentage, maxDuration: max_recording_length, peakPower: soundRecorder!.peakPower(forChannel: 0), averagePower: soundRecorder!.averagePower(forChannel: 0))
        } else if useComplexRecordingMechanism && isRecording() {
            let max_recording_length = RWFrameworkConfig.getConfigValueAsNumber("max_recording_length").doubleValue
            let rwfar = RWFrameworkAudioRecorder.sharedInstance()
            percentage = (rwfar?.currentTime())!/max_recording_length

            // TODO: Meters (kAudioUnitProperty_MeteringMode on a mixer in the AUGraph)

            let peakPower: Float = 0.0
            let averagePower: Float = 0.0
            rwRecordingProgress(percentage, maxDuration: max_recording_length, peakPower: peakPower, averagePower: averagePower)

            if percentage >= 1.0 {
                stopRecording()
                rwAudioRecorderDidFinishRecording()
            }
        } else if isPlayingBack() {
            percentage = soundPlayer!.currentTime/soundPlayer!.duration
            soundPlayer!.updateMeters()
            rwPlayingBackProgress(percentage, duration: soundPlayer!.duration, peakPower: soundPlayer!.peakPower(forChannel: 0), averagePower: soundPlayer!.averagePower(forChannel: 0))
        }
    }

    func startAudioTimer() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.audioTimer = Timer.scheduledTimer(timeInterval: 0.1, target:self, selector:#selector(RWFramework.audioTimer(_:)), userInfo:nil, repeats:true)
        })
    }

// MARK: - Upload

    @objc func uploadTimer(_ timer: Timer) {
        mediaUploader()
    }

    func startUploadTimer() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.uploadTimer = Timer.scheduledTimer(timeInterval: 1.0, target:self, selector:#selector(RWFramework.uploadTimer(_:)), userInfo:nil, repeats:true)
        })
    }

}
