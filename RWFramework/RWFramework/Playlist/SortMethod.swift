
import Foundation

protocol SortMethod {
    func sortRanking(for asset: Asset, in playlist: Playlist) -> Double
}


struct SortRandomly: SortMethod {
    func sortRanking(for asset: Asset, in playlist: Playlist) -> Double {
        return drand48()
    }
}

struct SortByWeight: SortMethod {
    func sortRanking(for asset: Asset, in playlist: Playlist) -> Double {
        return -asset.weight
    }
}