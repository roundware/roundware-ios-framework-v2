//
//  RWFrameworkAudioRecorder.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/5/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation
import AVFoundation

extension RWFramework: AVAudioRecorderDelegate, AVAudioPlayerDelegate {

// MARK: Media queue

    /// Add the current audio recording with optional description, returns a path (key) to the file that will ultimately be uploaded.
    /// NOTE: The audio recording is now queued for upload and can no longer be played back by the framework
    public func addRecording(description: String = "") -> String? {
        var key: String? = nil

        if (hasRecording() == false) { return key }

        let r = arc4random()
        let recorded_file_name = RWFrameworkConfig.getConfigValueAsString("recorded_file_name")
// TBD        let recordedFilePath = NSTemporaryDirectory().stringByAppendingPathComponent("\(r)_\(recorded_file_name)")
        let recordedFilePath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("\(r)_\(recorded_file_name)")?.absoluteString

        do {
            try NSFileManager.defaultManager().moveItemAtPath(soundFilePath(), toPath: recordedFilePath!)
            addMedia(MediaType.Audio, string: recordedFilePath!, description: description)
            key = recordedFilePath

            if useComplexRecordingMechanism {
                let rwfar = RWFrameworkAudioRecorder.sharedInstance()
                rwfar.deleteRecording()
            }
        }
        catch {
            println("RWFramework - Couldn't move recorded file \(error)")
        }
        return key
    }

    /// Set a description on an already added recording, pass the path returned from addRecording as the string parameter
    public func setRecordingDescription(string: String, description: String) {
        setMediaDescription(MediaType.Audio, string: string, description: description)
    }

    /// Remove an audio recording, pass the path returned from addRecording as the string parameter
    public func removeRecording(string: String) {
        removeMedia(MediaType.Audio, string: string)
    }

// MARK: Audio file/recording management

    /// Return the path to the recorded sound file
    func soundFilePath() -> String {
        let recorded_file_name = RWFrameworkConfig.getConfigValueAsString("recorded_file_name")
// TBD        let soundFilePath = NSTemporaryDirectory().stringByAppendingPathComponent(recorded_file_name)
        let soundFilePath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(recorded_file_name)
        println(soundFilePath)
        return (soundFilePath?.absoluteString)!
    }

    /// Return true if the framework can record audio
    public func canRecord() -> Bool {
        return RWFrameworkConfig.getConfigValueAsBool("speak_enabled")
    }

    /// Preflight any recording setup (mainly used when useComplexRecordingMechanism = true)
    public func preflightRecording() {
        if canRecord() && useComplexRecordingMechanism {
            let rwfar = RWFrameworkAudioRecorder.sharedInstance()
            rwfar.setupAllCustomAudio()
        }
    }

    /// Start recording audio
    public func startRecording() {
        let speak_enabled = RWFrameworkConfig.getConfigValueAsBool("speak_enabled")
        if (!speak_enabled) { return }

        let geo_speak_enabled = RWFrameworkConfig.getConfigValueAsBool("geo_speak_enabled")
        if (geo_speak_enabled) {
            locationManager.startUpdatingLocation()
        }

        if useComplexRecordingMechanism {
            let rwfar = RWFrameworkAudioRecorder.sharedInstance()
            rwfar.startAudioGraph()
            logToServer("start_record")
            // Recording will auto-stop via audioTimer function in RWFrameworkTimers.swift
        } else {
            soundRecorder = nil
            let soundFileURL = NSURL(fileURLWithPath: soundFilePath())
            let recordSettings =
                [AVSampleRateKey: 22050,
                AVFormatIDKey: NSNumber(unsignedInt: kAudioFormatMPEG4AAC),
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.Max.rawValue]

            do {
                soundRecorder = try AVAudioRecorder(URL: soundFileURL, settings: recordSettings)
                soundRecorder!.delegate = self
                _ = soundRecorder!.prepareToRecord()
                soundRecorder!.meteringEnabled = true
                let max_recording_length = RWFrameworkConfig.getConfigValueAsNumber("max_recording_length")
                _ = soundRecorder!.recordForDuration(max_recording_length.doubleValue)
                logToServer("start_record")
            }
            catch {
                println("RWFramework - Couldn't create AVAudioRecorder \(error)")
            }
        }
    }

