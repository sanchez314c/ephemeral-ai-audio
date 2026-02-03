# API Reference

EVA exposes a REST API over HTTP and a WebSocket endpoint for real-time audio.

## REST API (port 8000)

Base URL: `http://localhost:8000`

Interactive Swagger docs available at `/docs` when the server is running.

### GET /health

Health check endpoint.

**Response:**
```json
{"status": "healthy", "service": "EVA"}
```

### POST /sessions

Create a new ephemeral session. Sessions expire after 30 minutes.

**Request body (optional):**
```json
{"config": {"key": "value"}}
```

**Response:**
```json
{
  "session_id": "uuid-string",
  "created_at": "2026-03-14T12:00:00",
  "expires_at": "2026-03-14T12:30:00"
}
```

### GET /sessions/{session_id}

Get session info.

**Response:**
```json
{
  "session_id": "uuid-string",
  "created_at": "2026-03-14T12:00:00",
  "expires_at": "2026-03-14T12:30:00",
  "is_active": true
}
```

**Errors:**
- `404` - Session not found or expired

### DELETE /sessions/{session_id}

Terminate a session immediately.

**Response:**
```json
{"status": "terminated"}
```

### POST /chat

Send a text message and get an AI response. Requires an active session.

**Request body:**
```json
{
  "session_id": "uuid-string",
  "message": "Hello, EVA",
  "streaming": false
}
```

**Response (non-streaming):**
```json
{
  "response": "Hello! How can I help you today?",
  "session_id": "uuid-string"
}
```

**Response (streaming):** Server-Sent Events stream. Each event:
```
data: {"chunk": "Hello"}
data: {"chunk": "! How"}
data: {"chunk": " can I help"}
```

**Errors:**
- `404` - Session not found
- `500` - LLM provider error

### POST /synthesize

Convert text to speech audio.

**Request body:**
```json
{
  "text": "Hello world",
  "voice": "alloy",
  "provider": "openai"
}
```

- `voice` - optional, defaults to provider default ("Rachel" for ElevenLabs, "alloy" for OpenAI)
- `provider` - optional, defaults to first configured provider

**Response:** Binary audio data (`audio/mpeg`), returned as a file download.

**Errors:**
- `500` - TTS synthesis error

### POST /transcribe

Convert audio to text. Accepts audio file upload.

**Request:** Multipart form data with `file` field (audio file) and optional `session_id` query param.

**Response:**
```json
{
  "transcription": "transcribed text",
  "session_id": "uuid-string"
}
```

**Note:** This endpoint is a stub in v0.0.1. Full implementation pending.

### GET /sessions/{session_id}/history

Get conversation history for a session.

**Response:**
```json
{
  "session_id": "uuid-string",
  "messages": [
    {"role": "user", "content": "Hello", "timestamp": "2026-03-14T12:01:00"},
    {"role": "assistant", "content": "Hi there!", "timestamp": "2026-03-14T12:01:01"}
  ],
  "created_at": "2026-03-14T12:00:00"
}
```

**Errors:**
- `404` - No conversation context found for session

### GET /

Serves the web UI (index.html) if the static directory exists. Otherwise returns a JSON message pointing to `/docs`.

## WebSocket API (port 8001)

Connect to `ws://localhost:8001`. A session is automatically created on connection.

### Connection

On connect, the server sends:
```json
{
  "type": "session_created",
  "session_id": "uuid-string",
  "timestamp": "2026-03-14T12:00:00"
}
```

### Client Messages

**audio_chunk** - Send recorded audio for processing:
```json
{
  "type": "audio_chunk",
  "audio": "<base64-encoded-audio-bytes>"
}
```

**control** - Start or stop recording:
```json
{"type": "control", "action": "start_recording"}
{"type": "control", "action": "stop_recording"}
```

**config** - Update session configuration:
```json
{
  "type": "config",
  "config": {"key": "value"}
}
```

### Server Messages

**audio_response** - Full pipeline result (STT + LLM + TTS):
```json
{
  "type": "audio_response",
  "transcript": "what the user said",
  "response_text": "what the AI replied",
  "audio": "<base64-encoded-mp3>"
}
```

**error** - Processing error:
```json
{
  "type": "error",
  "message": "error description"
}
```

## Pydantic Request Models

Defined in `src/api/rest_api.py`:

| Model | Fields |
|-------|--------|
| `SessionRequest` | `config: Optional[Dict]` |
| `TranscriptionRequest` | `session_id: str`, `audio_format: str = "wav"` |
| `SynthesisRequest` | `text: str`, `voice: Optional[str]`, `provider: Optional[str]` |
| `ChatRequest` | `session_id: str`, `message: str`, `streaming: bool = False` |

## LLM Response Format

Internal `LLMResponse` dataclass returned by all LLM providers:

| Field | Type | Description |
|-------|------|-------------|
| `content` | `str` | Generated text |
| `model` | `str` | Model identifier used |
| `usage` | `Dict[str, int]` | Token usage (prompt_tokens, completion_tokens, total_tokens) |
| `provider` | `str` | Provider name ("openai" or "anthropic") |
