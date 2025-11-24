# AGENTS.md - AI Agent Integration Guide

## Overview

This document describes how AI coding agents should interact with the EVA codebase. It covers entry points, key files, testing strategy, and conventions to follow.

## Entry Points

### Starting the Application

The main entry point is `src/api/server.py`. The `main()` function at the bottom loads config from environment variables, creates an `EVAServer` instance, and calls `run_forever()`. This spins up both the FastAPI HTTP server (port 8000) and the WebSocket server (port 8001).

```bash
python -m src.api.server
```

### Running Tests

```bash
bash run_tests.sh
# or directly:
pytest tests/ -v --tb=short
```

### Running the Demo

```bash
python demo.py
```

This runs a standalone text conversation through the LLM without starting the server. Good for verifying AI client wiring.

## Key Files to Understand First

1. **`src/core/config.py`** - All configuration lives here as dataclasses. `Config.from_env()` is the factory method.
2. **`src/api/server.py`** - `EVAServer.__init__()` wires everything together: session manager, event bus, LLM providers, TTS providers, conversation agent, WebSocket handler, REST API.
3. **`src/api/rest_api.py`** - `create_rest_api()` is a FastAPI app factory. All HTTP endpoints are defined here.
4. **`src/api/websocket_handler.py`** - `WebSocketHandler` manages connections and routes messages by type.
5. **`src/api/audio_processor.py`** - `AudioProcessor.process_audio_message()` is the full voice pipeline: STT -> LLM -> TTS.

## Testing Strategy

Tests are in the `tests/` directory using pytest with pytest-asyncio for async functions.

- **`test_session_manager.py`** - Session CRUD: create, retrieve, expire, extend, terminate
- **`test_event_bus.py`** - Pub/sub: single handler, multiple handlers
- **`test_audio_processor.py`** - Audio normalization, buffer read/write, circular wrap behavior
- **`test_integration.py`** - WebSocket connection test, text chat round-trip (requires running server), component existence checks

External API calls (OpenAI, Anthropic, ElevenLabs) should always be mocked in tests. Unit tests should never require real API keys.

## Conventions

### Code Style

- Python PEP 8, enforced by `black` and `flake8`
- Type hints on all public function signatures
- `async/await` for anything that does I/O
- Logging via Python's `logging` module, one logger per module (`logger = logging.getLogger(__name__)`)
- No `print()` statements in production code

### Architecture Patterns

- **Provider pattern**: LLM and TTS clients use abstract base classes (`LLMProvider`, `TTSProvider`). Concrete implementations wrap specific APIs. The client classes (`LLMClient`, `TTSClient`) manage provider selection and fallback.
- **Event bus**: Components communicate through `EventBus.emit()` and `EventBus.subscribe()`. Events carry a type string, arbitrary data, and an optional session_id.
- **Session scoping**: Every interaction is tied to a session ID. Sessions are ephemeral (30-min TTL). Conversation history is per-session.
- **App factory**: The FastAPI app is created by `create_rest_api()`, which takes the session manager, conversation agent, and TTS client as arguments. This makes testing easier.

### Module Boundaries

- `src/core/` has no external API dependencies. It's pure infrastructure.
- `src/audio/` depends on NumPy, SciPy, PyAudio, WebRTC VAD, and OpenAI (for Whisper).
- `src/ai/` depends on the OpenAI and Anthropic SDKs, plus ElevenLabs.
- `src/api/` depends on everything above. It's the orchestration layer.

### Adding New Components

- New audio processing: add to `src/audio/`, import in `src/audio/__init__.py`
- New AI provider: subclass the abstract provider in the appropriate file under `src/ai/`
- New API endpoint: add to `create_rest_api()` in `src/api/rest_api.py`
- New WebSocket message type: add handler branch in `WebSocketHandler._handle_message()`
- New tests: create `tests/test_<component>.py`, use `@pytest.mark.asyncio` for async tests

### Environment

- Conda environment at `./conda_env` (local prefix, not named)
- Required: `OPENAI_API_KEY` environment variable
- Optional: `ANTHROPIC_API_KEY`, `ELEVENLABS_API_KEY`
- Config loaded via `python-dotenv` from `.env` file in project root

### What Not to Do

- Don't add persistent storage. Ephemeral is the whole point.
- Don't commit API keys or `.env` files.
- Don't use synchronous blocking calls inside async handlers.
- Don't bypass the provider abstraction by calling OpenAI/Anthropic SDKs directly from the API layer.
