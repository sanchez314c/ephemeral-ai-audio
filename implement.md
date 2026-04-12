# EVA - Implementation Plan

## Project Overview

EVA (Ephemeral Voice Agent) - Real-time voice interaction system with AI-powered ephemeral conversations. Browser-based mic input, Whisper STT, multi-provider LLM (GPT-4/Claude), multi-provider TTS (ElevenLabs/OpenAI), WebSocket audio streaming.

## Current State (v0.0.1)

Core engine complete:
- Ephemeral session manager (30-min TTL, auto-cleanup)
- Async event bus (pub/sub)
- Multi-provider LLM client with fallback (OpenAI + Anthropic)
- Multi-provider TTS client (ElevenLabs + OpenAI)
- Audio processing pipeline (VAD, bandpass filter, noise gate, spectral subtraction)
- WebSocket real-time audio streaming
- FastAPI REST API
- Browser web UI (vanilla HTML/JS)

## Pending Implementation

- Implement `/transcribe` REST endpoint (currently a stub)
- Wire `AudioProcessor` into `server.py` (instructions in `server_update.py`)
- Add API authentication
- Add WebSocket authentication
- Create `requirements.txt` or `pyproject.toml`
- Docker support
- GitHub Actions CI
- Fix `Transcriber` using sync client in async context
- Enforce `max_sessions` limit

## Ideas & Future Features

- Local LLM support (Ollama, llama.cpp)
- Local TTS support (Coqui, Piper)
- Voice selection UI
- Audio level visualization
- Conversation export before session expires
- Response streaming in web UI
- WebSocket reconnection with session resumption
- Multi-language support
