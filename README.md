# Galaterm

Galaterm is an arcade-style, top-down space shooter built in Dart using the [nocterm](https://pub.dev/packages/nocterm) TUI (Terminal User Interface) library. It brings classic arcade action to both your terminal and the web, featuring enemy formations, challenging boss fights, and a complete upgrade system.

## Features

- **Classic Arcade Action:** Face off against waves of enemies that dive and attack.
- **Boss Fights:** Encounter powerful boss formations every 5 levels.
- **Mouse Controls:** Smoothly control your ship's movement using your mouse.
- **Upgrades & Progression:** Earn "Galabucks" by defeating enemies and use them to upgrade your ship between levels:
  - **Engines:** Increase your ship's movement speed.
  - **Cannons:** Boost your projectile damage.
  - **Armor:** Increase maximum health.
- **Special Abilities:** Use screen-clearing Bombs (`B`) to escape tight situations.
- **Cross-Platform:** Runs directly in your terminal, and can be compiled to run on the web thanks to Nocterm's web rendering support.

## Controls

* **Mouse Hover/Move:** Move your ship
* **`b`**: Deploy a Bomb
* **`p`**: Pause / Resume the game
* **`q`**: Quit the game

## Getting Started

### Prerequisites

You will need the [Dart SDK](https://dart.dev/get-dart) installed.

### Running in the Terminal

To run the game natively in your terminal:

```bash
dart run bin/galaterm.dart
```

### Running on the Web

To run the game in your browser using Nocterm's web backend:

```bash
# Compile to JavaScript:
dart compile js -O2 -o web/main.dart.js web/main.dart

# Run a local web server in the build directory, for example:
dart pub global run dhttpd --path web/
```
Then, open your browser and navigate to the local server URL (usually `http://localhost:8080/`).

## Project Structure

* `bin/galaterm.dart`: The main entry point for running the game as a terminal application.
* `web/main.dart`: The entry point for compiling and running the game in the browser.
* `web/index.html`: The HTML wrapper for the web build, using xterm.js under the hood.
* `lib/`: Contains the core game logic, state management, and entity definitions:
  * `galaterm.dart`: The main game UI and loop.
  * `player.dart`: Player ship and mechanics.
  * `enemy.dart` & `enemy_formation.dart`: Enemy behaviors and formations.
  * `projectile.dart` & `bomb_projectile.dart`: Weapon and collision logic.
  * `game_state.dart`: Core state and game engine tick logic.

## Built With

* [Dart](https://dart.dev/)
* [Nocterm](https://pub.dev/packages/nocterm) - A robust framework for building terminal UIs and games in Dart.
