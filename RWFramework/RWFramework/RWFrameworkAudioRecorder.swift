//
//  RWFrameworkAudioRecorder.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/5/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import AVFoundation
import Foundation

extension RWFramework: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    // MARK: Media queue

    /// Add the current audio recording with optional description, returns a path (key) to the file that will ultimately be uploaded.
    /// NOTE: The audio recording is now queued for upload and can no longer be played back by the framework
    public func addRecording(_ description: String = "") -> URL? {
        return playlist.recorder!.addRecording(description)
    }

    /// Set a description on an already added recording, pass the path returned from addRecording as the string parameter
    public func setRecordingDescription(_ string: String, description: String) {
        print("recorder: set recording (\(string)) desc: \(description)")
        // setMediaDescription(MediaType.Audio, string: string, description: description)
    }

    /// Remove an audio recording, pass the path returned from addRecording as the string parameter
    public func removeRecording(_ string: String) {
        print("recorder: remove recording (\(string))")
        // removeMedia(MediaType.Audio, string: string)
    }

    // MARK: Audio file/recording management

    /// Return the path to the recorded sound file
    func soundFilePath() -> String {
        let recorded_file_name = RWFrameworkConfig.getConfigValueAsString("recorded_file_name")
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let soundFilePath = paths[0].appendingPathComponent(recorded_file_name)
        println(soundFilePath)
        return (soundFilePath.path)
    }

    func soundFilePathURL() -> URL {
        let recorded_file_name = RWFrameworkConfig.getConfigValueAsString("recorded_file_name")
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let soundFileURL = paths[0].appendingPathComponent(recorded_file_name)
        println(soundFileURL)
        return (soundFileURL)
    }

    /// Return true if the framework can record audio
    public func canRecord() -> Bool {
        return RWFrameworkConfig.getConfigValueAsBool("speak_enabled")
    }

    /// Preflight any recording setup (mainly used when useComplexRecordingMechanism = true)
    public func preflightRecording() {}

    /// Start recording audio
    public func startRecording() {
        let speak_enabled = RWFrameworkConfig.getConfigValueAsBool("speak_enabled")
        if !speak_enabled { return }

        let geo_speak_enabled = RWFrameworkConfig.getConfigValueAsBool("geo_speak_enabled")
        if geo_speak_enabled {
            locationManager.startUpdatingLocation()
        }

        playlist.recorder!.startRecording()
    }

    /// Stop recording audio
    public func stopRecording() {
        playlist.recorder!.stopRecording()
    }

    /// Playback the most recent audio recording
    public func startPlayback() {
        if hasRecording() == false { return }
        stopPlayback()
        soundPlayer = nil

        let soundFileURL = playlist.recorder!.lastRecordingPath

        do {
            soundPlayer = try AVAudioPlayer(contentsOf: soundFileURL)
            soundPlayer!.delegate = self
            _ = soundPlayer!.prepareToPlay()
            soundPlayer!.isMeteringEnabled = true
            _ = soundPlayer!.play()
        } catch {
            println("RWFramework - Couldn't create AVAudioPlayer \(error)")
        }
    }

    /// Stop playing back the most recent audio recording
    public func stopPlayback() {
        if soundPlayer == nil { return }
        if soundPlayer!.isPlaying {
            soundPlayer!.stop()
        }
    }

    /// Returns true if currently playing back the most recent audio recording, false otherwise
    public func isPlayingBack() -> Bool {
        if soundPlayer == nil { return false }
        return soundPlayer!.isPlaying
    }

    /// Returns true if currently recording, false otherwise
    public func isRecording() -> Bool {
        return playlist.recorder?.isRecording ?? false
    }

    /// Returns true if there is a most recent recording, false otherwise
    public func hasRecording() -> Bool {
        return playlist.recorder?.hasRecording ?? false
    }

    /// Deletes the most recent recording
    public func deleteRecording() {
        print("recorder: delete last")
        if hasRecording() == false { return }
        let filePathToDelete: String
        filePathToDelete = soundFilePath()

        do {
            _ = try FileManager.default.removeItem(atPath: filePathToDelete)
        } catch {
            println("RWFramework - Couldn't delete recording \(error)")
        }
    }

    // MARK: AVAudioRecorderDelegate

    public func audioRecorderDidFinishRecording(_: AVAudioRecorder, successfully _: Bool) {
        println("audioRecorderDidFinishRecording")
        rwAudioRecorderDidFinishRecording()
    }

    public func audioRecorderEncodeErrorDidOccur(_: AVAudioRecorder, error: Error?) {
        println("audioRecorderEncodeErrorDidOccur \(String(describing: error))")
        alertOK("RWFramework - Audio Encode Error", message: error!.localizedDescription)
    }

    // MARK: AVAudioPlayerDelegate

    public func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        println("audioPlayerDidFinishPlaying")
        rwAudioPlayerDidFinishPlaying()
    }

    public func audioPlayerDecodeErrorDidOccur(_: AVAudioPlayer, error: Error?) {
        println("audioPlayerDecodeErrorDidOccur \(String(describing: error))")
        alertOK("RWFramework - Audio Decode Error", message: error!.localizedDescription)
    }
}
