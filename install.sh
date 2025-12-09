#!/bin/bash
# Install script that preserves Accessibility permissions

APP_PATH="/Applications/MacMouseMover.app"

# Build
swift build -c release

# Create app bundle structure if it doesn't exist (first install only)
if [ ! -d "$APP_PATH" ]; then
    mkdir -p "$APP_PATH/Contents/MacOS"
    cp Sources/MacMouseMover/Info.plist "$APP_PATH/Contents/"
fi

# Kill running instance
pkill -f MacMouseMover 2>/dev/null

# Update only the binary (preserves permissions)
cp .build/release/MacMouseMover "$APP_PATH/Contents/MacOS/"

echo "Installed. Restart with: open $APP_PATH"
