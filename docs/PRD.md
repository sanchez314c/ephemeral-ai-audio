# Product Requirements Document

## What This Is

EVA (Ephemeral Voice Agent) is a real-time voice conversational AI system. Users talk to it through a browser mic or type text, and it responds with both text and synthesized speech. Every session is temporary. Nothing gets saved.

## Why It Exists

Most voice AI demos are either cloud-hosted services with persistent accounts, or simple one-shot speech-to-text tools. EVA fills the gap: a self-hosted, privacy-first voice agent where conversations are disposable. You spin it up, talk to it, and everything disappears when the session ends.

## Target Users

- Developers building voice-enabled applications who need a reference implementation
- Privacy-conscious users who want AI conversations that don't persist anywhere
- Teams evaluating LLM and TTS providers who want to A/B test via the multi-provider architecture

## Core Features

1. **Voice conversations** - Browser mic input, AI-generated speech response, full round-trip over WebSocket
2. **Text chat** - REST API alternative for text-only interaction with the same AI backend
3. **Multi-provider LLM** - OpenAI and Anthropic with automatic failover
4. **Multi-provider TTS** - ElevenLabs and OpenAI TTS, selectable per request
5. **Ephemeral sessions** - 30-minute TTL, no persistence, auto-cleanup
6. **Audio processing** - VAD, noise reduction, bandpass filtering for voice clarity

## Non-Goals

- **User accounts or authentication** - Not a multi-tenant service
- **Persistent conversation history** - Ephemeral is the point
- **Mobile app** - Browser-only for now
- **Custom model training** - Uses existing API providers
- **Multi-language support** - English-focused (Whisper supports other languages but the system prompt is English)
- **Production deployment** - Currently a local dev tool

## Success Criteria

- Voice round-trip completes in under 5 seconds (network + STT + LLM + TTS)
- Text chat responds in under 2 seconds
- Sessions auto-expire without memory leaks
- LLM fallback activates transparently when primary provider fails
- Audio quality is good enough for natural conversation (no clipping, reasonable noise reduction)

## Architecture Constraints

- Single-server deployment (no distributed state)
- In-memory session storage (no database required)
- Stateless audio processing (no files written to disk)
- Provider-agnostic design (easy to swap or add AI providers)
