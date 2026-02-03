# Development Workflow

## Branching Strategy

Not yet formalized. The project uses a single `main` branch with folder-based versioning (`EphemeralAiAudio_v0.0.1/`).

Recommended workflow for contributions:

1. Fork the repository
2. Create a feature branch from `main`: `git checkout -b feature/your-feature`
3. Make changes
4. Run tests: `bash run_tests.sh`
5. Lint and format: `black src/ tests/ && flake8 src/ tests/`
6. Open a pull request against `main`

## Code Quality Tools

```bash
# Format
black src/ tests/

# Lint
flake8 src/ tests/

# Type check
mypy src/
```

These are not enforced by CI (no CI pipeline exists yet), but they're part of the PR checklist.

## Testing Workflow

```bash
# Run all tests
bash run_tests.sh

# Run specific test file
pytest tests/test_session_manager.py -v

# Run with verbose output
pytest tests/ -v --tb=short
```

Tests are split into:
- **Unit tests**: `test_session_manager.py`, `test_event_bus.py`, `test_audio_processor.py`
- **Integration tests**: `test_integration.py` (requires a running server for WebSocket and HTTP tests)

## Release Process

Manual folder-based versioning:

1. Copy the current version folder with the new version number
2. Update `CHANGELOG.md` with changes
3. Update `VERSION_MAP.md` with the new version entry
4. Tag in git: `git tag v0.0.2`

## CI/CD

No CI/CD pipeline is configured. No `.github/workflows/` directory exists. Adding GitHub Actions for automated testing is a future improvement.

## Local Development Loop

1. Edit source files in `src/`
2. Restart the server (no hot-reload configured)
3. Test via browser UI at `http://localhost:8000` or curl/httpx
4. Run `pytest` to check unit tests
5. Commit when satisfied
