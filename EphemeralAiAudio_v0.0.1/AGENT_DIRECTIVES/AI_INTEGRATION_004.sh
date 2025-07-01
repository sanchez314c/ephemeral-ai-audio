#!/bin/bash
source ~/miniconda3/etc/profile.d/conda.sh
conda activate ./conda_env

# AI Integration Agent 004 - LLM and TTS Integration
echo "[$(date '+%Y-%m-%d %H:%M:%S')] AI Integration Agent 004 starting..."

cd /Volumes/mpRAID/Development/Projects/EphemeralAIAudio

# Create AI integration modules
cat > src/ai/__init__.py << 'EOF'
"""AI service integrations for EVA"""
EOF

cat > src/ai/llm_client.py << 'EOF'
"""Multi-provider LLM client with fallback support"""
import asyncio
from typing import Optional, List, Dict, Any, AsyncGenerator
from abc import ABC, abstractmethod
import openai
import anthropic
import logging
from dataclasses import dataclass

logger = logging.getLogger(__name__)

@dataclass
class LLMResponse:
    """Standard LLM response format"""
    content: str
    model: str
    usage: Dict[str, int]
    provider: str
    
class LLMProvider(ABC):
    """Abstract base for LLM providers"""
    
    @abstractmethod
    async def complete(self, 
                      messages: List[Dict[str, str]], 
                      **kwargs) -> LLMResponse:
        pass
        
    @abstractmethod
    async def stream(self, 
                    messages: List[Dict[str, str]], 
                    **kwargs) -> AsyncGenerator[str, None]:
        pass

class OpenAIProvider(LLMProvider):
    """OpenAI API provider"""
    
    def __init__(self, api_key: str, model: str = "gpt-4"):
        self.client = openai.AsyncOpenAI(api_key=api_key)
        self.model = model
        
    async def complete(self, messages: List[Dict[str, str]], **kwargs) -> LLMResponse:
        try:
            response = await self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                **kwargs
            )
            
            return LLMResponse(
                content=response.choices[0].message.content,
                model=response.model,
                usage=response.usage.model_dump(),
                provider="openai"
            )
        except Exception as e:
            logger.error(f"OpenAI completion error: {e}")
            raise
            
    async def stream(self, messages: List[Dict[str, str]], **kwargs) -> AsyncGenerator[str, None]:
        try:
            stream = await self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                stream=True,
                **kwargs
            )
            
            async for chunk in stream:
                if chunk.choices[0].delta.content:
                    yield chunk.choices[0].delta.content
                    
        except Exception as e:
            logger.error(f"OpenAI streaming error: {e}")
            raise

class AnthropicProvider(LLMProvider):
    """Anthropic Claude provider"""
    
    def __init__(self, api_key: str, model: str = "claude-3-opus-20240229"):
        self.client = anthropic.AsyncAnthropic(api_key=api_key)
        self.model = model
        
    async def complete(self, messages: List[Dict[str, str]], **kwargs) -> LLMResponse:
        try:
            # Convert messages to Anthropic format
            system_msg = next((m['content'] for m in messages if m['role'] == 'system'), None)
            user_messages = [m for m in messages if m['role'] != 'system']
            
            response = await self.client.messages.create(
                model=self.model,
                messages=user_messages,
                system=system_msg,
                max_tokens=kwargs.get('max_tokens', 2000)
            )
            
            return LLMResponse(
                content=response.content[0].text,
                model=response.model,
                usage={
                    'prompt_tokens': response.usage.input_tokens,
                    'completion_tokens': response.usage.output_tokens,
                    'total_tokens': response.usage.input_tokens + response.usage.output_tokens
                },
                provider="anthropic"
            )
        except Exception as e:
            logger.error(f"Anthropic completion error: {e}")
            raise
            
    async def stream(self, messages: List[Dict[str, str]], **kwargs) -> AsyncGenerator[str, None]:
        try:
            system_msg = next((m['content'] for m in messages if m['role'] == 'system'), None)
            user_messages = [m for m in messages if m['role'] != 'system']
            
            async with self.client.messages.stream(
                model=self.model,
                messages=user_messages,
                system=system_msg,
                max_tokens=kwargs.get('max_tokens', 2000)
            ) as stream:
                async for text in stream.text_stream:
                    yield text
                    
        except Exception as e:
            logger.error(f"Anthropic streaming error: {e}")
            raise

