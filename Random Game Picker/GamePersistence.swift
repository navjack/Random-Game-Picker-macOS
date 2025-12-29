import Foundation

struct GamePersistence {
    static func saveGames(_ games: [String], to url: URL) throws {
        try createDirectoryIfNeeded(for: url)
        let content = GameLibrary.serializeGames(games)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    static func loadGames(from url: URL) throws -> [String] {
        let content = try String(contentsOf: url, encoding: .utf8)
        return GameLibrary.parseGames(from: content)
    }

    static func saveHistory(_ history: [String], to url: URL) throws {
        try createDirectoryIfNeeded(for: url)
        let content = history.joined(separator: "\n")
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    static func loadHistory(from url: URL) throws -> [String] {
        let content = try String(contentsOf: url, encoding: .utf8)
        return content.components(separatedBy: "\n").filter { !$0.isEmpty }
    }

    static func savePapers(_ papers: [PaperSlip], to url: URL) throws {
        try createDirectoryIfNeeded(for: url)
        let data = try JSONEncoder().encode(papers)
        try data.write(to: url, options: .atomic)
    }

    static func loadPapers(from url: URL) throws -> [PaperSlip] {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([PaperSlip].self, from: data)
    }

    private static func createDirectoryIfNeeded(for url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
}
