# FAQ

## What does EVA stand for?

Ephemeral Voice Agent. It's a real-time voice interaction system where sessions are temporary by design.

## Do I need all three API keys?

No. Only `OPENAI_API_KEY` is required. It's used for Whisper (speech-to-text), GPT-4 (LLM), and OpenAI TTS. The Anthropic key adds Claude as a fallback LLM, and the ElevenLabs key gives you better TTS voices. Both are optional.

## What happens when a session expires?

The session object gets removed from memory. All conversation history for that session is gone. There's no database, no disk writes. This is intentional.

## Can I change the session timeout?

Yes. Edit `ServerConfig.session_timeout` in `src/core/config.py`. Default is 1800 seconds (30 minutes). The cleanup task runs every 5 minutes (`SessionManager.start_cleanup_task()`).

## Why are there two servers on two ports?

FastAPI serves the REST API on port 8000. The `websockets` library runs a separate WebSocket server on port 8001. They share the same session manager and event bus. The WebSocket port is `config.server.port + 1`.

## Can I use only the text chat without voice?

Yes. Just use the `POST /chat` endpoint. You don't need PyAudio, WebRTC VAD, or a microphone. The voice pipeline is only triggered through WebSocket audio messages.

## What audio format does the browser send?

WebM. The browser's `MediaRecorder` captures audio as `audio/webm`, which gets base64-encoded and sent over WebSocket. The Whisper API accepts WebM directly.

## How does the LLM fallback work?

`LLMClient` holds an ordered list of providers (configured in `EVAServer._init_ai_clients()`). When you call `complete()` or `stream()`, it tries each provider in order. If the first one throws an exception, it moves to the next. If all fail, it raises.

## Can I add my own LLM provider?

Yes. Subclass `LLMProvider` in `src/ai/llm_client.py`. Implement `complete()` (returns `LLMResponse`) and `stream()` (yields string chunks). Then add your provider to the list in `src/api/server.py`.

## Where is the conversation history stored?

In memory, inside `ConversationAgent.contexts` (a dict keyed by session_id). Each `ConversationContext` holds a list of messages capped at 20. When the session ends, the context gets deleted.

## Why is the `/transcribe` endpoint a stub?

The full transcription pipeline works through WebSocket (audio comes in, gets transcribed by Whisper, processed through LLM, and synthesized back). The REST endpoint for standalone transcription was planned but not finished in v0.0.1.

## Does EVA store any data to disk?

No. All session data, conversation history, and audio processing happens in memory. The only disk I/O is log files (if configured) and the static frontend files. Audio data is sent to third-party APIs (OpenAI, ElevenLabs) for processing.

## What's the `server_update.py` file?

It's a code snippet (not an importable module) showing how to wire the `AudioProcessor` into `server.py`. It demonstrates adding the Transcriber and AudioProcessor to the EVAServer initialization.
