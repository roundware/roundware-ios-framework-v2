
import Promises

public struct TimedAsset: Codable {
    let id: Int
    let asset_id: Int
    let start: Double
    let end: Double
}

public class TimedAssetFilter: AssetFilter {
    private var timedAssets: [TimedAsset]? = nil

    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        if track.timedAssetPriority == .discard {
            return .discard
        }
        
        // keep assets that are slated to start now or in the past few minutes
        //      AND haven't been played before
        // Units: seconds
        let now = Date().timeIntervalSince(playlist.startTime)
        if timedAssets!.contains(where: { it in
            it.asset_id == asset.id &&
                it.start <= now &&
                it.end >= now &&
                // it hasn't been played before.
                playlist.userAssetData[it.asset_id] == nil
        }) {
            // Prioritize timed assets only if the track is configured to.
            return track.timedAssetPriority
        }
        
        return .discard
    }

    func onUpdateAssets(playlist: Playlist) -> Promise<Void> {
        if timedAssets == nil {
            return RWFramework.sharedInstance.apiGetTimedAssets([
                "project_id": String(playlist.project.id)
            ]).then { data in
                self.timedAssets = data
            }
        } else {
            return Promise(())
        }
    }
}
