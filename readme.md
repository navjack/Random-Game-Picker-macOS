# Random Game Picker

## Description

A simple macOS application built with SwiftUI that helps you randomly select a game to play from various classic video game consoles. It loads initial game lists for different systems and allows you to pick a random title from your chosen console.

## Features

*   **Console List:** Displays a list of classic gaming consoles.
*   **Game Lists:** Shows the game library for the selected console.
*   **Random Pick:** Selects a random game from the chosen console's list.
*   **Add/Delete Games:** Allows users to add new games or remove existing ones from a console's list.
*   **Persistent Changes:** User modifications to game lists are saved locally.
*   **Paper Slip Printouts:** Tear off a random pick into a draggable paper slip that persists across launches.

## How it Works

The application initially loads console and game data from `.txt` files included within the app bundle (specifically from the `Systems` directory). When you add or remove games, these changes are saved to corresponding `.txt` files in your user's Documents directory, ensuring your customized lists persist across app launches without modifying the original bundled data. Torn-off paper slips are also saved in the same Documents folder so your layout stays in place.
## License

This project is licensed under the [MIT License](LICENSE).
