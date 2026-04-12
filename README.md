# EVA - Ephemeral Voice Agent

A real-time voice interaction system that runs ephemeral, context-aware conversations using AI. Talk to it through your browser mic, or just type. Sessions are temporary by design -- nothing gets stored, everything expires.

## What It Does

EVA captures audio from the browser, transcribes it with OpenAI Whisper, sends the text through an LLM (GPT-4 or Claude), converts the response to speech, and plays it back. The whole round-trip happens over WebSocket in near real-time.

You can also skip the voice part and just use the text chat via the REST API.

## Features

- **Voice conversations** -- hold-to-talk mic input from the browser, audio response played back automatically
- **Text chat** -- REST endpoint for plain text conversations with the same AI backend
- **Multi-provider LLM** -- OpenAI GPT-4 as primary, Anthropic Claude as fallback. If one fails, the next one picks up
- **Multi-provider TTS** -- ElevenLabs and OpenAI TTS, selectable per request
- **Speech-to-text** -- OpenAI Whisper API for transcription
- **Voice Activity Detection** -- WebRTC VAD on 30ms audio chunks to detect when someone's actually talking
- **Audio enhancement** -- bandpass filter for voice frequencies (80Hz-8kHz), noise gate, spectral subtraction
- **Ephemeral sessions** -- 30-minute TTL, auto-cleanup every 5 minutes, no persistence
- **Event-driven architecture** -- async pub/sub event bus keeps components decoupled
- **Web UI** -- minimal browser interface with chat display and voice recording button

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | Python 3.11 |
| REST API | FastAPI + uvicorn |
| WebSocket | websockets library |
| LLM | OpenAI GPT-4, Anthropic Claude |
| Speech-to-text | OpenAI Whisper |
| Text-to-speech | ElevenLabs, OpenAI TTS |
| Audio processing | NumPy, SciPy, PyAudio, WebRTC VAD |
| Config | python-dotenv, dataclasses |
| Frontend | Vanilla HTML/JS (single page) |
| Environment | Conda |

## Architecture

```
Browser (Web UI)
    |
    |-- REST API (FastAPI, port 8000)
    |       |-- POST /sessions        create ephemeral session
    |       |-- GET  /sessions/:id    get session info
    |       |-- DELETE /sessions/:id  terminate session
    |       |-- POST /chat            text conversation
    |       |-- POST /synthesize      text-to-speech
    |       |-- POST /transcribe      speech-to-text
    |       |-- GET  /health          health check
    |
    |-- WebSocket (port 8001)
            |-- audio_chunk           mic audio from browser
            |-- audio_response        synthesized speech back to browser
            |-- control               start/stop recording signals
```

### Voice Pipeline

```
Mic -> MediaRecorder (WebM) -> base64 -> WebSocket -> Whisper STT -> LLM -> TTS -> base64 audio -> WebSocket -> Browser playback
```

### Module Layout

```
EphemeralAiAudio_v0.0.1/
  src/
    core/
      config.py             Dataclass configs (AudioConfig, AIConfig, ServerConfig)
      event_bus.py           Async pub/sub event queue
      session_manager.py     Ephemeral sessions with UUID + TTL

    audio/
      audio_buffer.py        Thread-safe circular buffer (numpy-backed)
      audio_enhancer.py      DSP: normalize, bandpass, noise gate, spectral subtraction
      stream_processor.py    Real-time mic capture + WebRTC VAD
      transcriber.py         OpenAI Whisper wrapper

    ai/
      llm_client.py          Multi-provider LLM with sequential fallback
      conversation_agent.py  Per-session conversation history (capped at 20 messages)
      tts_client.py          Multi-provider TTS with named provider selection

    api/
      server.py              Main entry point, spins up HTTP + WS servers
      rest_api.py            FastAPI route definitions
      websocket_handler.py   WebSocket connection manager
      audio_processor.py     Full pipeline orchestrator (STT -> LLM -> TTS)
      static/
        index.html           Web UI
        app.js               Frontend logic
```

## Installation

### Prerequisites

- Python 3.9+ (3.11 recommended)
- Conda (Miniconda or Anaconda)
- An OpenAI API key (required)
- Optional: Anthropic API key (LLM fallback), ElevenLabs API key (better TTS voices)

### Setup

1. Clone and navigate to the project:

