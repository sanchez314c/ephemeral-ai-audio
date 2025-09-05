# Changelog

All notable changes to EVA are documented here.

Format: [Semantic Versioning](https://semver.org/). Dates in YYYY-MM-DD.

---

## v0.0.1 - 2025-07-03

### Initial Release

**Core Engine**
- Ephemeral session manager with 30-minute TTL and background cleanup every 5 minutes
- Async event bus with pub/sub pattern for decoupled component communication
- Dataclass-based configuration with environment variable loading (AudioConfig, AIConfig, ServerConfig)

**Audio Processing**
- Thread-safe circular audio buffer with configurable duration
- Real-time stream processor using PyAudio with WebRTC VAD
- Voice activity detection on 30ms chunks with configurable aggressiveness (0–3)
- Audio enhancer: normalization, bandpass filter (80Hz–8kHz), noise gate, spectral subtraction
- OpenAI Whisper transcriber wrapper (async, supports wav/mp3/webm/ogg)

**AI Integration**
- Multi-provider LLM client: OpenAI GPT-4 with Anthropic Claude fallback
- Multi-provider TTS client: ElevenLabs with OpenAI TTS fallback
- Conversation agent with per-session message history (truncated to 20 messages)
- Configurable system prompt injection per session

**API Gateway**
- FastAPI REST server on port 8000 with CORS support
- WebSocket handler on port 8001 for real-time audio streaming
- Audio pipeline orchestrator (transcribe → chat → synthesize)
- Endpoints: POST /sessions, GET /sessions/{id}, DELETE /sessions/{id}, POST /chat, POST /synthesize, POST /transcribe (stub)
- Browser-based web UI (index.html + app.js) with voice input and chat interface
- Server-Sent Events for streaming chat responses

**Tests**
- Unit tests: session manager, event bus, audio buffer
- Integration tests: WebSocket connection, text chat pipeline

**Scripts**
- Cross-platform launch scripts (Linux, macOS, Windows)
- Demo script for offline conversation testing
- Test runner script

---

## v0.1.0 - 2026-03-07

### Documentation Standardization

- Rewrote README.md from scratch with full project description, architecture diagrams, installation steps, usage examples, WebSocket protocol docs, configuration reference, API reference, and testing instructions
- Added CHANGELOG.md
- Added CODE_OF_CONDUCT.md (Contributor Covenant v2.1)
- Added SECURITY.md with vulnerability reporting policy
- Added docs/ARCHITECTURE.md with system diagram, component map, and data flow walkthrough
- Added docs/INSTALLATION.md with step-by-step setup guide including PortAudio troubleshooting
- Added docs/DEVELOPMENT.md with dev environment setup, project structure, code conventions, and extension guides
- Expanded CONTRIBUTING.md with full setup, workflow, code conventions, module structure, and PR checklist
- Added GitHub issue templates (bug report, feature request) and PR template
- Fixed LICENSE copyright
- Updated CHANGELOG.md with documentation audit entry (2026-03-07)

### Documentation Cleanup (2026-03-07 post-audit)

- Created missing CODE_OF_CONDUCT.md and SECURITY.md (referenced in changelog but not present)
- Fixed inconsistent git clone URL in CONTRIBUTING.md (was lowercase, now matches README)
- Removed em dashes from CHANGELOG.md and CONTRIBUTING.md
- Fixed CONTRIBUTING.md module structure formatting

### 15-File Documentation Standard (2026-03-07 23:30)

- Added CLAUDE.md with full AI assistant context: project purpose, tech stack, file structure, build/run commands, key design decisions, common tasks
- Added AGENTS.md with AI agent integration guide: entry points, key files, testing strategy, conventions, module boundaries, what not to do
- Updated docs/README.md to link to CLAUDE.md and AGENTS.md
- All 15 standard documentation files now present and verified
