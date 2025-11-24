#!/bin/bash
# Universal run script for PROJECT_NAME
# Auto-detects platform and runs appropriate version

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PLATFORM=$(uname -s)

case "$PLATFORM" in
    Darwin)
        echo "🍎 Running on macOS..."
        bash "$SCRIPT_DIR/run-source-macos.sh" "$@"
        ;;
    Linux)
        echo "🐧 Running on Linux..."
        bash "$SCRIPT_DIR/run-source-linux.sh" "$@"
        ;;
    CYGWIN*|MINGW32*|MSYS*|MINGW*)
        echo "🪟 Running on Windows..."
        cmd.exe /c "$SCRIPT_DIR/run-source-windows.bat" "$@"
        ;;
    *)
        echo "❓ Unknown platform: $PLATFORM"
        echo "Falling back to macOS version..."
        bash "$SCRIPT_DIR/run-source-macos.sh" "$@"
        ;;
esac
