# Tech Stack

## Runtime

| Technology | Version | Purpose |
|-----------|---------|---------|
| Python | 3.11 | Primary language |
| Conda | Any | Environment management (local prefix `./conda_env`) |

## Server

| Library | Version | Purpose |
|---------|---------|---------|
| FastAPI | Latest | REST API framework with auto-generated OpenAPI docs |
| uvicorn | Latest | ASGI server for FastAPI |
| websockets | Latest | Standalone WebSocket server (not FastAPI's built-in) |
| pydantic | v2 | Request/response validation models |
| python-dotenv | Latest | `.env` file loading for configuration |

FastAPI was chosen for its async support, automatic request validation, and built-in Swagger docs. The WebSocket server uses the `websockets` library directly (not FastAPI's WebSocket support) to run on a separate port for independent scaling.

## AI Providers

| Library | Purpose |
|---------|---------|
| openai | GPT-4 LLM, Whisper STT, OpenAI TTS |
| anthropic | Claude LLM (fallback provider) |
| elevenlabs | ElevenLabs TTS (higher quality voices) |

OpenAI is the primary provider because it covers all three AI services (LLM, STT, TTS) with a single API key. Anthropic Claude is a fallback LLM. ElevenLabs provides better voice quality for TTS but costs more.

## Audio Processing

| Library | Purpose |
|---------|---------|
| numpy | Audio data arrays, buffer operations |
| scipy | Signal processing (Butterworth bandpass filter, median filter) |
| pyaudio | Microphone capture (PortAudio wrapper) |
| webrtcvad | Voice Activity Detection on 30ms audio chunks |

NumPy and SciPy handle the DSP pipeline: normalization, bandpass filtering (80Hz-8kHz for voice frequencies), noise gate, and spectral subtraction. PyAudio captures mic input for the standalone `StreamProcessor` (the browser-based pipeline uses MediaRecorder instead). WebRTC VAD detects speech vs silence in real-time.

## Frontend

| Technology | Purpose |
|-----------|---------|
| HTML5 | Single page UI (`index.html`) |
| Vanilla JavaScript | Client logic (`app.js`) |
| Web Audio API | Audio playback (AudioContext, BufferSource) |
| MediaRecorder API | Browser mic capture (WebM format) |
| WebSocket API | Real-time audio streaming |

No frontend framework. The UI is a single HTML file with inline CSS and a separate JS file. This keeps the frontend dependency-free and easy to modify.

## Testing

| Library | Purpose |
|---------|---------|
| pytest | Test runner |
| pytest-asyncio | Async test support |
| httpx | HTTP client for integration tests |

## System Dependencies

| Dependency | Platform | Required For |
|-----------|----------|-------------|
| PortAudio (`portaudio19-dev`) | Linux/macOS | PyAudio installation |

## Not Used (and why)

- **No database** - Sessions are ephemeral. Memory-only storage is the point.
- **No Docker** - Local dev tool for now. Containerization planned for future.
- **No frontend framework** - Single page doesn't need React/Vue overhead.
- **No message queue** - The async EventBus handles internal pub/sub without external infrastructure.
- **No Redis** - In-memory session storage is sufficient for single-server deployment.