class LLMClient:
    """Multi-provider LLM client with fallback"""
    
    def __init__(self, providers: List[LLMProvider]):
        self.providers = providers
        
    async def complete(self, messages: List[Dict[str, str]], **kwargs) -> LLMResponse:
        """Complete with fallback support"""
        for provider in self.providers:
            try:
                return await provider.complete(messages, **kwargs)
            except Exception as e:
                logger.warning(f"Provider {provider.__class__.__name__} failed: {e}")
                continue
                
        raise Exception("All LLM providers failed")
        
    async def stream(self, messages: List[Dict[str, str]], **kwargs) -> AsyncGenerator[str, None]:
        """Stream with fallback support"""
        for provider in self.providers:
            try:
                async for chunk in provider.stream(messages, **kwargs):
                    yield chunk
                return
            except Exception as e:
                logger.warning(f"Provider {provider.__class__.__name__} failed: {e}")
                continue
                
        raise Exception("All LLM providers failed")
EOF

cat > src/ai/tts_client.py << 'EOF'
"""Text-to-speech client with multiple providers"""
import asyncio
from typing import Optional, AsyncGenerator
from abc import ABC, abstractmethod
import logging
import io
import numpy as np
from elevenlabs import AsyncElevenLabs
from elevenlabs.client import AsyncStream

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
EOF

cat > src/ai/conversation_agent.py << 'EOF'
"""Conversational AI agent for voice interactions"""
import asyncio
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, field
from datetime import datetime
import logging

from .llm_client import LLMClient

logger = logging.getLogger(__name__)

@dataclass
class ConversationContext:
    """Maintains conversation state and history"""
    session_id: str
    messages: List[Dict[str, str]] = field(default_factory=list)
    system_prompt: str = ""
    metadata: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.utcnow)
    
    def add_message(self, role: str, content: str):
        """Add message to conversation history"""
        self.messages.append({
            "role": role,
            "content": content,
            "timestamp": datetime.utcnow().isoformat()
        })
        
    def get_messages_for_llm(self) -> List[Dict[str, str]]:
        """Get messages formatted for LLM"""
        messages = []
        
        if self.system_prompt:
            messages.append({
                "role": "system",
                "content": self.system_prompt
            })
            
        for msg in self.messages:
            messages.append({
                "role": msg["role"],
                "content": msg["content"]
            })
            
        return messages
        
    def truncate_history(self, max_messages: int = 20):
        """Keep only recent messages to manage context length"""
        if len(self.messages) > max_messages:
            self.messages = self.messages[-max_messages:]

class ConversationAgent:
    """Manages conversational AI interactions"""
    
    def __init__(self, llm_client: LLMClient):
        self.llm_client = llm_client
        self.contexts: Dict[str, ConversationContext] = {}
        
        # Default system prompt for voice assistant
        self.default_system_prompt = """You are EVA (Ephemeral Voice Agent), a helpful and natural voice assistant. 
Your responses should be:
- Conversational and friendly
- Concise but informative
- Optimized for speech (avoid complex punctuation or formatting)
- Context-aware based on the conversation history

Remember that your responses will be spoken aloud, so write them as you would naturally speak."""
        
    def create_context(self, session_id: str, system_prompt: Optional[str] = None) -> ConversationContext:
        """Create new conversation context"""
        context = ConversationContext(
            session_id=session_id,
            system_prompt=system_prompt or self.default_system_prompt
        )
        self.contexts[session_id] = context
        logger.info(f"Created conversation context for session {session_id}")
        return context
        
    def get_context(self, session_id: str) -> Optional[ConversationContext]:
        """Retrieve conversation context"""
        return self.contexts.get(session_id)
        
    async def process_message(self, 
                            session_id: str, 
                            user_input: str,
                            streaming: bool = False) -> Any:
        """Process user input and generate response"""
        context = self.get_context(session_id)
        if not context:
            context = self.create_context(session_id)
            
        # Add user message
        context.add_message("user", user_input)
        
        # Truncate history if needed
        context.truncate_history()
        
        # Get LLM messages
        messages = context.get_messages_for_llm()
        
        try:
            if streaming:
                # Return async generator for streaming
                return self._stream_response(context, messages)
            else:
                # Get complete response
                response = await self.llm_client.complete(
                    messages=messages,
                    temperature=0.7,
                    max_tokens=500  # Keep responses concise for voice
                )
                
                # Add assistant response to context
                context.add_message("assistant", response.content)
                
                return response.content
                
        except Exception as e:
            logger.error(f"Error processing message: {e}")
            raise
            
    async def _stream_response(self, 
                              context: ConversationContext, 
                              messages: List[Dict[str, str]]):
        """Stream response and update context"""
        full_response = ""
        
        async for chunk in self.llm_client.stream(
            messages=messages,
            temperature=0.7,
            max_tokens=500
        ):
            full_response += chunk
            yield chunk
            
        # Add complete response to context
        context.add_message("assistant", full_response)
        
    def clear_context(self, session_id: str):
        """Clear conversation context"""
        if session_id in self.contexts:
            del self.contexts[session_id]
            logger.info(f"Cleared context for session {session_id}")
EOF

echo "[$(date '+%Y-%m-%d %H:%M:%S')] AI Integration modules created"
echo "STATUS: COMPLETE"