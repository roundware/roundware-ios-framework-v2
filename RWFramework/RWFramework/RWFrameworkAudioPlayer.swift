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
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        rwObserveValueForKeyPath(forKeyPath: keyPath, of: object, change: change, context: context)
    }

    /// Return true if the framework can play audio
    public func canPlay() -> Bool {
        let listen_enabled = RWFrameworkConfig.getConfigValueAsBool("listen_enabled")
        return listen_enabled //&& streamURL != nil
    }

    /// Create an AVPlayer to play the stream
    func createPlayer() {
        if (streamURL == nil) { return }
        player = AVPlayer(url: streamURL! as URL)
    }

    /// Destroy the AVPlayer
    public func destroyPlayer() {
        if (player == nil) { return }
        player = nil
    }

    /// Begin playing audio
    public func play() {
//        if (canPlay() == false) { return }
        self.playlist.resume()
//        if (player == nil) {
//            createPlayer()
//        }
//        player?.play()
//        isPlaying = (player?.rate == 1.0)
//        logToServer("start_listen")
//
//        // Tell server to resume asset playback
//        apiPostStreamsIdResume()
    }

    /// Pause audio
    public func pause() {
//        if (canPlay() == false) { return }
        self.playlist.pause()
//        player?.pause()
//        isPlaying = (player?.rate == 1.0)
//
//        // Tell server to stop adding assets to stream
//        apiPostStreamsIdPause()
    }

    /// Stop audio
    public func stop() {
        pause()
    }

    /// Next audio
    public func skip() {
//        apiPostStreamsIdSkip()
        playlist.skip()
    }

    /// Replay audio
    public func replay() {
        apiPostStreamsIdReplay()
    }
    
    /// Check if stream active
    public func isActive() {
        apiGetStreamsIdIsActive()
    }

}
