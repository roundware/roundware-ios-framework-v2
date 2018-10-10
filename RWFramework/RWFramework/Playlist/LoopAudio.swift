
import StreamingKit

class LoopAudio: NSObject, STKAudioPlayerDelegate {
    let current: String
    
    /// Loop the given url as long as this delegate is applied.
    init(_ asset: String) {
        self.current = asset
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didStartPlayingQueueItemId queueItemId: NSObject) {
        if (audioPlayer.pendingQueueCount < 1) {
            audioPlayer.queue(current)
        }
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishBufferingSourceWithQueueItemId queueItemId: NSObject) {
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, stateChanged state: STKAudioPlayerState, previousState: STKAudioPlayerState) {
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishPlayingQueueItemId queueItemId: NSObject, with stopReason: STKAudioPlayerStopReason, andProgress progress: Double, andDuration duration: Double) {
        if (audioPlayer.pendingQueueCount < 1) {
            audioPlayer.queue(current)
        }
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, unexpectedError errorCode: STKAudioPlayerErrorCode) {
    }
}
