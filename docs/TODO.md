# TODO

Known issues, planned work, and technical debt.

## Known Issues

- [ ] `/transcribe` REST endpoint is a stub (returns placeholder text). The full transcription pipeline only works through WebSocket
- [ ] `server_update.py` is a code snippet, not an importable module. The AudioProcessor wiring instructions should be merged into `server.py`
- [ ] WebSocket port is hardcoded in the frontend JS (`ws://localhost:8001`) instead of being derived from the page URL
- [ ] `StreamProcessor` (mic capture via PyAudio) is not wired into the server. Audio input comes from the browser, not from server-side mic capture
- [ ] `max_sessions` limit in `ServerConfig` (100) is not enforced anywhere

## Planned Features

- [ ] Implement the `/transcribe` REST endpoint with actual Whisper integration
- [ ] Add API authentication (API key middleware or OAuth)
- [ ] Add WebSocket authentication (token in connection URL or first message)
- [ ] Create a `requirements.txt` or `pyproject.toml` for proper dependency management
- [ ] Add Docker support (Dockerfile + docker-compose)
- [ ] Add GitHub Actions CI (lint, test, type check on push)
- [ ] Support configurable WebSocket port in the frontend
- [ ] Add uvicorn `--reload` support for development

## Technical Debt

- [ ] `server_update.py` should be merged into `server.py` or removed
- [ ] Run scripts reference `requirements.txt` but no such file exists in the project
- [ ] The `AudioEnhancer` noise profile update (`update_noise_profile()`) is never called. Spectral subtraction is effectively disabled
- [ ] No `__init__.py` exports defined in any package (all modules use direct imports)
- [ ] `Transcriber` uses sync `openai.OpenAI` client but is called with `await`, which will block the event loop
- [ ] Integration tests require a running server. They should use `TestClient` from FastAPI or `httpx.ASGITransport`

## Nice to Have

- [ ] WebSocket reconnection with session resumption
- [ ] Voice selection UI in the web interface
- [ ] Audio level visualization in the browser
- [ ] Conversation export before session expires
- [ ] Response streaming in the web UI (currently waits for full response)
- [ ] Support for local LLM providers (Ollama, llama.cpp)
- [ ] Support for local TTS (Coqui, Piper)
