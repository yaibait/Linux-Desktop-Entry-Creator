#!/bin/bash
# Convenient launch script for Linux Desktop Entry Creator
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.local/bin:$PATH"

if [ "$1" == "--debug" ]; then
    echo "Running in Debug mode via Flutter..."
    cd "$SCRIPT_DIR" && flutter run -d linux
else
    echo "Launching Release build..."
    "$SCRIPT_DIR/build/linux/x64/release/bundle/app_launcher_creator" "$@"
fi
