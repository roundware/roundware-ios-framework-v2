
import Promises

public struct TimedAsset: Codable {
    let id: Int
    let asset_id: Int
    let start: Int
    let end: Int
}

public class TimedAssetFilter: AssetFilter {
    private var timedAssets: [TimedAsset]? = nil

    func keep(_ asset: Asset, playlist: Playlist, track: AudioTrack) -> AssetPriority {
        if timedAssets == nil {
            // load the timed assets
            do {
                timedAssets = try await(RWFramework.sharedInstance.apiGetTimedAssets([
                    "project_id": String(playlist.project.id)
                ]).timeout(5))
            } catch {
                return .discard
            }
        }
        // keep assets that are slated to start now or in the past few minutes
        //      AND haven't been played before
        // Units: seconds
        let now = Int(Date().timeIntervalSince(playlist.startTime))
        let earliest = now - 60*2 // few minutes ago
        if (timedAssets!.contains { it in
            return it.asset_id == asset.id &&
                it.start <= now &&
                it.start > earliest &&
                // it hasn't been played before.
                playlist.userAssetData[it.asset_id] == nil
        }) {
            return .highest
        }
        
        return .discard
    }
}
