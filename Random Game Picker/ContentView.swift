import SwiftUI

struct ContentView: View {
	@State private var consoles: [Console] = []
	@State private var selectedConsole: Console?
	@State private var randomGame: String?
	@State private var randomGameConsoleName: String?
	@State private var newGame: String = ""
	@State private var selectedGame: String?
	@State private var scrollTarget: String?
    @State private var searchText: String = ""
    @State private var randomHistory: [String] = []
    @State private var papers: [PaperSlip] = []
    @State private var canvasSize: CGSize = .zero
    @State private var draggingPaperId: UUID?

    private let randomSectionHeight: CGFloat = 220
	private let paperTearSound = PaperTearSound.shared

	private func filteredGames(console: Console) -> [String] {
		GameLibrary.filteredGames(console.games, searchText: searchText)
	}

	var body: some View {
		NavigationSplitView {
			List(consoles) { console in
				Button {
					selectedConsole = console
					randomGame = nil // Reset random selection when switching consoles
					randomGameConsoleName = nil
					searchText = ""
					scrollTarget = nil
					selectedGame = nil
				} label: {
					Text(console.name)
				}
				.accessibilityLabel(console.name)
			}
			.navigationTitle("Consoles")
			.onAppear(perform: loadConsoles)
		} detail: {
			if let console = selectedConsole {
				ZStack {
					VStack {
						ScrollViewReader { proxy in
						List(filteredGames(console: console), id: \.self) { game in
							HStack {
								Text(game)
									.onTapGesture {
										selectedGame = game
									}
									.padding(.vertical, 4)
									.background(selectedGame == game ? Color.gray.opacity(0.3) : Color.clear)
									.id(game)

								Spacer()

								Button {
									if let index = consoles.firstIndex(where: { $0.id == selectedConsole?.id }) {
										consoles[index].games = GameLibrary.removeGame(game, from: consoles[index].games)
										saveGames(for: consoles[index]) // Save modifications
										selectedConsole = consoles[index] // Refresh view
									}
								} label: {
									Image(systemName: "trash")
										.foregroundColor(.red)
								}
								.accessibilityLabel("Delete \(game)")
								.buttonStyle(.borderless) // Ensure button works in List
							}
						}
						.searchable(text: $searchText)
						.animation(nil, value: searchText)
						.onChange(of: searchText) { _, _ in
							scrollTarget = nil
							selectedGame = nil
						}
						// Keep a stable identity for the list so the search
						// field retains focus while typing.
						.id(console.id)
						.onChange(of: scrollTarget) { newValue, _ in
							if let target = newValue {
								withAnimation {
									proxy.scrollTo(target, anchor: .center)
								}
							}
						}
					}

					Button {
						if let console = selectedConsole,
						   let index = consoles.firstIndex(where: { $0.id == console.id }) {
							saveGames(for: consoles[index]) // Save the displayed game list
						}
					} label: {
						Label("Save Changes", systemImage: "square.and.arrow.down")
					}
					.accessibilityLabel("Save Changes")
					.padding()

					TextField("Enter new game", text: $newGame)
						.textFieldStyle(.roundedBorder)
						.accessibilityLabel("New Game")
						.padding()

					Button {
						let trimmed = newGame.trimmingCharacters(in: .whitespaces)
						guard !trimmed.isEmpty else { return }
						if let index = consoles.firstIndex(where: { $0.id == selectedConsole?.id }) {
							consoles[index].games = GameLibrary.insertGame(trimmed, into: consoles[index].games)
							saveGames(for: consoles[index]) // Save modifications
							newGame = "" // Reset input field
							selectedConsole = consoles[index] // Refresh view
							selectedGame = trimmed
							scrollTarget = trimmed
						}
					} label: {
						Label("Add Game", systemImage: "plus")
					}
					.accessibilityLabel("Add Game")
					.padding()

					Button(action: pickRandomGame) {
						Label("Pick Random Game", systemImage: "die.face.3")
					}
					.accessibilityLabel("Pick Random Game")
					.padding()

					VStack(alignment: .leading, spacing: 10) {
						VStack(alignment: .leading, spacing: 8) {
							Text("Printout")
								.font(.caption)
								.foregroundStyle(.secondary)

							PaperSlipView(text: printoutText())
								.onLongPressGesture(minimumDuration: 0.3) {
									tearOffRandomPick()
								}

							Button("Tear Off", action: tearOffRandomPick)
								.disabled(randomGame == nil)
						}

						if !randomHistory.isEmpty {
							Text("History")
								.font(.headline)
							ForEach(randomHistory.suffix(5), id: \.self) { entry in
								Text(entry)
							}
						}
					}
					.frame(maxWidth: .infinity,
						   minHeight: randomSectionHeight,
						   maxHeight: randomSectionHeight,
						   alignment: .topLeading)
					.padding(.horizontal)
					.padding(.bottom)
					}
					.overlay {
						paperCanvas
					}
				}
				.navigationTitle(console.name)
			} else {
				Text("Select a console")
			}
		}
	}

