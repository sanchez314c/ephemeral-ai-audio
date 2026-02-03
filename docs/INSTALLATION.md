# Installation

## Prerequisites

- Python 3.9+
- Conda (Miniconda or Anaconda)
- At least one API key: OpenAI (required for core functionality)
- Optional: Anthropic API key (LLM fallback), ElevenLabs API key (TTS)

## Setup

### 1. Clone and Navigate

```bash
git clone https://github.com/sanchez314c/EphemeralAiAudio.git
cd EphemeralAiAudio/EphemeralAiAudio_v0.0.1
```

### 2. Create Conda Environment

```bash
conda create -p ./conda_env python=3.11 -y
conda activate ./conda_env
```

### 3. Install Dependencies

```bash
pip install fastapi uvicorn websockets openai anthropic elevenlabs
pip install numpy scipy pyaudio webrtcvad
pip install python-dotenv pydantic
pip install pytest pytest-asyncio httpx  # for testing
```

If PyAudio fails to install, install PortAudio first:

```bash
# Ubuntu/Debian
sudo apt-get install portaudio19-dev

# macOS
brew install portaudio
```

### 4. Configure Environment

Create a `.env` file in the project root:

```bash
OPENAI_API_KEY=sk-your-openai-key
ANTHROPIC_API_KEY=sk-ant-your-anthropic-key  # optional
ELEVENLABS_API_KEY=your-elevenlabs-key        # optional
DEBUG=false
LOG_LEVEL=INFO
```

### 5. Verify Installation

```bash
python3 -m src.api.server
```

The server should start on:
- HTTP: http://localhost:8000
- WebSocket: ws://localhost:8001

Open http://localhost:8000 in your browser to see the web UI.

## Quick Verify

```bash
# Health check
curl http://localhost:8000/health

# Create a session
curl -X POST http://localhost:8000/sessions

# Run the demo
python3 demo.py
```
