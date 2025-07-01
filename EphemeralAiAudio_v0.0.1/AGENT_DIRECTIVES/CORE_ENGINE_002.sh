#!/bin/bash
source ~/miniconda3/etc/profile.d/conda.sh
conda activate ./conda_env

# Core Engine Agent 002 - Main Application Framework
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Core Engine Agent 002 starting..."

cd /Volumes/mpRAID/Development/Projects/EphemeralAIAudio

# Create core engine modules
cat > src/core/__init__.py << 'EOF'
"""Core Engine for Ephemeral Voice Agent (EVA)"""
__version__ = "0.1.0"
EOF

cat > src/core/session_manager.py << 'EOF'
"""Session management for ephemeral voice interactions"""
import asyncio
import uuid
from datetime import datetime, timedelta
from typing import Dict, Optional, Any
from dataclasses import dataclass, field
import logging

logger = logging.getLogger(__name__)

@dataclass
class Session:
    """Represents an ephemeral voice session"""
    session_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    created_at: datetime = field(default_factory=datetime.utcnow)
    expires_at: Optional[datetime] = None
    context: Dict[str, Any] = field(default_factory=dict)
    is_active: bool = True
    
    def __post_init__(self):
        if not self.expires_at:
            self.expires_at = self.created_at + timedelta(minutes=30)
    
    def is_expired(self) -> bool:
        return datetime.utcnow() > self.expires_at
    
    def extend_session(self, minutes: int = 30):
        self.expires_at = datetime.utcnow() + timedelta(minutes=minutes)

class SessionManager:
    """Manages ephemeral voice sessions"""
    
    def __init__(self):
        self.sessions: Dict[str, Session] = {}
        self._cleanup_task = None
        
    async def create_session(self) -> Session:
        """Create a new ephemeral session"""
        session = Session()
        self.sessions[session.session_id] = session
        logger.info(f"Created session: {session.session_id}")
        return session
    
    async def get_session(self, session_id: str) -> Optional[Session]:
        """Retrieve an active session"""
        session = self.sessions.get(session_id)
        if session and not session.is_expired():
            return session
        return None
    
    async def terminate_session(self, session_id: str):
        """Terminate and cleanup a session"""
        if session_id in self.sessions:
            session = self.sessions[session_id]
            session.is_active = False
            del self.sessions[session_id]
            logger.info(f"Terminated session: {session_id}")
    
    async def cleanup_expired_sessions(self):
        """Remove expired sessions"""
        expired = [
            sid for sid, session in self.sessions.items()
            if session.is_expired()
        ]
        for sid in expired:
            await self.terminate_session(sid)
        
    async def start_cleanup_task(self):
        """Start background cleanup task"""
        async def cleanup_loop():
            while True:
                await asyncio.sleep(300)  # 5 minutes
                await self.cleanup_expired_sessions()
        
        self._cleanup_task = asyncio.create_task(cleanup_loop())
EOF

cat > src/core/event_bus.py << 'EOF'
"""Event bus for real-time communication between components"""
import asyncio
from typing import Dict, List, Callable, Any
from dataclasses import dataclass
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

@dataclass
class Event:
    """Base event class"""
    event_type: str
    data: Any
    timestamp: datetime = field(default_factory=datetime.utcnow)
    session_id: Optional[str] = None

class EventBus:
    """Central event bus for component communication"""
    
    def __init__(self):
        self._handlers: Dict[str, List[Callable]] = {}
        self._event_queue: asyncio.Queue = asyncio.Queue()
        self._running = False
        
    def subscribe(self, event_type: str, handler: Callable):
        """Subscribe to an event type"""
        if event_type not in self._handlers:
            self._handlers[event_type] = []
        self._handlers[event_type].append(handler)
        logger.debug(f"Subscribed handler to {event_type}")
    
    def unsubscribe(self, event_type: str, handler: Callable):
        """Unsubscribe from an event type"""
        if event_type in self._handlers:
            self._handlers[event_type].remove(handler)
    
    async def emit(self, event: Event):
        """Emit an event to all subscribers"""
        await self._event_queue.put(event)
    
    async def _process_events(self):
        """Process events from the queue"""
        while self._running:
            try:
                event = await asyncio.wait_for(
                    self._event_queue.get(), 
                    timeout=1.0
                )
                
                handlers = self._handlers.get(event.event_type, [])
                for handler in handlers:
                    try:
                        if asyncio.iscoroutinefunction(handler):
                            await handler(event)
                        else:
                            handler(event)
                    except Exception as e:
                        logger.error(f"Handler error: {e}")
                        
            except asyncio.TimeoutError:
                continue
    
    async def start(self):
        """Start the event bus"""
        self._running = True
        asyncio.create_task(self._process_events())
        logger.info("Event bus started")
    
    async def stop(self):
        """Stop the event bus"""
        self._running = False
        logger.info("Event bus stopped")
EOF

cat > src/core/config.py << 'EOF'
"""Configuration management for EVA"""
import os
from typing import Optional
from dataclasses import dataclass
from dotenv import load_dotenv

load_dotenv()

@dataclass
class AudioConfig:
    """Audio processing configuration"""
    sample_rate: int = 16000
    chunk_size: int = 1024
    channels: int = 1
    format: str = "int16"
    silence_threshold: float = 0.01
    max_silence_duration: float = 2.0
    
@dataclass
class AIConfig:
    """AI service configuration"""
    openai_api_key: Optional[str] = None
    anthropic_api_key: Optional[str] = None
    elevenlabs_api_key: Optional[str] = None
    model_name: str = "gpt-4"
    temperature: float = 0.7
    max_tokens: int = 2000
    
    def __post_init__(self):
        self.openai_api_key = self.openai_api_key or os.getenv("OPENAI_API_KEY")
        self.anthropic_api_key = self.anthropic_api_key or os.getenv("ANTHROPIC_API_KEY")
        self.elevenlabs_api_key = self.elevenlabs_api_key or os.getenv("ELEVENLABS_API_KEY")

@dataclass
class ServerConfig:
    """Server configuration"""
    host: str = "0.0.0.0"
    port: int = 8000
    cors_origins: List[str] = field(default_factory=lambda: ["*"])
    max_sessions: int = 100
    session_timeout: int = 1800  # 30 minutes
    
@dataclass
class Config:
    """Main configuration class"""
    audio: AudioConfig = field(default_factory=AudioConfig)
    ai: AIConfig = field(default_factory=AIConfig)
    server: ServerConfig = field(default_factory=ServerConfig)
    debug: bool = False
    log_level: str = "INFO"
    
    @classmethod
    def from_env(cls) -> "Config":
        """Create config from environment variables"""
        return cls(
            debug=os.getenv("DEBUG", "false").lower() == "true",
            log_level=os.getenv("LOG_LEVEL", "INFO")
        )
EOF

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Core Engine modules created"
echo "STATUS: COMPLETE"