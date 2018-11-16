
import Foundation

protocol SortMethod {
    func sortRanking(for asset: Asset, in playlist: Playlist) -> Double
}


class SortRandomly: SortMethod {
    func sortRanking(for asset: Asset, in playlist: Playlist) -> Double {
        return drand48()
    }
}

