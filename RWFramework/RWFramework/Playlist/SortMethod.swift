
import Foundation

protocol SortMethod {
    func sortRanking(for asset: Asset, in playlist: Playlist) -> Double
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