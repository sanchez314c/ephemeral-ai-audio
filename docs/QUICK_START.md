# Quick Start

Get EVA running in 5 steps.

## 1. Clone

```bash
git clone https://github.com/sanchez314c/EphemeralAiAudio.git
cd EphemeralAiAudio/EphemeralAiAudio_v0.0.1
```

## 2. Create Environment

```bash
conda create -p ./conda_env python=3.11 -y
conda activate ./conda_env
```

## 3. Install Dependencies

```bash
pip install fastapi uvicorn websockets openai anthropic elevenlabs
pip install numpy scipy pyaudio webrtcvad python-dotenv pydantic
```

If PyAudio fails: `sudo apt-get install portaudio19-dev` (Linux) or `brew install portaudio` (macOS), then retry.

## 4. Set API Key

```bash
export OPENAI_API_KEY="sk-your-key"
```

## 5. Start

```bash
python -m src.api.server
```

## Verify

Open `http://localhost:8000` in your browser. You should see the EVA chat interface with a text input and a "Hold to Talk" button.

Quick API test:

```bash
curl http://localhost:8000/health
# {"status": "healthy", "service": "EVA"}
```
