//
//  RWFrameworkTimers.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/17/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation

extension RWFramework {
// MARK: - Audio

    @objc func audioTimer(_ timer: Timer) {
        var percentage: Double = 0
        if isRecording() {
            let soundRecorder = playlist.recorder!.soundRecorder
            let max_recording_length = RWFrameworkConfig.getConfigValueAsNumber("max_recording_length").doubleValue
            percentage = soundRecorder!.currentTime/max_recording_length
            soundRecorder!.updateMeters()
            rwRecordingProgress(percentage, maxDuration: max_recording_length, peakPower: soundRecorder!.peakPower(forChannel: 0), averagePower: soundRecorder!.averagePower(forChannel: 0))
        } else if isPlayingBack() {
            let soundRecorder = playlist.recorder!.soundRecorder
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
        // TODO Use the promise and progress
//        playlist.recorder?.onProgress { progress in
//            print("recorder: upload progress = \(progress)")
//        }
    }

    func startUploadTimer() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.uploadTimer = Timer.scheduledTimer(timeInterval: 5.0, target:self, selector:#selector(RWFramework.uploadTimer(_:)), userInfo:nil, repeats:true)
        })
    }

}
