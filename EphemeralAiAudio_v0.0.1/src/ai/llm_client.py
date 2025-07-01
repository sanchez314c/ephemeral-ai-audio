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
    
    def __init__(self, api_key: str, model: str = "gpt-4o"):
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
    
    def __init__(self, api_key: str, model: str = "claude-sonnet-4-20250514"):
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