    /// Stop recording audio
    public func stopRecording() {
        if useComplexRecordingMechanism {
            let rwfar = RWFrameworkAudioRecorder.sharedInstance()
            if (rwfar.isRecording() == false) { return }
            rwfar.stopAudioGraph()
            logToServer("stop_record")

            let soundFileURL = rwfar.outputURL // caf file
            let outputURL = NSURL(fileURLWithPath: soundFilePath()) // soon to be m4a

            do {
                _ = try NSFileManager.defaultManager().removeItemAtPath(soundFilePath())

                let options = ["AVURLAssetPreferPreciseDurationAndTimingKey": true]
                let audioAsset = AVURLAsset(URL: soundFileURL, options: options)
                let exportSession = AVAssetExportSession(asset: audioAsset, presetName: AVAssetExportPresetMediumQuality)
        
                exportSession!.outputURL = outputURL
                exportSession!.outputFileType = AVFileTypeQuickTimeMovie
                exportSession!.exportAsynchronouslyWithCompletionHandler { () -> Void in
                    if (exportSession!.status == AVAssetExportSessionStatus.Completed) {
                        self.println("file conversion success to \(outputURL)")
                    } else {
                        self.println("file conversion failure from \(soundFileURL)")
                    }
                }
            }
            catch {
                println("RWFramework - Couldn't removeItemAtPath \(error)")
            }

        } else {
            if (soundRecorder == nil) { return }
            if soundRecorder!.recording {
                soundRecorder!.stop()
                logToServer("stop_record")
            }
        }
    }

    /// Playback the most recent audio recording
    public func startPlayback() {
        if useComplexRecordingMechanism {
            stopPlayback()

            let rwfar = RWFrameworkAudioRecorder.sharedInstance()
            let soundFileURL = rwfar.outputURL

            do {
                soundPlayer = try AVAudioPlayer(contentsOfURL: soundFileURL)
                soundPlayer!.delegate = self
                _ = soundPlayer!.prepareToPlay()
                soundPlayer!.meteringEnabled = true
                _ = soundPlayer!.play()
            }
            catch {
                println("RWFramework - Couldn't create AVAudioPlayer \(error)")
            }

        } else {
            if hasRecording() == false { return }
            stopPlayback()
            soundPlayer = nil

            let soundFileURL = NSURL(fileURLWithPath: soundFilePath())

            do {
                soundPlayer = try AVAudioPlayer(contentsOfURL: soundFileURL)
                soundPlayer!.delegate = self
                _ = soundPlayer!.prepareToPlay()
                soundPlayer!.meteringEnabled = true
                _ = soundPlayer!.play()
            }
            catch {
                println("RWFramework - Couldn't create AVAudioPlayer \(error)")
            }
        }
    }

    /// Stop playing back the most recent audio recording
    public func stopPlayback() {
        if (soundPlayer == nil) { return }
        if (soundPlayer!.playing) {
            soundPlayer!.stop()
        }
    }

    /// Returns true if currently playing back the most recent audio recording, false otherwise
    public func isPlayingBack() -> Bool {
        if (soundPlayer == nil) { return false }
        return soundPlayer!.playing
    }

    /// Returns true if currently recording, false otherwise
    public func isRecording() -> Bool {
        if useComplexRecordingMechanism {
            let rwfar = RWFrameworkAudioRecorder.sharedInstance()
            return rwfar.isRecording()
        } else {
            if (soundRecorder == nil) { return false }
            return soundRecorder!.recording
        }
    }

    /// Returns true if there is a most recent recording, false otherwise
    public func hasRecording() -> Bool {
        if useComplexRecordingMechanism {
            let rwfar = RWFrameworkAudioRecorder.sharedInstance()
            return rwfar.hasRecording()
        } else {
            return NSFileManager.defaultManager().fileExistsAtPath(soundFilePath())
        }
    }

    /// Deletes the most recent recording
    public func deleteRecording() {
        if (hasRecording() == false) { return }
        let filePathToDelete: String
        if useComplexRecordingMechanism {
            let rwfar = RWFrameworkAudioRecorder.sharedInstance()
            filePathToDelete = rwfar.outputURL.path!
            rwfar.deleteRecording()
        } else {
            filePathToDelete = soundFilePath()
        }

        do {
            _ = try NSFileManager.defaultManager().removeItemAtPath(filePathToDelete)
        }
        catch {
            println("RWFramework - Couldn't delete recording \(error)")
        }
    }

// MARK: AVAudioRecorderDelegate

    public func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        println("audioRecorderDidFinishRecording")
        rwAudioRecorderDidFinishRecording()
    }

    public func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder, error: NSError?) {
        println("audioRecorderEncodeErrorDidOccur \(error)")
        alertOK("RWFramework - Audio Encode Error", message: error!.localizedDescription)
    }

// MARK: AVAudioPlayerDelegate

    public func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        println("audioPlayerDidFinishPlaying")
        rwAudioPlayerDidFinishPlaying()
    }
    
    public func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        println("audioPlayerDecodeErrorDidOccur \(error)")
        alertOK("RWFramework - Audio Decode Error", message: error!.localizedDescription)
    }

}
