#!/bin/bash
source ~/miniconda3/etc/profile.d/conda.sh

# DevOps Agent 001 - Environment Setup
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DevOps Agent 001 starting..."

# Navigate to project root
cd /Volumes/mpRAID/Development/Projects/EphemeralAIAudio

# Create self-contained Conda environment
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating self-contained Conda environment..."
conda create -p ./conda_env python=3.11 -y

# Activate the environment
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Activating Conda environment..."
conda activate ./conda_env

# Install required packages
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Installing required packages..."
conda install -c conda-forge -y \
    numpy \
    scipy \
    librosa \
    soundfile \
    pyaudio \
    websockets \
    aiohttp \
    pydantic \
    python-dotenv \
    pytest \
    black \
    flake8 \
    mypy

# Install additional pip packages
pip install \
    openai \
    anthropic \
    elevenlabs \
    webrtcvad \
    python-multipart \
    uvicorn \
    fastapi \
    redis \
    celery

# Sanitize file permissions
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sanitizing file permissions..."
chmod -R u+rwX .
chmod -R -N .

# Create necessary project structure
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating project structure..."
mkdir -p \
    src/core \
    src/audio \
    src/ai \
    src/api \
    src/utils \
    tests \
    configs \
    logs \
    data/audio_cache \
    data/models

# Write completion status
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DevOps Agent 001 completed successfully"
echo "STATUS: COMPLETE"