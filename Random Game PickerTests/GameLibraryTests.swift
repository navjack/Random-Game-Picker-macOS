import XCTest
@testable import Random_Game_Picker

final class GameLibraryTests: XCTestCase {
    func testFilteredGamesCaseInsensitive() {
        let games = ["Zelda", "Metroid", "Super Mario"]

        let filtered = GameLibrary.filteredGames(games, searchText: "mAR")

        XCTAssertEqual(filtered, ["Super Mario"])
    }

    func testInsertGameSorted() {
        let games = ["Banjo", "Zelda"]

        let updated = GameLibrary.insertGame("Mario", into: games)

        XCTAssertEqual(updated, ["Banjo", "Mario", "Zelda"])
    }

    func testRemoveGameRemovesFirstMatch() {
        let games = ["Mario", "Zelda", "Mario"]

        let updated = GameLibrary.removeGame("Mario", from: games)

        XCTAssertEqual(updated, ["Zelda", "Mario"])
    }

    func testParseGamesTrimsAndSorts() {
        let content = " Zelda \n;Metroid\n\nMario; \n"

        let parsed = GameLibrary.parseGames(from: content)

        XCTAssertEqual(parsed, ["Mario", "Metroid", "Zelda"])
    }

    func testSerializeGames() {
        let games = ["A", "B", "C"]

        let serialized = GameLibrary.serializeGames(games)

        XCTAssertEqual(serialized, "A\nB\nC")
    }

    func testPickRandomGameDeterministic() {
        var rng = FixedRNG(values: [1])
        let games = ["A", "B", "C"]

        let pick = GameLibrary.pickRandomGame(from: games, using: &rng)

        XCTAssertEqual(pick, "B")
    }

    func testSaveAndLoadGamesRoundTrip() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("games.txt")
        let games = ["Alpha", "Beta"]

        try GamePersistence.saveGames(games, to: tempURL)
        let loaded = try GamePersistence.loadGames(from: tempURL)

        XCTAssertEqual(loaded, games)
    }

    func testSaveAndLoadHistoryRoundTrip() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("history.txt")
        let history = ["NES: Zelda", "SNES: Metroid"]

        try GamePersistence.saveHistory(history, to: tempURL)
        let loaded = try GamePersistence.loadHistory(from: tempURL)

        XCTAssertEqual(loaded, history)
    }

    func testSaveAndLoadPapersRoundTrip() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("papers.json")
        let paperId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let papers = [PaperSlip(id: paperId, text: "NES: Zelda", x: 120, y: 80, rotation: -1.5)]

        try GamePersistence.savePapers(papers, to: tempURL)
        let loaded = try GamePersistence.loadPapers(from: tempURL)

        XCTAssertEqual(loaded, papers)
    }
}

private struct FixedRNG: RandomNumberGenerator {
    private var values: [UInt64]

    init(values: [UInt64]) {
        self.values = values
    }

    mutating func next() -> UInt64 {
        if values.isEmpty {
            return 0
        }
        return values.removeFirst()
    }
}
