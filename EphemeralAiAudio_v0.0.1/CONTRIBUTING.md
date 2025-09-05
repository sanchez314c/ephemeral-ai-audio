# Contributing to EVA

Thanks for taking the time to contribute. Here's how to get started.

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/sanchez314c/EphemeralAiAudio.git
   cd EphemeralAiAudio/EphemeralAiAudio_v0.0.1
   ```

2. Set up the Conda environment (Python 3.11):
   ```bash
   conda create --prefix ./conda_env python=3.11
   conda activate ./conda_env
   pip install fastapi uvicorn websockets pydantic python-dotenv
   pip install openai anthropic elevenlabs
   pip install pyaudio webrtcvad numpy scipy soundfile
   pip install pytest black flake8 mypy
   conda install -c conda-forge librosa
   ```

3. Set required environment variables:
   ```bash
   export OPENAI_API_KEY="your-key"
   export ANTHROPIC_API_KEY="your-key"   # Optional
   export ELEVENLABS_API_KEY="your-key"  # Optional
   ```

4. Verify setup by running the test suite:
   ```bash
   ./run_tests.sh
   ```

## Workflow

1. Fork the repository on GitHub
2. Create a feature branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Make your changes
4. Run linting and formatting:
   ```bash
   black src/ tests/
   flake8 src/ tests/
   mypy src/
   ```
5. Run tests to confirm nothing broke:
   ```bash
   ./run_tests.sh
   ```
6. Commit with a clear message and open a pull request

## Code Conventions

- **Python**: PEP 8 style, enforced by `black` and `flake8`
- **Async**: All I/O-bound code uses `async/await`. Do not mix sync blocking calls into async handlers
- **Type hints**: Required on all public functions and class methods
- **Naming**: Snake case for Python (`audio_buffer`), descriptive names over abbreviations
- **Error handling**: Use structured try/except in async contexts; never swallow exceptions silently
- **Logging**: Use the standard `logging` module with per-module loggers, not `print()`

## Module Structure

```
src/
  core/    Session manager, event bus, config (no external deps)
  audio/   Audio processing components (PyAudio, VAD, filters)
  ai/      LLM and TTS client wrappers
  api/     FastAPI REST server, WebSocket handler, audio pipeline
tests/     pytest unit and integration tests
```

When adding a new component, match the module it belongs to. New audio pipeline components go under `src/audio/`, new AI provider integrations go under `src/ai/`.

## Testing

- Unit tests for new components go in `tests/test_<component>.py`
- Use `pytest-asyncio` for async test functions
- Mock external API calls. Tests should not require real API keys
- Aim for coverage on the happy path and at least one failure/edge case

## Pull Request Checklist

- [ ] Tests pass: `./run_tests.sh`
- [ ] Code formatted: `black src/ tests/`
- [ ] No new linting errors: `flake8 src/ tests/`
- [ ] Type hints present on new public functions
- [ ] CHANGELOG.md updated with your change
- [ ] No API keys or secrets committed

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). Be respectful and constructive.
