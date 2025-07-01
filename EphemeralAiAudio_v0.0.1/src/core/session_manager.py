"""Session management for ephemeral voice interactions"""
import asyncio
import uuid
from datetime import datetime, timedelta, timezone
from typing import Dict, Optional, Any
from dataclasses import dataclass, field
import logging

logger = logging.getLogger(__name__)

@dataclass
class Session:
    """Represents an ephemeral voice session"""
    session_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    expires_at: Optional[datetime] = None
    context: Dict[str, Any] = field(default_factory=dict)
    is_active: bool = True
    
    def __post_init__(self):
        if not self.expires_at:
            self.expires_at = self.created_at + timedelta(minutes=30)
    
    def is_expired(self) -> bool:
        return datetime.now(timezone.utc) > self.expires_at
    
    def extend_session(self, minutes: int = 30):
        self.expires_at = datetime.now(timezone.utc) + timedelta(minutes=minutes)

class SessionManager:
    """Manages ephemeral voice sessions"""
    
    def __init__(self, max_sessions: int = 100):
        self.sessions: Dict[str, Session] = {}
        self.max_sessions = max_sessions
        self._cleanup_task = None
        
    async def create_session(self) -> Session:
        """Create a new ephemeral session"""
        if len(self.sessions) >= self.max_sessions:
            raise RuntimeError(f"Maximum sessions ({self.max_sessions}) reached")
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
        if self._cleanup_task is not None:
            return
        async def cleanup_loop():
            while True:
                await asyncio.sleep(300)  # 5 minutes
                await self.cleanup_expired_sessions()
        
        self._cleanup_task = asyncio.create_task(cleanup_loop())
