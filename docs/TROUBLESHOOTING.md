# Troubleshooting

## PyAudio Installation Fails

**Error:** `portaudio.h: No such file or directory`

PyAudio needs PortAudio development headers at compile time.

```bash
# Ubuntu/Debian
sudo apt-get install portaudio19-dev

# macOS
brew install portaudio

# Then retry
pip install pyaudio
```

## "No LLM providers configured"

**Error:** `ValueError: No LLM providers configured`

The server requires at least one LLM API key. Set `OPENAI_API_KEY` in your environment or `.env` file.

```bash
export OPENAI_API_KEY="sk-your-key"
```

## "No TTS providers configured"

**Error:** `ValueError: No TTS providers configured`

At least one TTS provider needs an API key. Either `OPENAI_API_KEY` (for OpenAI TTS) or `ELEVENLABS_API_KEY`.

## WebSocket Connection Refused

**Symptom:** Browser console shows `WebSocket connection to 'ws://localhost:8001' failed`

1. Check the server is running (`curl http://localhost:8000/health`)
2. Confirm port 8001 is not in use by another process: `lsof -i :8001`
3. The WebSocket server starts on `config.server.port + 1`. If you changed the HTTP port, the WS port moved too.

## Browser Mic Access Denied

**Symptom:** "Microphone access denied" in the UI status bar

- The browser needs permission to access the microphone
- HTTPS is required for mic access on most browsers (except localhost)
- Check browser settings for site permissions

## Audio Playback Silent

**Symptom:** Response text appears but no audio plays

- Click anywhere on the page first. Browsers block autoplay audio until the user interacts with the page
- Check that the TTS provider returned valid audio. Look for errors in server logs
- Verify `AudioContext` state in browser console: `audioContext.state` should be "running"

## Whisper Transcription Returns Empty

**Possible causes:**
- Audio too short (needs at least 0.1 seconds)
- Audio format not recognized (Whisper accepts wav, mp3, webm, ogg, m4a, flac)
- `OPENAI_API_KEY` is invalid or has no Whisper access

## Session Not Found (404)

**Error:** `HTTPException: Session not found`

- Sessions expire after 30 minutes. Create a new one.
- The session ID must match exactly (it's a UUID)
- Check if the cleanup task removed it: look for "Terminated session" in logs

## CORS Errors in Browser

**Symptom:** `Access to fetch blocked by CORS policy`

The server is configured with `allow_origins=["*"]` by default. If you're seeing CORS errors:
- Make sure you're hitting the right port (8000 for REST, not 8001)
- Check that the FastAPI server started without errors

## High Memory Usage

Sessions and conversation contexts live in memory. If many sessions accumulate:
- The cleanup task runs every 5 minutes and removes expired sessions
- Reduce `ServerConfig.max_sessions` or `ServerConfig.session_timeout`
- Restart the server to clear all state

## Debugging

Enable debug logging:

```bash
export LOG_LEVEL=DEBUG
export DEBUG=true
python -m src.api.server
```

This shows event bus emissions, session lifecycle events, and provider-level API call details.