	private var paperCanvas: some View {
		GeometryReader { proxy in
			Color.clear
				.allowsHitTesting(false)
				.onAppear {
					canvasSize = proxy.size
				}
				.onChange(of: proxy.size) { newValue, _ in
					canvasSize = newValue
				}

			ForEach(papers) { paper in
				PaperSlipView(text: paper.text)
					.position(x: paper.x, y: paper.y)
					.rotationEffect(.degrees(paper.rotation))
					.gesture(
						DragGesture()
							.onChanged { value in
								if draggingPaperId != paper.id {
									bringPaperToFront(paper.id)
									draggingPaperId = paper.id
								}
								updatePaperPosition(id: paper.id, location: value.location)
							}
							.onEnded { _ in
								draggingPaperId = nil
								savePapers()
							}
					)
					.contextMenu {
						Button("Remove", role: .destructive) {
							removePaper(id: paper.id)
						}
					}
			}
		}
	}

	private func printoutText() -> String {
		guard let game = randomGame else {
			return "Pick a random game to print."
		}
		if let consoleName = randomGameConsoleName ?? selectedConsole?.name {
			return "\(consoleName): \(game)"
		}
		return game
	}

	private func baseDirectory() -> URL? {
		let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
		return documents?.appendingPathComponent("NavJack Software/Random Game Picker/Save Data")
	}

	private func saveGames(for console: Console) {
		guard let base = baseDirectory() else { return }
		let fileURL = base.appendingPathComponent("\(console.name).txt")
		do {
			try GamePersistence.saveGames(console.games, to: fileURL)
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
			loadPapers()
		} catch {
			print("Error loading consoles: \(error)")
		}
	}

	// Load game list from a text file
	private func loadGames(for fileName: String) -> [String]? {
		let fileManager = FileManager.default
		let docURL = baseDirectory()?.appendingPathComponent(fileName)
		// User-edited lists in Documents override bundled defaults.
		if let docURL = docURL, fileManager.fileExists(atPath: docURL.path) {
			do {
				return try GamePersistence.loadGames(from: docURL)
			} catch {
				print("Error reading file \(fileName) from Documents: \(error)")
			}
		}

		if let path = Bundle.main.path(forResource: fileName.replacingOccurrences(of: ".txt", with: ""), ofType: "txt") {
			do {
				let content = try String(contentsOfFile: path, encoding: .utf8)
				return GameLibrary.parseGames(from: content)
			} catch {
				print("Error reading file \(fileName): \(error)")
			}
		}
		return nil
	}

	// Pick a random game
	private func pickRandomGame() {
		guard let games = selectedConsole?.games, let consoleName = selectedConsole?.name else { return }
		var rng = SystemRandomNumberGenerator()
		if let pick = GameLibrary.pickRandomGame(from: games, using: &rng) {
			// Only move the previous pick into history once a new pick happens.
			if let previousGame = randomGame, let previousConsole = randomGameConsoleName {
				randomHistory.append("\(previousConsole): \(previousGame)")
			}

			randomGame = pick
			randomGameConsoleName = consoleName
			saveRandomHistory()
		}
	}

	private func tearOffRandomPick() {
		guard let game = randomGame else { return }
		let consoleName = randomGameConsoleName ?? selectedConsole?.name ?? "Unknown Console"
		addPaper(text: "\(consoleName): \(game)")
		paperTearSound.play()
		randomGame = nil
		randomGameConsoleName = nil
	}

	private func saveRandomHistory() {
		guard let url = baseDirectory()?.appendingPathComponent("RandomPickHistory.txt") else { return }
		try? GamePersistence.saveHistory(randomHistory, to: url)
	}

	private func loadRandomHistory() {
		guard let url = baseDirectory()?.appendingPathComponent("RandomPickHistory.txt") else { return }
		if let history = try? GamePersistence.loadHistory(from: url) {
			randomHistory = history
		}
	}

	private func papersURL() -> URL? {
		return baseDirectory()?.appendingPathComponent("Papers.json")
	}

	private func savePapers() {
		guard let url = papersURL() else { return }
		try? GamePersistence.savePapers(papers, to: url)
	}

	private func loadPapers() {
		guard let url = papersURL(),
			  let loaded = try? GamePersistence.loadPapers(from: url) else { return }
		papers = loaded
	}

	private func addPaper(text: String) {
		let size = canvasSize == .zero ? CGSize(width: 600, height: 400) : canvasSize
		let x = clamp(value: size.width * 0.5 + CGFloat.random(in: -60...60), min: 40, max: size.width - 40)
		let y = clamp(value: size.height * 0.25 + CGFloat.random(in: -40...40), min: 40, max: size.height - 40)
		let rotation = Double.random(in: -2.0...2.0)
		papers.append(PaperSlip(text: text, x: Double(x), y: Double(y), rotation: rotation))
		savePapers()
	}

	private func updatePaperPosition(id: UUID, location: CGPoint) {
		guard let index = papers.firstIndex(where: { $0.id == id }) else { return }
		let x = clamp(value: location.x, min: 20, max: canvasSize.width - 20)
		let y = clamp(value: location.y, min: 20, max: canvasSize.height - 20)
		papers[index].x = Double(x)
		papers[index].y = Double(y)
	}

	private func bringPaperToFront(_ id: UUID) {
		guard let index = papers.firstIndex(where: { $0.id == id }) else { return }
		let paper = papers.remove(at: index)
		papers.append(paper)
	}

	private func removePaper(id: UUID) {
		guard let index = papers.firstIndex(where: { $0.id == id }) else { return }
		papers.remove(at: index)
		savePapers()
	}

	private func clamp(value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
		return Swift.min(Swift.max(value, minValue), maxValue)
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