```bash
git clone https://github.com/sanchez314c/EphemeralAiAudio.git
cd EphemeralAiAudio/EphemeralAiAudio_v0.0.1
```

2. Create the Conda environment:

```bash
conda create -p ./conda_env python=3.11 -y
conda activate ./conda_env
```

3. Install dependencies:

```bash
pip install fastapi uvicorn websockets openai anthropic elevenlabs
pip install numpy scipy pyaudio webrtcvad
pip install python-dotenv pydantic
```

If PyAudio fails, install PortAudio first:

```bash
# Ubuntu/Debian
sudo apt-get install portaudio19-dev

# macOS
brew install portaudio
```

4. Configure your API keys. Create a `.env` file in the `EphemeralAiAudio_v0.0.1/` directory:

```
OPENAI_API_KEY=sk-your-openai-key
ANTHROPIC_API_KEY=sk-ant-your-anthropic-key
ELEVENLABS_API_KEY=your-elevenlabs-key
DEBUG=false
LOG_LEVEL=INFO
```

Or export them directly:

```bash
export OPENAI_API_KEY="sk-your-key"
```

## Usage

### Start the Server

```bash
cd EphemeralAiAudio_v0.0.1
python -m src.api.server
```

Or use the run script:

```bash
bash scripts/run-source-linux.sh
```

This starts:
- **REST API** at http://localhost:8000
- **WebSocket** at ws://localhost:8001
- **Web UI** at http://localhost:8000 (served from the REST API)
- **Swagger docs** at http://localhost:8000/docs

### Quick Test

```bash
# Health check
curl http://localhost:8000/health

# Create a session
curl -X POST http://localhost:8000/sessions -H "Content-Type: application/json" -d '{}'

# Send a chat message (use the session_id from above)
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"session_id": "YOUR_SESSION_ID", "message": "Hello, EVA"}'
```

### Run the Demo

A standalone script that runs a quick text conversation without the server:

```bash
python demo.py
```

### WebSocket Protocol

Connect to `ws://localhost:8001`. On connect, you'll get a session automatically.

Send audio:
```json
{"type": "audio_chunk", "audio": "<base64_encoded_audio>"}
```

Control recording:
```json
{"type": "control", "action": "start_recording"}
{"type": "control", "action": "stop_recording"}
```

Responses come back as:
```json
{
  "type": "audio_response",
  "transcript": "what the user said",
  "response_text": "what the AI replied",
  "audio": "<base64_encoded_mp3>"
}
```

## Configuration

All config is handled through environment variables and dataclasses in `src/core/config.py`.

| Variable | Required | Default | What it does |
|----------|----------|---------|-------------|
| `OPENAI_API_KEY` | Yes | -- | Used for Whisper STT, GPT-4, and OpenAI TTS |
| `ANTHROPIC_API_KEY` | No | -- | Enables Claude as LLM fallback |
| `ELEVENLABS_API_KEY` | No | -- | Enables ElevenLabs TTS voices |
| `DEBUG` | No | `false` | Debug mode |
| `LOG_LEVEL` | No | `INFO` | Python logging level |

Audio defaults: 16kHz sample rate, mono, 16-bit. Sessions expire after 30 minutes.

## Testing

```bash
# Install test dependencies
pip install pytest pytest-asyncio httpx

# Run the test suite
bash run_tests.sh

# Or run pytest directly
pytest tests/ -v
```

Tests cover session management, event bus pub/sub, and audio buffer operations. External API calls are mocked.

## API Reference

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/sessions` | POST | Create a new ephemeral session |
| `/sessions/{id}` | GET | Get session info |
| `/sessions/{id}` | DELETE | Terminate a session |
| `/sessions/{id}/history` | GET | Get conversation history |
| `/chat` | POST | Send a text message, get AI response |
| `/synthesize` | POST | Convert text to speech audio |
| `/transcribe` | POST | Convert audio to text |

Full interactive docs available at http://localhost:8000/docs when the server is running.

## Documentation

- [Architecture](docs/ARCHITECTURE.md) - System design, data flow, component map
- [Installation](docs/INSTALLATION.md) - Full setup guide
- [Development](docs/DEVELOPMENT.md) - Dev environment, code conventions, extension guides

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, workflow, code conventions, and PR checklist.

## License

MIT -- see [LICENSE](LICENSE) for details.

Copyright (c) 2026 Jason Paul Michaels
