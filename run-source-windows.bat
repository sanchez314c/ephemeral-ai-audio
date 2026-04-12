@echo off
echo === EVA (Ephemeral Voice Agent) - Windows ===

cd /d "%~dp0EphemeralAiAudio_v0.0.1"

REM Check Python
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: Python is not installed.
    pause
    exit /b 1
)

REM Check dependencies
python -c "import fastapi" >nul 2>nul
if %errorlevel% neq 0 (
    echo Installing dependencies...
    pip install fastapi uvicorn websockets openai anthropic elevenlabs
    pip install numpy scipy pyaudio webrtcvad python-dotenv pydantic
)

if "%1"=="install" (
    echo Installing dependencies...
    pip install fastapi uvicorn websockets openai anthropic elevenlabs
    pip install numpy scipy pyaudio webrtcvad python-dotenv pydantic
    pip install pytest pytest-asyncio httpx
) else if "%1"=="test" (
    echo Running tests...
    python -m pytest tests/ -v --tb=short
) else if "%1"=="demo" (
    echo Running demo...
    python demo.py
) else (
    echo Starting EVA server...
    echo   REST API: http://localhost:8000
    echo   WebSocket: ws://localhost:8001
    echo   Web UI: http://localhost:8000
    python -m src.api.server
)

pause
