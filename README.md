# Timer

A minimalist macOS menu bar timer application with a clean, Apple-style design.

## Features

### Menu Bar Integration
- Shows countdown timer and task description in the menu bar
- Quick access to timer controls via dropdown menu
- Preset buttons for fast timer creation (5m, 10m, 25m)
- Custom timer input with optional task description

### Timer Controls
- **Start**: Set a timer from presets or custom input
- **Pause/Resume**: Toggle timer state
- **Stop**: Cancel the current timer
- When a new timer starts, it replaces any running timer

### Floating Display
- Always-on-top draggable window
- Shows countdown and task description
- Hover to reveal controls
- Position anywhere on screen

### Notifications
- macOS notification when timer completes
- Alarm sound (multiple sounds available)
- Timer auto-clears after alarm finishes

### Customizable Hotkeys
Set global keyboard shortcuts for:
- Start new timer
- Pause/Resume timer
- Stop timer

### Settings
- **Presets**: Add, edit, or remove timer presets
- **Sounds**: Choose from multiple alarm sounds
- **Hotkeys**: Configure global keyboard shortcuts

## Requirements

- macOS 15.0+
- Xcode 16.0+ (for building)

## Building

1. Open `timer-application.xcodeproj` in Xcode
2. Select your development team for code signing
3. Build and run (⌘R)

## Usage

1. Click the timer icon (⏱) in the menu bar
2. Choose a preset or enter a custom time
3. Optionally add a task description
4. Click Start or use a preset button
5. Use "Show Floating Display" for an always-visible timer

## Keyboard Shortcuts

Configure global hotkeys in Settings > Hotkeys. Shortcuts must include at least one modifier key (⌘, ⌃, ⌥, or ⇧).

## License

MIT License
