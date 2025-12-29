# Repository Guidelines

## Project Structure & Module Organization
- `Random Game Picker/` contains the SwiftUI app source and assets.
- `Random Game Picker/ContentView.swift` holds the main UI and game list logic.
- `Random Game Picker/Random_Game_PickerApp.swift` is the app entry point.
- `Random Game Picker/Systems/` holds bundled `.txt` game lists by console.
- `Random Game Picker/Assets.xcassets/` contains the app icon and color assets.
- `Random Game Picker.xcodeproj/` contains Xcode project settings and schemes.

## Build, Test, and Development Commands
- `open "Random Game Picker.xcodeproj"`: open the project in Xcode.
- `xcodebuild -scheme "Random Game Picker" -configuration Debug build`: build from the CLI.
- `xcodebuild -scheme "Random Game Picker" test`: run the XCTest suite.

## Coding Style & Naming Conventions
- Swift files use 4-space indentation and SwiftUI conventions.
- Types and files use `UpperCamelCase` (e.g., `ContentView`, `Console`).
- Variables and functions use `lowerCamelCase` (e.g., `loadConsoles`, `randomGame`).
- Keep view logic in `ContentView.swift` and avoid duplicating file I/O helpers.

## Testing Guidelines
- XCTest lives in `Random Game PickerTests/` and mirrors the main app features.
- Name tests by feature (e.g., `testPickRandomGameDeterministic`) and keep them deterministic.

## Data & Persistence Notes
- Bundled console lists live in `Random Game Picker/Systems/*.txt`.
- User edits are saved to `~/Documents/NavJack Software/Random Game Picker/Save Data/`.
- Torn-off paper slips persist in `~/Documents/NavJack Software/Random Game Picker/Save Data/Papers.json`.
- Keep bundled data read-only and write new data to the Documents path.

## Commit & Pull Request Guidelines
- Use Gitmoji prefixes in commit subjects (e.g., `:bug: Fix search field losing focus`).
- Keep subjects short, imperative, and in present tense.
- For PRs, include a clear description of the change and link related issues.
- If UI behavior changes, include before/after screenshots or a short GIF.
