# Build and Compile

EVA is a Python project. There's no compilation step, but the environment setup and dependency installation serve the same role.

## Environment Setup

EVA uses Conda for environment management with a local prefix:

```bash
conda create -p ./conda_env python=3.11 -y
conda activate ./conda_env
```

## Dependency Installation

No `requirements.txt` is bundled (dependencies are installed manually):

```bash
# Core server
pip install fastapi uvicorn websockets pydantic python-dotenv

# AI providers
pip install openai anthropic elevenlabs

# Audio processing
pip install numpy scipy pyaudio webrtcvad

# Testing
pip install pytest pytest-asyncio httpx
```

### System Dependencies

PyAudio requires PortAudio headers at install time:

```bash
# Ubuntu/Debian
sudo apt-get install portaudio19-dev

# macOS
brew install portaudio

# Windows
# PyAudio ships pre-built wheels on Windows, no extra steps needed
```

## Run Scripts

Cross-platform launch scripts are in `EphemeralAiAudio_v0.0.1/scripts/`:

| Script | Platform | What it does |
|--------|----------|-------------|
| `run-source.sh` | Any | Auto-detects OS, delegates to platform script |
| `run-source-linux.sh` | Linux | Checks deps, starts `python3 -m src.api.server` |
| `run-source-macos.sh` | macOS | Same as Linux script |
| `run-source-windows.bat` | Windows | Windows batch equivalent |

### Script Commands

```bash
bash scripts/run-source-linux.sh           # Start the server
bash scripts/run-source-linux.sh install   # Install dependencies
bash scripts/run-source-linux.sh dev       # Start in dev mode (same as default)
```

## Test Runner

```bash
bash run_tests.sh
```

This script:
1. Activates the conda environment
2. Runs `pytest tests/ -v --tb=short`
3. Runs `demo.py`

## No Build Artifacts

EVA runs directly from source. There's no build output directory, no compiled assets, and no packaging step. The static frontend (`src/api/static/index.html` and `src/api/static/app.js`) is served directly by FastAPI's `StaticFiles` mount.

## Packaging (Future)

If packaging becomes needed:
- **Docker**: Containerize with a Python 3.11 base image, install deps, expose ports 8000 and 8001
- **PyPI**: Would need a `setup.py` or `pyproject.toml` (not yet created)
- **Standalone**: Could use PyInstaller, but the external API dependencies make this impractical
