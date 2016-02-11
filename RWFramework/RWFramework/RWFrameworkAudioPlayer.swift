//
//  RWFrameworkAudioPlayer.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/5/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation
import AVFoundation

extension RWFramework {

    /// This is set in the self.player's willSet/didSet
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        //println("keyPath: \(keyPath) object: \(object) change: \(change)")

        rwObserveValueForKeyPath(keyPath, ofObject: object, change: change, context: context)

//        if (keyPath == "timedMetadata") {
//            let newChange = change["new"] as! NSArray // NB: change may be nil when backgrounding - TOFIX
//            let avMetadataItem = newChange.firstObject as! AVMetadataItem
//            let value = avMetadataItem.value
//            println("AVMetadataItem value = \(value)")
//
//        }
    }

    /// Return true if the framework can play audio
    public func canPlay() -> Bool {
        let listen_enabled = RWFrameworkConfig.getConfigValueAsBool("listen_enabled")
        return listen_enabled && streamURL != nil
    }

    /// Create an AVPlayer to play the stream
    func createPlayer() {
        if (streamURL == nil) { return }
        player = AVPlayer.playerWithURL(streamURL!) as? AVPlayer
    }

    /// Destroy the AVPlayer
    func destroyPlayer() {
        if (player == nil) { return }
        player = nil
    }

    /// Begin playing audio
    public func play() {
        if (canPlay() == false) { return }
        if (player == nil) {
            createPlayer()
        }
        player?.play()
        isPlaying = (player?.rate == 1.0)
        logToServer("start_listen")
    }

    /// Pause audio
    public func pause() {
        if (canPlay() == false) { return }
        player?.pause()
        isPlaying = (player?.rate == 1.0)
    }

    /// Stop audio
    public func stop() {
        pause()
        destroyPlayer()
        createPlayer()
        logToServer("stop_listen")
    }

    /// Next audio
    public func next() {
        apiPostStreamsIdNext()
    }

    /// Current audio
    public func current() {
        apiGetStreamsIdCurrent()
    }

}