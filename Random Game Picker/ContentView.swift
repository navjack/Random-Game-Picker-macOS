import SwiftUI

struct ContentView: View {
    @State private var consoles: [Console] = []
    @State private var selectedConsole: Console?
    @State private var randomGame: String?
    @State private var globalRandomPick: (console: String, game: String)?
    @State private var newGame: String = ""
    @State private var selectedGame: String?

    var body: some View {
        NavigationSplitView {
            List(consoles) { console in
                Button(action: {
                    selectedConsole = console
                    randomGame = nil // Reset random selection when switching consoles
                }) {
                    Text(console.name)
                }
            }
            .navigationTitle("Consoles")
            .onAppear(perform: loadConsoles)
        } detail: {
            if let console = selectedConsole {
                VStack {
                    List {
                        ForEach(console.games, id: \.self) { game in
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
                                .buttonStyle(BorderlessButtonStyle()) // Ensure button works in List
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Button(action: {
                        if let console = selectedConsole, let index = consoles.firstIndex(where: { $0.id == console.id }) {
                            saveGames(for: consoles[index]) // Save the displayed game list
                        }
                    }) {
                        Label("Save Changes", systemImage: "square.and.arrow.down")
                    }
                    .padding()
                    
                    TextField("Enter new game", text: $newGame)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button(action: {
                        if !newGame.trimmingCharacters(in: .whitespaces).isEmpty {
                            if let index = consoles.firstIndex(where: { $0.id == selectedConsole?.id }) {
                                consoles[index].games.append(newGame.trimmingCharacters(in: .whitespaces))
                                consoles[index].games.sort() // Ensure sorting
                                saveGames(for: consoles[index]) // Save modifications
                                newGame = "" // Reset input field
                                selectedConsole = consoles[index] // Refresh view
                            }
                        }
                    }) {
                        Label("Add Game", systemImage: "plus")
                    }
                    .padding()

                    Button(action: pickRandomGame) {
                        Label("Pick Random Game", systemImage: "die.face.3")
                    }
                    .padding()

                    if let game = randomGame {
                        Text("🎲 Random Pick: \(game)")
                            .font(.headline)
                            .textSelection(.enabled) // Allows copy-pasting
                            .padding()
                    }
                }
                .navigationTitle(console.name)
            } else {
                Text("Select a console")
            }

        }
    }
    
    private func saveGames(for console: Console) {
        let fileName = "\(console.name).txt"
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)

        do {
            let content = console.games.joined(separator: "\n")
            try content.write(to: fileURL!, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving games for \(console.name): \(error)")
        }
    }

    private func pickRandomFromAll() {
        let allGames = consoles.flatMap { console in
            console.games.map { (console.name, $0) }
        }
        
        if let randomSelection = allGames.randomElement() {
            globalRandomPick = randomSelection
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
        } catch {
            print("Error loading consoles: \(error)")
        }
    }

    // Load game list from a text file
    private func loadGames(for fileName: String) -> [String]? {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let docURL = documentsURL?.appendingPathComponent(fileName)
        // User-edited lists in Documents override bundled defaults.
        if let docPath = docURL?.path, fileManager.fileExists(atPath: docPath) {
            do {
                let content = try String(contentsOfFile: docPath)
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
                let content = try String(contentsOfFile: path)
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
        if let games = selectedConsole?.games, !games.isEmpty {
            randomGame = games.randomElement()
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
