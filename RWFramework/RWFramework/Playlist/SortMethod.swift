
import Foundation
import Promises

protocol SortMethod {
    /**
     The sorting ranking of the given asset.
     Assets will be sorted in ascending order of their rank.
     Thus, returning a negatized result effectively causes
     assets to be in descending order.
    */
    func sortRanking(for asset: Asset, in playlist: Playlist) -> Double

    /// Load any data required before sorting.
    func onRefreshAssets(in playlist: Playlist) -> Promise<Void>
}

extension SortMethod {
    /// By default does nothing when assets are refreshed.
    func onRefreshAssets(in playlist: Playlist) -> Promise<Void> {
        return Promise(())
    }
}

/**
 Sort assets in totally random order.
 */
struct SortRandomly: SortMethod {
    func sortRanking(for asset: Asset, in playlist: Playlist) -> Double {
        return Double.random(in: 0...1)
    }
}

/**
 Sort assets in descending order of assigned weight.
 */
struct SortByWeight: SortMethod {
    func sortRanking(for asset: Asset, in playlist: Playlist) -> Double {
        return -asset.weight
    }
}

/**
 Sort assets in descending order of current number of likes.
 */
class SortByLikes: SortMethod {
    private var assetVotes: [Int: Int]? = nil

    func sortRanking(for asset: Asset, in playlist: Playlist) -> Double {
        if let votes = assetVotes?[asset.id] {
            return Double(-votes)
        } else {
            return 0.0
        }
    }

    func onRefreshAssets(in playlist: Playlist) -> Promise<Void> {
        let projectId = playlist.project.id
        return RWFramework.sharedInstance.apiGetVotesSummary(
            type: "like",
            projectId: projectId.description
        ).then { data -> Void in
            let voteData = try RWFramework.decoder.decode([AssetVote].self, from: data)
            self.assetVotes = voteData.reduce(into: [Int: Int]()) { acc, item in
                acc[item.asset_id] = item.asset_votes
            }
        }
    }

    private struct AssetVote: Codable {
        let asset_id: Int
        let asset_votes: Int
    }
}
