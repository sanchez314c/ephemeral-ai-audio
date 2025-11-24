#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/EphemeralAiAudio_v0.0.1"

echo "=== EVA (Ephemeral Voice Agent) - Linux ==="

# Check conda
if command -v conda &> /dev/null; then
    source ~/miniconda3/etc/profile.d/conda.sh 2>/dev/null || true
    conda activate ./conda_env 2>/dev/null || true
fi

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed."
    exit 1
fi
echo "Python: $(python3 --version)"

# Check dependencies
python3 -c "import fastapi" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Installing dependencies..."
    pip3 install fastapi uvicorn websockets openai anthropic elevenlabs
    pip3 install numpy scipy pyaudio webrtcvad python-dotenv pydantic
fi

# Handle commands
case "$1" in
    "install")
        echo "Installing dependencies..."
        pip3 install fastapi uvicorn websockets openai anthropic elevenlabs
        pip3 install numpy scipy pyaudio webrtcvad python-dotenv pydantic
        pip3 install pytest pytest-asyncio httpx
        ;;
    "test")
        echo "Running tests..."
        python3 -m pytest tests/ -v --tb=short
        ;;
    "demo")
        echo "Running demo..."
        python3 demo.py
        ;;
    *)
        echo "Starting EVA server..."
        echo "  REST API: http://localhost:8000"
        echo "  WebSocket: ws://localhost:8001"
        echo "  Web UI: http://localhost:8000"
        python3 -m src.api.server
        ;;
esac
