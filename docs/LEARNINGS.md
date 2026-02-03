# Learnings

Development insights and gotchas discovered while building EVA.

## Dual Server Architecture

Running FastAPI and a standalone `websockets` server in the same process requires careful async coordination. The WebSocket server is started with `websockets.serve()` and the HTTP server runs via `uvicorn.Server` in a background task. Both share the same asyncio event loop. If one blocks, the other stalls.

## WebSocket Port Offset

The WebSocket port is hardcoded as `config.server.port + 1`. This means changing the HTTP port also changes the WS port. The frontend JS has the WS port hardcoded to `8001`, so these must stay in sync manually.

## MediaRecorder Format

Browser `MediaRecorder` defaults vary by browser. Chrome defaults to `audio/webm;codecs=opus`, Firefox to `audio/ogg;codecs=opus`. We explicitly set `mimeType: 'audio/webm'` to keep it consistent. Whisper API accepts both.

## Context Window Management

Conversation history is capped at 20 messages per session. Without this cap, long conversations would exceed the LLM's context window and start failing. The truncation happens in `ConversationContext.truncate_history()` before every LLM call.

## Anthropic Message Format

OpenAI and Anthropic have different message formats. OpenAI includes `system` as a message role. Anthropic takes `system` as a separate parameter. The `AnthropicProvider` in `llm_client.py` handles this conversion by extracting the system message from the list.

## PyAudio on Linux

PyAudio requires PortAudio headers (`portaudio19-dev`) to compile. This is the most common installation failure. The run scripts check for `fastapi` as a proxy for "dependencies installed" but don't check PyAudio specifically.

## VAD Chunk Size

WebRTC VAD requires specific chunk durations: 10ms, 20ms, or 30ms. At 16kHz sample rate, 30ms = 480 samples. The `StreamProcessor` uses 480 as `chunk_size`. Using a different chunk size will cause VAD to throw.

## Audio Buffer Thread Safety

The `AudioBuffer` uses a threading lock because `numpy` array operations aren't atomic. The circular buffer handles wrap-around by splitting writes into two parts when they cross the buffer boundary.

## Browser Audio Autoplay

Modern browsers block audio autoplay until the user interacts with the page. The "Hold to Talk" button interaction satisfies this requirement, but if you try to play audio before any user interaction, `AudioContext` will be in "suspended" state.

## ElevenLabs vs OpenAI TTS

ElevenLabs produces more natural-sounding voices but has higher latency and cost. OpenAI TTS is faster and cheaper but sounds more robotic. The multi-provider design lets users switch based on their priorities.

## No Hot Reload

The server doesn't support hot reload. Code changes require a full restart. Adding uvicorn's `--reload` flag would only cover the FastAPI part, not the WebSocket server.
