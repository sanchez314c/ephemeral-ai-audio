# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.0.1   | Yes       |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

**Do not open a public GitHub issue for security vulnerabilities.**

Instead, email the maintainer directly. Include:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if you have one)

You should receive an acknowledgment within 48 hours. We'll work with you to understand and address the issue before any public disclosure.

## Security Considerations

- **Ephemeral sessions**: All session data expires after 30 minutes and is not persisted to disk
- **API keys**: Stored in environment variables or `.env` files, never committed to source control
- **No authentication**: The current version does not include API authentication. Do not expose the server to the public internet without adding your own auth layer
- **WebSocket connections**: Not authenticated in the current version. Treat this as a local development tool, not a production service
- **Audio data**: Processed in memory only. Audio is sent to third-party APIs (OpenAI, ElevenLabs) for transcription and synthesis
