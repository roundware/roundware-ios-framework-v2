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
    public var isPlaying: Bool {
        return self.playlist.isPlaying
    }

    /// This is set in the self.player's willSet/didSet
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        rwObserveValueForKeyPath(forKeyPath: keyPath, of: object, change: change, context: context)
    }

    /// Return true if the framework can play audio
    public func canPlay() -> Bool {
        let listen_enabled = RWFrameworkConfig.getConfigValueAsBool("listen_enabled")
        return listen_enabled //&& streamURL != nil
    }

    /// Begin playing audio
    public func play() {
        self.playlist.resume()
    }

    /// Pause audio
    public func pause() {
        self.playlist.pause()
    }

    /// Stop audio
    public func stop() {
        pause()
    }

    /// Next audio
    public func skip() {
        playlist.skip()
    }

    /// Replay audio
    public func replay() {
        playlist.replay()
    }
    
    /// Check if stream active
    public func isActive() {
    }
}
