"""Text-to-speech client with multiple providers"""
import asyncio
from typing import Optional, AsyncGenerator, Dict
from abc import ABC, abstractmethod
import logging
import io
from elevenlabs import AsyncElevenLabs

logger = logging.getLogger(__name__)

class TTSProvider(ABC):
    """Abstract base for TTS providers"""
    
    @abstractmethod
    async def synthesize(self, text: str, voice: str) -> bytes:
        """Synthesize speech from text"""
        pass
        
    @abstractmethod
    async def stream(self, text: str, voice: str) -> AsyncGenerator[bytes, None]:
        """Stream synthesized speech"""
        pass

class ElevenLabsProvider(TTSProvider):
    """ElevenLabs TTS provider"""
    
    def __init__(self, api_key: str):
        self.client = AsyncElevenLabs(api_key=api_key)
        self.model_id = "eleven_monolingual_v1"
        
    async def synthesize(self, text: str, voice: str = "Rachel") -> bytes:
        """Synthesize complete audio"""
        try:
            audio = await self.client.generate(
                text=text,
                voice=voice,
                model=self.model_id
            )
            
            # Convert generator to bytes
            audio_data = b''
            async for chunk in audio:
                audio_data += chunk
                
            return audio_data
            
        except Exception as e:
            logger.error(f"ElevenLabs synthesis error: {e}")
            raise
            
    async def stream(self, text: str, voice: str = "Rachel") -> AsyncGenerator[bytes, None]:
        """Stream audio chunks"""
        try:
            audio_stream = await self.client.generate(
                text=text,
                voice=voice,
                model=self.model_id,
                stream=True
            )
            
            async for chunk in audio_stream:
                yield chunk
                
        except Exception as e:
            logger.error(f"ElevenLabs streaming error: {e}")
            raise

class OpenAITTSProvider(TTSProvider):
    """OpenAI TTS provider"""
    
    def __init__(self, api_key: str):
        import openai
        self.client = openai.AsyncOpenAI(api_key=api_key)
        
    async def synthesize(self, text: str, voice: str = "alloy") -> bytes:
        """Synthesize complete audio"""
        try:
            response = await self.client.audio.speech.create(
                model="tts-1",
                voice=voice,
                input=text,
                response_format="mp3"
            )
            
            return response.content
            
        except Exception as e:
            logger.error(f"OpenAI TTS error: {e}")
            raise
            
    async def stream(self, text: str, voice: str = "alloy") -> AsyncGenerator[bytes, None]:
        """Stream audio chunks"""
        try:
            response = await self.client.audio.speech.create(
                model="tts-1",
                voice=voice,
                input=text,
                response_format="mp3",
                stream=True
            )
            
            async for chunk in response.iter_bytes(1024):
                yield chunk
                
        except Exception as e:
            logger.error(f"OpenAI TTS streaming error: {e}")
            raise

class TTSClient:
    """Multi-provider TTS client"""
    
    def __init__(self, providers: Dict[str, TTSProvider]):
        self.providers = providers
        self.default_provider = next(iter(providers.keys()))
        
    async def synthesize(self, 
                        text: str, 
                        voice: str = None,
                        provider: str = None) -> bytes:
        """Synthesize speech with provider selection"""
        provider = provider or self.default_provider
        
        if provider not in self.providers:
            raise ValueError(f"Unknown provider: {provider}")
            
        return await self.providers[provider].synthesize(text, voice)
        
    async def stream(self,
                    text: str,
                    voice: str = None,
                    provider: str = None) -> AsyncGenerator[bytes, None]:
        """Stream speech with provider selection"""
        provider = provider or self.default_provider
        
        if provider not in self.providers:
            raise ValueError(f"Unknown provider: {provider}")
            
        async for chunk in self.providers[provider].stream(text, voice):
            yield chunk
