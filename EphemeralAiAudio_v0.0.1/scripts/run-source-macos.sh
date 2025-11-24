#!/bin/bash
# macOS run script for EphemeralAudio

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Check if we're in the right directory
if [ ! -f "$PROJECT_DIR/requirements.txt" ]; then
    echo "❌ Error: requirements.txt not found. Please run from project root."
    exit 1
fi

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

# Install dependencies if needed
echo "📦 Checking dependencies..."
python3 -c "import fastapi" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "📦 Installing dependencies..."
    pip3 install -r "$PROJECT_DIR/requirements.txt"
fi

echo "🎤 EphemeralAudio - Starting on macOS..."
echo "📍 Project root: $PROJECT_DIR"
echo "🚀 Command: $@"

# Handle different commands
case "$1" in
    "install")
        echo "📦 Installing dependencies..."
        pip3 install -r "$PROJECT_DIR/requirements.txt"
        ;;
    "dev")
        echo "🔄 Starting development server..."
        cd "$PROJECT_DIR" && python3 -m src.api.server
        ;;
    *)
        echo "▶️  Starting EphemeralAudio server..."
        cd "$PROJECT_DIR" && python3 -m src.api.server
        ;;
esac