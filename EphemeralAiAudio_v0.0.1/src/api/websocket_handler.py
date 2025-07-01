"""WebSocket handler for real-time voice communication"""
import asyncio
import json
import base64
from typing import Dict, Optional
import websockets
from websockets.server import WebSocketServerProtocol
import logging
from datetime import datetime
from ..core.event_bus import Event

logger = logging.getLogger(__name__)

class WebSocketHandler:
    """Handles WebSocket connections for voice streaming"""
    
    def __init__(self, session_manager, event_bus):
        self.session_manager = session_manager
        self.event_bus = event_bus
        self.connections: Dict[str, WebSocketServerProtocol] = {}
        
    async def handle_connection(self, websocket: WebSocketServerProtocol):
        """Handle new WebSocket connection"""
        session = await self.session_manager.create_session()
        session_id = session.session_id
        self.connections[session_id] = websocket
        
        logger.info(f"WebSocket connected: {session_id}")
        
        try:
            # Send session info
            await websocket.send(json.dumps({
                "type": "session_created",
                "session_id": session_id,
                "timestamp": datetime.utcnow().isoformat()
            }))
            
            # Handle messages
            async for message in websocket:
                await self._handle_message(session_id, message)
                
        except websockets.exceptions.ConnectionClosed:
            logger.info(f"WebSocket disconnected: {session_id}")
        except Exception as e:
            logger.error(f"WebSocket error: {e}")
        finally:
            # Cleanup
            if session_id in self.connections:
                del self.connections[session_id]
            await self.session_manager.terminate_session(session_id)
            
    async def _handle_message(self, session_id: str, message: str):
        """Process incoming WebSocket message"""
        try:
            data = json.loads(message)
            msg_type = data.get("type")
            
            if msg_type == "audio_chunk":
                # Reject payloads over 10MB (base64 encoded)
                if len(data.get("audio", "")) > 10 * 1024 * 1024 * 4 // 3:
                    logger.warning(f"Audio payload too large from session {session_id}")
                    return
                # Handle audio data
                audio_data = base64.b64decode(data["audio"])
                await self.event_bus.emit(Event(
                    event_type="audio_received",
                    data=audio_data,
                    session_id=session_id
                ))
                
            elif msg_type == "control":
                # Handle control messages
                action = data.get("action")
                if action == "start_recording":
                    await self.event_bus.emit(Event(
                        event_type="recording_started",
                        data={},
                        session_id=session_id
                    ))
                elif action == "stop_recording":
                    await self.event_bus.emit(Event(
                        event_type="recording_stopped",
                        data={},
                        session_id=session_id
                    ))
                    
            elif msg_type == "config":
                # Handle configuration updates
                config = data.get("config", {})
                session = await self.session_manager.get_session(session_id)
                if session:
                    allowed_keys = {"language", "voice_preference", "response_style"}
                    filtered = {k: v for k, v in config.items() if k in allowed_keys}
                    session.context.update(filtered)
                    
        except json.JSONDecodeError:
            logger.error(f"Invalid JSON from session {session_id}")
        except Exception as e:
            logger.error(f"Message handling error: {e}")
            
    async def send_to_session(self, session_id: str, data: Dict):
        """Send data to specific session"""
        if session_id in self.connections:
            try:
                await self.connections[session_id].send(json.dumps(data))
            except Exception as e:
                logger.error(f"Failed to send to session {session_id}: {e}")
                
    async def broadcast(self, data: Dict, exclude: Optional[str] = None):
        """Broadcast to all connected sessions"""
        for session_id, ws in self.connections.items():
            if session_id != exclude:
                await self.send_to_session(session_id, data)

    async def process_audio_chunk(self, session_id: str, audio_data: bytes):
        """Process audio chunk through the pipeline"""
        if hasattr(self, 'audio_processor'):
            response = await self.audio_processor.process_audio_message(session_id, audio_data)
            await self.send_to_session(session_id, response)
