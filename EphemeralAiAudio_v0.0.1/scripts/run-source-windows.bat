@echo off
REM Windows batch script for EphemeralAudio

set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%..

echo 🎤 EphemeralAudio - Starting on Windows...
echo 📍 Project root: %PROJECT_DIR%
echo 🚀 Command: %*

REM Check if requirements.txt exists
if not exist "%PROJECT_DIR%\requirements.txt" (
    echo ❌ Error: requirements.txt not found. Please run from project root.
    pause
    exit /b 1
)

REM Check if Python 3 is installed
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Error: Python 3 is not installed. Please install Python 3 first.
    pause
    exit /b 1
)

REM Check if fastapi is installed
python -c "import fastapi" >nul 2>nul
if %errorlevel% neq 0 (
    echo 📦 Installing dependencies...
    pip install -r "%PROJECT_DIR%\requirements.txt"
    if %errorlevel% neq 0 (
        echo ❌ Failed to install dependencies
        pause
        exit /b 1
    )
)

REM Handle different commands
if "%1"=="install" (
    echo 📦 Installing dependencies...
    pip install -r "%PROJECT_DIR%\requirements.txt"
) else if "%1"=="dev" (
    echo 🔄 Starting development server...
    cd /d "%PROJECT_DIR%" && python -m src.api.server
) else (
    echo ▶️  Starting EphemeralAudio server...
    cd /d "%PROJECT_DIR%" && python -m src.api.server
)

pause
