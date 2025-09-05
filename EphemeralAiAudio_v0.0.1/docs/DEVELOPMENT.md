# Development Guide

## Dev Environment Setup

Follow [Installation](INSTALLATION.md) first, then:

```bash
conda activate ./conda_env
```

## Running the Server

```bash
# From project root
python3 -m src.api.server

# Or use the run script
bash scripts/run-source-linux.sh
```

The server starts two processes:
- FastAPI/uvicorn on port 8000 (REST API + static files)
- WebSocket server on port 8001 (real-time audio)

## Running Tests

```bash
# All tests
bash run_tests.sh

# Unit tests only
pytest tests/ -v

# Specific test file
pytest tests/test_event_bus.py -v

# With coverage
pytest tests/ -v --tb=short
```

## Project Structure

```
src/
  core/           Infrastructure layer
    config.py       Configuration dataclasses (AudioConfig, AIConfig, ServerConfig)
    event_bus.py    Async pub/sub event system
    session_manager.py  Ephemeral session lifecycle (30-min TTL)

  audio/          Audio processing layer
    audio_buffer.py    Thread-safe circular buffer
    audio_enhancer.py  DSP pipeline (normalize, filter, noise gate)
    stream_processor.py  Mic capture + VAD (standalone, not used by server)
    transcriber.py     Whisper API wrapper

  ai/             AI services layer
    llm_client.py       Multi-provider LLM with fallback
    conversation_agent.py  Per-session conversation management
    tts_client.py       Multi-provider text-to-speech

  api/            Server layer
    server.py          Main entry point, orchestrates all components
    rest_api.py        FastAPI routes
    websocket_handler.py  WebSocket connection management
    audio_processor.py    Full audio pipeline orchestrator
    static/            Web frontend (index.html, app.js)
```

## Code Conventions

- **Async/await** for all I/O operations
- **PEP 8** style throughout
- **Type hints** on all function signatures
- **Logging** via Python's `logging` module (no print statements)
- **Dataclasses** for configuration and data transfer
- **Abstract base classes** for provider interfaces (LLM, TTS)
- **Naming**: snake_case for functions/variables, PascalCase for classes

## Adding a New LLM Provider

1. Create a class extending `LLMProvider` in `src/ai/llm_client.py`
2. Implement `generate()` and `generate_stream()` methods
3. Register it in `LLMClient.__init__()` provider list

## Adding a New TTS Provider

1. Create a class extending `TTSProvider` in `src/ai/tts_client.py`
2. Implement `synthesize()` and `synthesize_stream()` methods
3. Register it in `TTSClient.__init__()` provider dict

## Environment Variables

| Variable | Required | Default | Purpose |
|----------|----------|---------|---------|
| OPENAI_API_KEY | Yes | - | Whisper STT, GPT-4, OpenAI TTS |
| ANTHROPIC_API_KEY | No | - | Claude LLM fallback |
| ELEVENLABS_API_KEY | No | - | ElevenLabs TTS |
| DEBUG | No | false | Debug mode |
| LOG_LEVEL | No | INFO | Logging level |

## API Documentation

With the server running, visit http://localhost:8000/docs for the auto-generated Swagger/OpenAPI documentation.
