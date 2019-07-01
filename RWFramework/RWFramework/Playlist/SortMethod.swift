
import Foundation
import SwiftyJSON
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


struct SortRandomly: SortMethod {
    func sortRanking(for asset: Asset, in playlist: Playlist) -> Double {
        return Double.random(in: 0...1)
    }
}

struct SortByWeight: SortMethod {
    func sortRanking(for asset: Asset, in playlist: Playlist) -> Double {
        return -asset.weight
    }
}

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
            let voteData = try JSON(data: data).array
            self.assetVotes = voteData?.reduce(into: [Int: Int]()) { acc, data in
                let assetId = data["asset_id"].int!
                let votes = data["asset_votes"].int!
                acc[assetId] = votes
            }
        }
    }
}
