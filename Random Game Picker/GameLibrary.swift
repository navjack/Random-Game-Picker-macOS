import Foundation

struct GameLibrary {
    static func filteredGames(_ games: [String], searchText: String) -> [String] {
        guard !searchText.isEmpty else { return games }
        return games.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    static func insertGame(_ game: String, into games: [String]) -> [String] {
        var updated = games
        let insertionIndex = updated.firstIndex { game.localizedCaseInsensitiveCompare($0) == .orderedAscending } ?? updated.count
        updated.insert(game, at: insertionIndex)
        return updated
    }

    static func removeGame(_ game: String, from games: [String]) -> [String] {
        var updated = games
        if let index = updated.firstIndex(of: game) {
            updated.remove(at: index)
        }
        return updated
    }

    static func parseGames(from content: String) -> [String] {
        return content
            .components(separatedBy: "\n")
            .map { $0.replacingOccurrences(of: ";", with: "").trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    static func serializeGames(_ games: [String]) -> String {
        games.joined(separator: "\n")
    }

    static func pickRandomGame<R: RandomNumberGenerator>(from games: [String], using rng: inout R) -> String? {
        guard !games.isEmpty else { return nil }
        let index = Int(rng.next() % UInt64(games.count))
        return games[index]
    }
}
