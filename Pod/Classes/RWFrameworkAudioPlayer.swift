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

    //TODO consider http://blog.scottlogic.com/2015/02/11/swift-kvo-alternatives.html
    /// This is set in the self.player's willSet/didSet

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        println(object: "keyPath: \(keyPath) object: \(object) change: \(change)")
        rwObserveValueForKeyPath(keyPath: keyPath, ofObject: object as AnyObject?, change: change as [NSKeyValueChangeKey : AnyObject]?, context: context)

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
        let listen_enabled = RWFrameworkConfig.getConfigValueAsBool(key: "listen_enabled")
        return listen_enabled && streamURL != nil
    }

    /// Create an AVPlayer to play the stream
    func createPlayer() {
        if (streamURL == nil) { return }
        player = AVPlayer(url:streamURL! as URL) as AVPlayer
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
        logToServer(event_type: "start_listen")
    }

    /// Pause audio
    public func pause() {
        if (canPlay() == false) { return }
        player?.pause()
        isPlaying = (player?.rate == 1.0)
        apiPostStreamsIdPause()
    }

    /// Resume audio
    public func resume() {
        if (canPlay() == false) { return }
        if (player == nil) {
            createPlayer()
        }
        player?.play()
        isPlaying = (player?.rate == 1.0)
        apiPostStreamsIdResume()
    }

    /// Stop audio
    public func stop() {
        pause()
        destroyPlayer()
        //commented out because player shouldn't exist after a stop
//        createPlayer()
        logToServer(event_type: "stop_listen")
    }

    /// Replay current asset
    public func replayAsset() {
        apiPostStreamsIdReplayAsset()
    }

    /// Skip to next asset
    public func skip() {
        apiPostStreamsIdSkip()
    }

    /// Play selected asset
    public func playAsset(asset_id: String) {
        apiPostStreamsIdPlayAsset(asset_id: asset_id)
    }

    /// Request info about current asset
    public func current() {
        apiGetStreamsIdCurrent()
    }
}
