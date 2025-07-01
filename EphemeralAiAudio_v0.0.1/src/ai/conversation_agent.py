"""Conversational AI agent for voice interactions"""
import asyncio
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, field
from datetime import datetime, timezone
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
    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    
    def add_message(self, role: str, content: str):
        """Add message to conversation history"""
        self.messages.append({
            "role": role,
            "content": content,
            "timestamp": datetime.now(timezone.utc).isoformat()
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
