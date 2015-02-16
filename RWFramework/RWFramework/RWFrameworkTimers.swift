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

    func heartbeatTimer(timer: NSTimer) {
        if (requestStreamSucceeded == false) { return }

        var geo_listen_enabled = RWFrameworkConfig.getConfigValueAsBool("geo_listen_enabled")
        if (!geo_listen_enabled) ||
            (geo_listen_enabled && lastRecordedLocation.timestamp.timeIntervalSinceNow < -RWFrameworkConfig.getConfigValueAsNumber("gps_idle_interval_in_seconds").doubleValue) {
            apiPostStreamsIdHeartbeat()
        }
    }

    func startHeartbeatTimer() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            var gps_idle_interval_in_seconds = RWFrameworkConfig.getConfigValueAsNumber("gps_idle_interval_in_seconds").doubleValue
            self.heartbeatTimer = NSTimer.scheduledTimerWithTimeInterval(gps_idle_interval_in_seconds, target:self, selector:Selector("heartbeatTimer:"), userInfo:nil, repeats:true)
        })
    }

// MARK: - Audio

    func audioTimer(timer: NSTimer) {
        var percentage: Double = 0
        if !useComplexRecordingMechanism && isRecording() {
            let max_recording_length = RWFrameworkConfig.getConfigValueAsNumber("max_recording_length").doubleValue
            percentage = soundRecorder!.currentTime/max_recording_length
            soundRecorder!.updateMeters()
            rwRecordingProgress(percentage, maxDuration: max_recording_length, peakPower: soundRecorder!.peakPowerForChannel(0), averagePower: soundRecorder!.averagePowerForChannel(0))
        } else if useComplexRecordingMechanism && isRecording() {
            let max_recording_length = RWFrameworkConfig.getConfigValueAsNumber("max_recording_length").doubleValue
            let rwfar = RWFrameworkAudioRecorder.sharedInstance()
            percentage = rwfar.currentTime()/max_recording_length

            // TODO: Meters (kAudioUnitProperty_MeteringMode on a mixer in the AUGraph)

            var peakPower: Float = 0.0
            var averagePower: Float = 0.0
            rwRecordingProgress(percentage, maxDuration: max_recording_length, peakPower: peakPower, averagePower: averagePower)

            if percentage >= 1.0 {
                stopRecording()
                rwAudioRecorderDidFinishRecording()
            }
        } else if isPlayingBack() {
            percentage = soundPlayer!.currentTime/soundPlayer!.duration
            soundPlayer!.updateMeters()
            rwPlayingBackProgress(percentage, duration: soundPlayer!.duration, peakPower: soundPlayer!.peakPowerForChannel(0), averagePower: soundPlayer!.averagePowerForChannel(0))
        }
    }

    func startAudioTimer() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.audioTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target:self, selector:Selector("audioTimer:"), userInfo:nil, repeats:true)
        })
    }

// MARK: - Upload

    func uploadTimer(timer: NSTimer) {
        mediaUploader()
    }

    func startUploadTimer() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.uploadTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target:self, selector:Selector("uploadTimer:"), userInfo:nil, repeats:true)
        })
    }

}