
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
        if timedAssets == nil {
            timedAssets = []
            // load the timed assets
            RWFramework.sharedInstance.apiGetTimedAssets([
                "project_id": String(playlist.project.id)
            ]).then { data in
                self.timedAssets = data
            }
            return .discard
        } else if timedAssets!.isEmpty {
            return .discard
        }
        
        // keep assets that are slated to start now or in the past few minutes
        //      AND haven't been played before
        // Units: seconds
        let now = Date().timeIntervalSince(playlist.startTime)
        if (timedAssets!.contains { it in
            it.asset_id == asset.id &&
                it.start <= now &&
                it.end >= now &&
                // it hasn't been played before.
                playlist.userAssetData[it.asset_id] == nil
        }) {
            // Prioritize timed assets only if the project is configured to.
            if playlist.project.timed_asset_priority {
                return .highest
            } else {
                return .normal
            }
        }
        
        return .discard
    }
}
