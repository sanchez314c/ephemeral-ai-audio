# Deployment

EVA is currently designed as a local development tool. It has no authentication, no rate limiting, and no TLS. Do not expose it directly to the public internet without adding those layers.

## Local Development (Current)

```bash
cd EphemeralAiAudio_v0.0.1
conda activate ./conda_env
python -m src.api.server
```

This starts:
- REST API on `http://0.0.0.0:8000`
- WebSocket on `ws://0.0.0.0:8001`
- Web UI at `http://localhost:8000`

## Environment Variables

Set these before starting the server:

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENAI_API_KEY` | Yes | Whisper STT, GPT-4, OpenAI TTS |
| `ANTHROPIC_API_KEY` | No | Claude LLM fallback |
| `ELEVENLABS_API_KEY` | No | ElevenLabs TTS |
| `DEBUG` | No | Debug mode (default: `false`) |
| `LOG_LEVEL` | No | Python logging level (default: `INFO`) |

Use a `.env` file in the project root, or export them in your shell.

## Ports

| Service | Port | Protocol |
|---------|------|----------|
| REST API | 8000 | HTTP |
| WebSocket | 8001 | WS |

The WebSocket port is hardcoded as `server.port + 1` in `src/api/server.py`.

## Production Considerations

If deploying EVA beyond local use, you'd need to add:

1. **Authentication** - The API currently accepts all requests. Add API key validation or OAuth.
2. **TLS** - Put it behind a reverse proxy (nginx, Caddy) with HTTPS/WSS.
3. **Rate limiting** - No request throttling exists. Add middleware or use the reverse proxy.
4. **CORS lockdown** - Currently set to `allow_origins=["*"]`. Restrict to your domain.
5. **Session limits** - `max_sessions` is set to 100 in `ServerConfig` but not enforced.
6. **Monitoring** - Add health check polling, log aggregation, and error tracking.
7. **Process management** - Use systemd or supervisor to keep the server running.

## Reverse Proxy Example (nginx)

```nginx
upstream eva_api {
    server 127.0.0.1:8000;
}

upstream eva_ws {
    server 127.0.0.1:8001;
}

server {
    listen 443 ssl;
    server_name eva.example.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://eva_api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /ws {
        proxy_pass http://eva_ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## Health Check

```bash
curl http://localhost:8000/health
# {"status": "healthy", "service": "EVA"}
```

## Release Process

No formal release process exists yet. The project uses folder-based versioning (`EphemeralAiAudio_v0.0.1/`). Version bumps are manual.

Steps for a new version:
1. Copy the version folder: `cp -r EphemeralAiAudio_v0.0.1 EphemeralAiAudio_v0.0.2`
2. Update CHANGELOG.md
3. Update VERSION_MAP.md
4. Tag in git: `git tag v0.0.2`
