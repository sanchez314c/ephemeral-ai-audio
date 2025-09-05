# CLAUDE.md - AI Assistant Context

## Project

EVA (Ephemeral Voice Agent) - a real-time voice interaction system that runs ephemeral, context-aware conversations through AI. Audio comes in from a browser mic, gets transcribed, sent through an LLM, synthesized to speech, and played back. Sessions are temporary by design.

## Tech Stack

- **Language**: Python 3.11
- **Environment**: Conda (local prefix `./conda_env`)
- **REST API**: FastAPI + uvicorn (port 8000)
- **WebSocket**: websockets library (port 8001)
- **LLM Providers**: OpenAI GPT-4 (primary), Anthropic Claude (fallback)
- **Speech-to-Text**: OpenAI Whisper API
- **Text-to-Speech**: ElevenLabs, OpenAI TTS
- **Audio DSP**: NumPy, SciPy, PyAudio, WebRTC VAD
- **Config**: python-dotenv, dataclasses
- **Frontend**: Vanilla HTML/JS (single page, served from FastAPI static mount)
- **Testing**: pytest, pytest-asyncio

## File Structure

```
src/
  core/
    config.py             Dataclass configs: AudioConfig, AIConfig, ServerConfig, Config
    event_bus.py           Async pub/sub event queue with subscribe/emit/start/stop
    session_manager.py     Ephemeral sessions with UUID, 30-min TTL, background cleanup

  audio/
    audio_buffer.py        Thread-safe circular numpy buffer with read/write/clear
    audio_enhancer.py      DSP: normalize, bandpass (80Hz-8kHz), noise gate, spectral subtraction
    stream_processor.py    Real-time mic capture + WebRTC VAD on 30ms chunks
    transcriber.py         OpenAI Whisper async wrapper

  ai/
    llm_client.py          Abstract LLMProvider, OpenAIProvider, AnthropicProvider, LLMClient (fallback chain)
    conversation_agent.py  Per-session ConversationContext + history truncation at 20 messages
    tts_client.py          Abstract TTSProvider, ElevenLabsProvider, OpenAITTSProvider, TTSClient

  api/
    server.py              EVAServer class - main entry point, initializes everything, runs HTTP + WS
    rest_api.py            FastAPI factory: /sessions, /chat, /synthesize, /transcribe, /health
    websocket_handler.py   WebSocket connection manager, audio_chunk/control message routing
    audio_processor.py     Pipeline orchestrator: transcribe -> LLM -> TTS -> combined response
    server_update.py       Code snippet showing how to wire AudioProcessor into server.py
    static/
      index.html           Web UI
      app.js               Frontend: session creation, WebSocket, MediaRecorder, audio playback

tests/
  test_audio_processor.py  Audio normalization, buffer write/read, circular wrap
  test_event_bus.py        Event subscription, multiple handlers
  test_session_manager.py  Create, expire, extend, retrieve, terminate sessions
  test_integration.py      WebSocket connect, text chat round-trip, component existence

scripts/
  run-source-linux.sh      Linux launcher with dependency check
  run-source-macos.sh      macOS launcher
  run-source-windows.bat   Windows launcher
  run-source.sh            Generic launcher

demo.py                    Standalone conversation demo (no server needed)
run_tests.sh               Test runner (activates conda, runs pytest + demo)
```

## Build and Run

```bash
# Activate environment
conda activate ./conda_env

# Start the server (REST + WebSocket)
python -m src.api.server

# Or use the script
bash scripts/run-source-linux.sh

# Run tests
bash run_tests.sh

# Run demo (no server needed)
python demo.py
```

## Required Environment Variables

- `OPENAI_API_KEY` - required for Whisper STT, GPT-4, and OpenAI TTS
- `ANTHROPIC_API_KEY` - optional, enables Claude as LLM fallback
- `ELEVENLABS_API_KEY` - optional, enables ElevenLabs TTS
- `DEBUG` - optional, default `false`
- `LOG_LEVEL` - optional, default `INFO`

## Key Design Decisions

- **Ephemeral sessions**: 30-minute TTL, no database, no persistence. Privacy by default.
- **Provider fallback**: LLMClient iterates through configured providers. If OpenAI fails, Anthropic picks up.
- **Event-driven**: Async EventBus decouples audio, AI, and transport layers.
- **Dual server**: Separate HTTP and WebSocket servers for independent protocol handling.
- **Conversation cap**: Message history truncated to 20 messages per session to manage context length.
- **No auth**: Current version is a local dev tool. Not meant for public exposure without adding auth.

## Ports

- 8000: FastAPI REST API + static file serving
- 8001: WebSocket server for real-time audio

## Common Tasks

- **Add an LLM provider**: Subclass `LLMProvider` in `src/ai/llm_client.py`, implement `complete()` and `stream()`, add to provider list in `server.py`
- **Add a TTS provider**: Subclass `TTSProvider` in `src/ai/tts_client.py`, implement `synthesize()` and `stream()`, register in `server.py`
- **Add a REST endpoint**: Add route in `src/api/rest_api.py` inside `create_rest_api()`
- **Add a WebSocket message type**: Handle in `WebSocketHandler._handle_message()` in `src/api/websocket_handler.py`
