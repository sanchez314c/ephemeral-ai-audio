# Architecture

## Overview

Ephemeral AI Audio (EVA) is a real-time voice conversational AI system built on a modular, event-driven architecture. Audio flows from the browser through a processing pipeline: capture, transcription, LLM conversation, text-to-speech, and playback.

## System Diagram

```
Browser (Web UI)
    |
    |-- REST API (FastAPI, port 8000)
    |       |-- POST /sessions      (create ephemeral session)
    |       |-- POST /chat           (text chat)
    |       |-- POST /synthesize     (TTS)
    |       |-- GET  /health         (health check)
    |       |-- GET  /sessions/:id/history
    |
    |-- WebSocket (port 8001)
            |-- audio_chunk          (browser mic -> server)
            |-- audio_response       (server -> browser speaker)
            |-- control              (start/stop recording)
```

## Component Architecture

```
src/
  core/
    config.py           Dataclass-based config (AudioConfig, AIConfig, ServerConfig)
    event_bus.py         Async pub/sub event system with queue processing
    session_manager.py   Ephemeral sessions (UUID, 30-min TTL, background cleanup)

  audio/
    audio_buffer.py      Thread-safe circular buffer (numpy-backed)
    audio_enhancer.py    DSP pipeline: normalize, bandpass, noise gate, spectral subtraction
    stream_processor.py  Real-time mic capture via PyAudio + WebRTC VAD
    transcriber.py       OpenAI Whisper API wrapper for speech-to-text

  ai/
    llm_client.py        Multi-provider LLM (OpenAI GPT-4, Anthropic Claude) with sequential fallback
    conversation_agent.py  Per-session conversation context management, message history truncation
    tts_client.py        Multi-provider TTS (ElevenLabs, OpenAI) with named provider selection

  api/
    server.py            Main orchestrator - initializes all components, runs HTTP + WS servers
    rest_api.py          FastAPI app factory with all REST routes
    websocket_handler.py WebSocket connection manager, message routing, session auto-creation
    audio_processor.py   Full pipeline: transcribe -> LLM -> TTS, returns combined response
    static/
      index.html         Single-page web UI
      app.js             Frontend logic (MediaRecorder, WebSocket, audio playback)
```

## Data Flow - Voice Interaction

1. Browser captures microphone audio via MediaRecorder (WebM format)
2. Audio chunks sent as base64 over WebSocket (`audio_chunk` message type)
3. WebSocketHandler receives and emits `audio_received` event on EventBus
4. AudioProcessor orchestrates the pipeline:
   - Transcriber sends audio to OpenAI Whisper API for speech-to-text
   - ConversationAgent sends transcript to LLM with conversation history
   - TTSClient synthesizes the LLM response to speech audio
5. Combined response (transcript + response text + base64 audio) sent back via WebSocket
6. Browser decodes base64 audio and plays through speakers

## Data Flow - Text Chat

1. Browser sends POST to `/chat` with session_id and message text
2. ConversationAgent processes through LLM with session's conversation history
3. JSON response returned with the assistant's reply

## Design Decisions

- **Ephemeral Sessions**: No persistent storage. Sessions auto-expire after 30 minutes. Privacy by design.
- **Provider Fallback**: LLMClient tries each configured provider in order. If OpenAI fails, it falls back to Anthropic Claude.
- **Event-Driven**: The EventBus decouples components so audio processing, LLM calls, and TTS can be modified independently.
- **Dual Server**: Separate HTTP (FastAPI/uvicorn) and WebSocket (websockets library) servers allow independent scaling and protocol handling.

## Dependencies

| Library | Purpose |
|---------|---------|
| fastapi | REST API framework |
| uvicorn | ASGI server for FastAPI |
| websockets | WebSocket server |
| openai | Whisper STT, GPT-4 LLM, TTS |
| anthropic | Claude LLM (fallback provider) |
| elevenlabs | ElevenLabs TTS |
| numpy | Audio data manipulation |
| scipy | Signal processing (filters, spectral analysis) |
| pyaudio | Microphone capture (StreamProcessor only) |
| webrtcvad | Voice Activity Detection |
| python-dotenv | Environment variable loading |
