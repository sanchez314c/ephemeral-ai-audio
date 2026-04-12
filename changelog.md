# Changelog (Detailed)

## 2026-03-14 01:50 — Repo Ship Security Hardening

- Added config key allowlist for session context updates (rest_api.py, websocket_handler.py)
- Fixed raw exception leak in audio_processor.py WebSocket responses
- Added file upload validation on /transcribe: 25MB limit + MIME type check
- Added security headers middleware (X-Content-Type-Options, X-Frame-Options, Referrer-Policy)
- Wired max_sessions config to SessionManager constructor
- Extracted inline SVG to named constants in app.js (innerHTML pattern cleanup)

## 2026-03-14 01:45 — Neo-Noir Glass Monitor Restyle (Web UI)

- Applied Neo-Noir Glass Monitor design system to web UI (index.html + app.js)
- Full design token system: colors, shadows, radii, typography, transitions
- Hero card with ambient gradient mesh and dot particle overlay
- Glass chat card with inner highlight and layered shadows
- Teal gradient user messages, glass-border assistant messages
- Input focus: teal border + glow shadow
- Voice button with recording state (red pulse animation)
- Status bar footer: status dot + text + pipe + message count (left), version in teal (right)
- About modal: app info, version, description, MIT license, GitHub badge, email
- Invisible scrollbars (visible on hover)
- Inter font family with Fira Code for monospace
- SVG mic icon replacing emoji in voice button
- No hardcoded hex colors outside design tokens
- Not an Electron app: skipped frameless window, IPC, drag handle (web-only UI)

## 2026-03-14 01:30 — Repo Audit (Forensic Code Quality + Remediation)

- CRITICAL: Fixed Transcriber sync/async client mismatch (transcriber.py)
- CRITICAL: Fixed CORS wildcard+credentials vulnerability (rest_api.py)
- HIGH: Added 10MB audio payload size validation (websocket_handler.py)
- HIGH: Merged AudioProcessor pipeline into server.py, archived server_update.py
- HIGH: Added max_sessions enforcement to SessionManager
- MEDIUM: Replaced deprecated datetime.utcnow() with datetime.now(timezone.utc) in 3 files
- MEDIUM: Updated LLM model defaults to gpt-4o and claude-sonnet-4-20250514
- MEDIUM: Fixed cleanup task race condition in SessionManager
- MEDIUM: Made WebSocket URL dynamic in frontend app.js
- MEDIUM: Created requirements.txt with pinned dependencies
- MEDIUM: Replaced leaked error details with generic messages in REST API
- Generated AUDIT_REPORT.md with full forensic analysis and remediation log

## 2026-03-14 01:25 — Repo Prep (Structural Compliance)

- Created .editorconfig, .gitignore, .python-version at root
- Created run-source-linux.sh, run-source-mac.sh, run-source-windows.bat at root
- Created archive/, resources/icons/, tests/, legacy/ directories
- Created timestamped backup: archive/20260314_012555.zip
- Added .gitkeep to 5 empty folders in EphemeralAiAudio_v0.0.1/
- Made all .sh scripts executable
- All compliance checks passing

## 2026-03-14 — Documentation Standardization (27-file standard)

- Created 11 missing docs/ files: API.md, BUILD_COMPILE.md, DEPLOYMENT.md, FAQ.md, TROUBLESHOOTING.md, TECHSTACK.md, WORKFLOW.md, QUICK_START.md, LEARNINGS.md, PRD.md, TODO.md
- Updated docs/README.md index to link all 15 docs files
- Updated CHANGELOG.md with v0.1.1 entry
- Created implement.md and changelog.md per project standard
- 27/27 standard documentation files present

## 2026-03-07 23:45 — Documentation to Repo Root

- Created all standard documentation files at the repo root level
- Files reference correct paths into EphemeralAiAudio_v0.0.1/ subdirectory

## 2026-03-07 — v0.1.0 Documentation Standardization

- Rewrote README.md with full project description
- Added CHANGELOG.md, CODE_OF_CONDUCT.md, SECURITY.md, CLAUDE.md, AGENTS.md
- Added docs/ARCHITECTURE.md, docs/INSTALLATION.md, docs/DEVELOPMENT.md
- Expanded CONTRIBUTING.md
- Added GitHub issue templates and PR template
- Fixed LICENSE copyright

## 2025-07-03 — v0.0.1 Initial Release

- Ephemeral session manager with 30-minute TTL
- Async event bus with pub/sub
- Multi-provider LLM client (OpenAI GPT-4, Anthropic Claude)
- Multi-provider TTS client (ElevenLabs, OpenAI)
- Audio processing pipeline (VAD, bandpass filter, noise gate, spectral subtraction)
- WebSocket audio streaming
- FastAPI REST API
- Browser web UI
- Test suite (session manager, event bus, audio buffer)
- Cross-platform launch scripts
