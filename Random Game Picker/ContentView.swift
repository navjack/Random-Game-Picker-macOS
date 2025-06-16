import SwiftUI

struct ContentView: View {
    @State private var consoles: [Console] = []
    @State private var selectedConsole: Console?
    @State private var randomGame: String?
    @State private var newGame: String = ""
    @State private var selectedGame: String?
    @State private var scrollTarget: String?
    @State private var searchText: String = ""
    @State private var randomHistory: [String] = []

    private func filteredGames(console: Console) -> [String] {
        if searchText.isEmpty { return console.games }
        return console.games.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationSplitView {
            List(consoles) { console in
                Button(action: {
                    selectedConsole = console
                    randomGame = nil // Reset random selection when switching consoles
                    searchText = ""
                    scrollTarget = nil
                    selectedGame = nil
                }) {
                    Text(console.name)
                }
                .accessibilityLabel(console.name)
            }
            .navigationTitle("Consoles")
            .onAppear(perform: loadConsoles)
        } detail: {
            if let console = selectedConsole {
                VStack {
                    ScrollViewReader { proxy in
                        List(filteredGames(console: console), id: \.self) { game in
                            HStack {
                                Text(game)
                                        .onTapGesture {
                                            selectedGame = game
                                        }
                                        .background(selectedGame == game ? Color.gray.opacity(0.3) : Color.clear)

                                    Spacer()

                                    Button(action: {
                                        if let index = consoles.firstIndex(where: { $0.id == selectedConsole?.id }) {
                                            if let gameIndex = consoles[index].games.firstIndex(of: game) {
                                                consoles[index].games.remove(at: gameIndex)
                                                saveGames(for: consoles[index]) // Save modifications
                                                selectedConsole = consoles[index] // Refresh view
                                            }
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .accessibilityLabel("Delete \(game)")
                                    .buttonStyle(BorderlessButtonStyle()) // Ensure button works in List
                                }
                                .padding(.vertical, 4)
                                .id(game)
                        }
                        .searchable(text: $searchText)
                        .animation(nil, value: searchText)
                        .onChange(of: searchText) { _, _ in
                            scrollTarget = nil
                            selectedGame = nil
                        }
                        // Keep a stable identity for the list so the search
                        // field retains focus while typing. The selection and
                        // scroll target are cleared on every searchText change
                        // to avoid index crashes.
                        .id(console.id)
                        .onChange(of: scrollTarget) { newValue, _ in
                            if let target = newValue {
                                withAnimation {
                                    proxy.scrollTo(target, anchor: .center)
                                }
                            }
                        }
                    }
                    
                    Button(action: {
                        if let console = selectedConsole, let index = consoles.firstIndex(where: { $0.id == console.id }) {
                            saveGames(for: consoles[index]) // Save the displayed game list
                        }
                    }) {
                        Label("Save Changes", systemImage: "square.and.arrow.down")
                    }
                    .accessibilityLabel("Save Changes")
                    .padding()
                    
                    TextField("Enter new game", text: $newGame)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .accessibilityLabel("New Game")
                        .padding()
                    
                    Button(action: {
                        let trimmed = newGame.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        if let index = consoles.firstIndex(where: { $0.id == selectedConsole?.id }) {
                            let insertionIndex = consoles[index].games.firstIndex { trimmed.localizedCaseInsensitiveCompare($0) == .orderedAscending } ?? consoles[index].games.count
                            consoles[index].games.insert(trimmed, at: insertionIndex)
                            saveGames(for: consoles[index]) // Save modifications
                            newGame = "" // Reset input field
                            selectedConsole = consoles[index] // Refresh view
                            selectedGame = trimmed
                            scrollTarget = trimmed
                        }
                    }) {
                        Label("Add Game", systemImage: "plus")
                    }
                    .accessibilityLabel("Add Game")
                    .padding()

                    Button(action: pickRandomGame) {
                        Label("Pick Random Game", systemImage: "die.face.3")
                    }
                    .accessibilityLabel("Pick Random Game")
                    .padding()

                    if let game = randomGame {
                        Text("🎲 Random Pick: \(game)")
                            .font(.headline)
                            .textSelection(.enabled) // Allows copy-pasting
                            .padding()
                    }

                    if !randomHistory.isEmpty {
                        VStack(alignment: .leading) {
                            Text("History")
                                .font(.headline)
                            ForEach(randomHistory.suffix(5), id: \.self) { entry in
                                Text(entry)
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle(console.name)
            } else {
                Text("Select a console")
            }

        }
    }
    
    private func baseDirectory() -> URL? {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents?.appendingPathComponent("NavJack Software/Random Game Picker/Save Data")
    }

    private func saveGames(for console: Console) {
        guard let base = baseDirectory() else { return }
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        let fileURL = base.appendingPathComponent("\(console.name).txt")

        do {
            let content = console.games.joined(separator: "\n")
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving games for \(console.name): \(error)")
        }
    }

    // Load console names from text files
    private func loadConsoles() {
        let fileManager = FileManager.default
        let path = Bundle.main.resourcePath! // Update this if using a different directory

        do {
            let files = try fileManager.contentsOfDirectory(atPath: path)
            let gameFiles = files.filter { $0.hasSuffix(".txt") }

            consoles = gameFiles.map { fileName in
                let consoleName = fileName.replacingOccurrences(of: ".txt", with: "")
                let games = loadGames(for: fileName) ?? []
                return Console(name: consoleName, games: games)
            }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            loadRandomHistory()
        } catch {
            print("Error loading consoles: \(error)")
        }
    }

    // Load game list from a text file
    private func loadGames(for fileName: String) -> [String]? {
        let fileManager = FileManager.default
        let docURL = baseDirectory()?.appendingPathComponent(fileName)
        // User-edited lists in Documents override bundled defaults.
        if let docPath = docURL?.path, fileManager.fileExists(atPath: docPath) {
            do {
                let content = try String(contentsOfFile: docPath, encoding: .utf8)
                return content.components(separatedBy: "\n")
                    .map { $0.replacingOccurrences(of: ";", with: "").trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            } catch {
                print("Error reading file \(fileName) from Documents: \(error)")
            }
        }

        if let path = Bundle.main.path(forResource: fileName.replacingOccurrences(of: ".txt", with: ""), ofType: "txt") {
            do {
                let content = try String(contentsOfFile: path, encoding: .utf8)
                return content.components(separatedBy: "\n")
                    .map { $0.replacingOccurrences(of: ";", with: "").trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            } catch {
                print("Error reading file \(fileName): \(error)")
            }
        }
        return nil
    }
    
    // Pick a random game
    private func pickRandomGame() {
        if let games = selectedConsole?.games, !games.isEmpty, let consoleName = selectedConsole?.name, let pick = games.randomElement() {
            randomGame = pick
            randomHistory.append("\(consoleName): \(pick)")
            saveRandomHistory()
        }
    }

    private func saveRandomHistory() {
        guard let url = baseDirectory()?.appendingPathComponent("RandomPickHistory.txt") else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let content = randomHistory.joined(separator: "\n")
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }

    private func loadRandomHistory() {
        guard let url = baseDirectory()?.appendingPathComponent("RandomPickHistory.txt") else { return }
        if let data = try? String(contentsOf: url, encoding: .utf8) {
            randomHistory = data.components(separatedBy: "\n").filter { !$0.isEmpty }
        }
    }
}

#Preview {
    ContentView()
}

struct Console: Identifiable {
    let id = UUID()
    let name: String
    var games: [String]
}
