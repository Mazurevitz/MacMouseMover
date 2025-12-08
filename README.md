# MacMouseMover

A lightweight, open-source macOS menubar app that prevents your Mac from going idle and keeps the screen awake.

Useful for presentations, monitoring dashboards, long-running tasks, downloads, video calls, or anytime you need your Mac to stay active without manual interaction.

![MacMouseMover Screenshot](screenshot.jpeg)

## Features

- **Menubar-only** — lives quietly in your menubar, no dock icon or windows
- **One-click toggle** — left-click to turn on/off, right-click for settings
- **Scheduling** — set different schedules for weekdays and weekends
- **Battery-aware** — optionally pause when running on battery power
- **Launch at login** — start automatically when you log in
- **Configurable interval** — choose 30s, 1m, 2m, or 5m between activity
- **Randomization** — optional random variation in timing and movement
- **Prevents screen saver** — uses macOS power assertion to prevent idle sleep
- **Simulates user activity** — keeps the system active for apps that monitor idle state
- **Smart idle detection** — only activates when you're away, never disturbs active use
- **Invisible operation** — tiny movement that returns to original position
- **Persistent settings** — remembers your preferences across restarts

## Privacy & Security

This app is fully open-source. You can inspect every line of code before building. It:

- Collects **no data**
- Makes **no network requests**
- Requires only Accessibility permission (to simulate input)
- Stores settings locally via UserDefaults

## Requirements

- macOS 13.0 (Ventura) or later
- Swift 5.9+ (for building from source)

## Installation

### Download (Easiest)

1. Download `MacMouseMover.zip` from the [Releases](https://github.com/Mazurevitz/MacMouseMover/releases) page
2. Extract and move `MacMouseMover.app` to Applications
3. Right-click the app → **Open** (required once for unsigned apps)
4. Grant Accessibility permission when prompted

### Build from Source

```bash
git clone https://github.com/Mazurevitz/MacMouseMover.git
cd MacMouseMover
swift build -c release
mkdir -p /Applications/MacMouseMover.app/Contents/MacOS
cp .build/release/MacMouseMover /Applications/MacMouseMover.app/Contents/MacOS/
cp Sources/MacMouseMover/Info.plist /Applications/MacMouseMover.app/Contents/
```

Then launch from **Applications** or **Spotlight**.

## Usage

| Action | Result |
|--------|--------|
| Left-click menubar icon | Toggle on/off |
| Right-click menubar icon | Open settings |

## Permissions

**Important:** The app requires Accessibility permission to work. Without it, the app will appear to run but won't actually simulate any activity.

**System Settings → Privacy & Security → Accessibility → Enable MacMouseMover**

If the app isn't working:
1. Remove MacMouseMover from Accessibility list
2. Re-add `/Applications/MacMouseMover.app`
3. Make sure the toggle is ON
4. Restart the app

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## License

MIT License — free to use, modify, and distribute.
