# MacMouseMover

A minimal macOS menubar app that keeps your Mac awake by sending invisible mouse movements.

## Features

- Menubar-only app (no dock icon, no window)
- Toggle mouse jiggler on/off
- Schedule automatic start/stop times (separate weekday/weekend schedules)
- Tiny 1-pixel movement for reliable wake detection (cursor returns to original position)
- Settings persist across app restarts
- Launch at login option
- Left-click menubar icon to toggle, right-click for settings (Caffeine-style)
- Pause on battery power option (auto-resumes when plugged in)

## Requirements

- macOS 13.0 or later
- Swift 5.9+

## Build & Run

```bash
git clone https://github.com/yourusername/MacMouseMover.git
cd MacMouseMover
swift build
.build/debug/MacMouseMover
```

## Install as App

```bash
swift build -c release
mkdir -p /Applications/MacMouseMover.app/Contents/MacOS
cp .build/release/MacMouseMover /Applications/MacMouseMover.app/Contents/MacOS/
cp Sources/MacMouseMover/Info.plist /Applications/MacMouseMover.app/Contents/
```

Then launch from Applications or Spotlight.

## Usage

- **Left-click** the menubar icon to toggle jiggler on/off
- **Right-click** to open settings

## Permissions

On first run, grant Accessibility permission in **System Settings > Privacy & Security > Accessibility** to allow mouse event posting.

## License

MIT
