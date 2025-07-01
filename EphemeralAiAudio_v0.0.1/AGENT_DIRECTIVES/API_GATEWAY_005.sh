#!/bin/bash
source ~/miniconda3/etc/profile.d/conda.sh
conda activate ./conda_env

# API Gateway Agent 005 - WebSocket and REST API
echo "[$(date '+%Y-%m-%d %H:%M:%S')] API Gateway Agent 005 starting..."

cd /Volumes/mpRAID/Development/Projects/EphemeralAIAudio

# Create API gateway modules
cat > src/api/__init__.py << 'EOF'
"""API Gateway for EVA"""
EOF

cat > src/api/websocket_handler.py << 'EOF'
"""WebSocket handler for real-time voice communication"""
import asyncio
import json
import base64
from typing import Dict, Optional
import websockets
from websockets.server import WebSocketServerProtocol
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

class WebSocketHandler:
    """Handles WebSocket connections for voice streaming"""
    
    def __init__(self, session_manager, event_bus):
        self.session_manager = session_manager
        self.event_bus = event_bus
        self.connections: Dict[str, WebSocketServerProtocol] = {}
        
    async def handle_connection(self, websocket: WebSocketServerProtocol, path: str):
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
                # Handle audio data
                audio_data = base64.b64decode(data["audio"])
                await self.event_bus.emit({
                    "event_type": "audio_received",
                    "session_id": session_id,
                    "data": audio_data
                })
                
            elif msg_type == "control":
                # Handle control messages
                action = data.get("action")
                if action == "start_recording":
                    await self.event_bus.emit({
                        "event_type": "recording_started",
                        "session_id": session_id
                    })
                elif action == "stop_recording":
                    await self.event_bus.emit({
                        "event_type": "recording_stopped",
                        "session_id": session_id
                    })
                    
            elif msg_type == "config":
                # Handle configuration updates
                config = data.get("config", {})
                session = await self.session_manager.get_session(session_id)
                if session:
                    session.context.update(config)
                    
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
EOF

cat > src/api/rest_api.py << 'EOF'
"""REST API endpoints for EVA"""
from fastapi import FastAPI, HTTPException, UploadFile, File, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import logging
import io

logger = logging.getLogger(__name__)

class SessionRequest(BaseModel):
    """Request model for session creation"""
    config: Optional[Dict[str, Any]] = None

class TranscriptionRequest(BaseModel):
    """Request model for transcription"""
    session_id: str
    audio_format: str = "wav"

class SynthesisRequest(BaseModel):
    """Request model for speech synthesis"""
    text: str
    voice: Optional[str] = None
    provider: Optional[str] = None

class ChatRequest(BaseModel):
    """Request model for chat completion"""
    session_id: str
    message: str
    streaming: bool = False

def create_rest_api(session_manager, conversation_agent, tts_client) -> FastAPI:
    """Create FastAPI application"""
    app = FastAPI(
        title="EVA API",
        description="Ephemeral Voice Agent REST API",
        version="0.1.0"
    )
    
    # CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    @app.get("/health")
    async def health_check():
        """Health check endpoint"""
        return {"status": "healthy", "service": "EVA"}
    
    @app.post("/sessions")
    async def create_session(request: SessionRequest):
        """Create new ephemeral session"""
        session = await session_manager.create_session()
        if request.config:
            session.context.update(request.config)
            
        return {
            "session_id": session.session_id,
            "created_at": session.created_at.isoformat(),
            "expires_at": session.expires_at.isoformat()
        }
    
    @app.get("/sessions/{session_id}")
    async def get_session(session_id: str):
        """Get session information"""
        session = await session_manager.get_session(session_id)
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")
            
        return {
            "session_id": session.session_id,
            "created_at": session.created_at.isoformat(),
            "expires_at": session.expires_at.isoformat(),
            "is_active": session.is_active
        }
    
    @app.delete("/sessions/{session_id}")
    async def terminate_session(session_id: str):
        """Terminate session"""
        await session_manager.terminate_session(session_id)
        return {"status": "terminated"}
    
    @app.post("/transcribe")
    async def transcribe_audio(
        file: UploadFile = File(...),
        session_id: Optional[str] = None
    ):
        """Transcribe audio file"""
        # TODO: Implement transcription
        return {
            "transcription": "Audio transcription placeholder",
            "session_id": session_id
        }
    
    @app.post("/synthesize")
    async def synthesize_speech(request: SynthesisRequest):
        """Synthesize speech from text"""
        try:
            audio_data = await tts_client.synthesize(
                text=request.text,
                voice=request.voice,
                provider=request.provider
            )
            
            return StreamingResponse(
                io.BytesIO(audio_data),
                media_type="audio/mpeg",
                headers={
                    "Content-Disposition": "attachment; filename=speech.mp3"
                }
            )
        except Exception as e:
            logger.error(f"Synthesis error: {e}")
            raise HTTPException(status_code=500, detail=str(e))
    
    @app.post("/chat")
    async def chat_completion(request: ChatRequest):
        """Process chat message"""
        session = await session_manager.get_session(request.session_id)
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")
            
        try:
            if request.streaming:
                # Return streaming response
                async def generate():
                    async for chunk in conversation_agent.process_message(
                        request.session_id,
                        request.message,
                        streaming=True
                    ):
                        yield f"data: {json.dumps({'chunk': chunk})}\n\n"
                        
                return StreamingResponse(
                    generate(),
                    media_type="text/event-stream"
                )
            else:
                # Return complete response
                response = await conversation_agent.process_message(
                    request.session_id,
                    request.message,
                    streaming=False
                )
                
                return {
                    "response": response,
                    "session_id": request.session_id
                }
                
        except Exception as e:
            logger.error(f"Chat error: {e}")
            raise HTTPException(status_code=500, detail=str(e))
    
    @app.get("/sessions/{session_id}/history")
    async def get_conversation_history(session_id: str):
        """Get conversation history for session"""
        context = conversation_agent.get_context(session_id)
        if not context:
            raise HTTPException(status_code=404, detail="Session not found")
            
        return {
            "session_id": session_id,
            "messages": context.messages,
            "created_at": context.created_at.isoformat()
        }
    
    return app
EOF

cat > src/api/server.py << 'EOF'
"""Main server orchestration"""
import asyncio
import uvicorn
import websockets
from typing import Optional
import logging
import signal
import sys

from ..core.session_manager import SessionManager
from ..core.event_bus import EventBus
from ..core.config import Config
from ..ai.llm_client import LLMClient, OpenAIProvider, AnthropicProvider
from ..ai.tts_client import TTSClient, ElevenLabsProvider, OpenAITTSProvider
from ..ai.conversation_agent import ConversationAgent
from .websocket_handler import WebSocketHandler
from .rest_api import create_rest_api

logger = logging.getLogger(__name__)

class EVAServer:
    """Main server class for EVA"""
    
    def __init__(self, config: Config):
        self.config = config
        self.session_manager = SessionManager()
        self.event_bus = EventBus()
        
        # Initialize AI clients
        self._init_ai_clients()
        
        # Initialize handlers
        self.ws_handler = WebSocketHandler(self.session_manager, self.event_bus)
        self.app = create_rest_api(
            self.session_manager,
            self.conversation_agent,
            self.tts_client
        )
        
        # Server instances
        self.ws_server = None
        self.http_server = None
        
    def _init_ai_clients(self):
        """Initialize AI service clients"""
        # LLM providers
        llm_providers = []
        
        if self.config.ai.openai_api_key:
            llm_providers.append(
                OpenAIProvider(
                    api_key=self.config.ai.openai_api_key,
                    model=self.config.ai.model_name
                )
            )
            
        if self.config.ai.anthropic_api_key:
            llm_providers.append(
                AnthropicProvider(
                    api_key=self.config.ai.anthropic_api_key
                )
            )
            
        if not llm_providers:
            raise ValueError("No LLM providers configured")
            
        self.llm_client = LLMClient(providers=llm_providers)
        
        # TTS providers
        tts_providers = {}
        
        if self.config.ai.elevenlabs_api_key:
            tts_providers["elevenlabs"] = ElevenLabsProvider(
                api_key=self.config.ai.elevenlabs_api_key
            )
            
        if self.config.ai.openai_api_key:
            tts_providers["openai"] = OpenAITTSProvider(
                api_key=self.config.ai.openai_api_key
            )
            
        if not tts_providers:
            raise ValueError("No TTS providers configured")
            
        self.tts_client = TTSClient(providers=tts_providers)
        
        # Conversation agent
        self.conversation_agent = ConversationAgent(self.llm_client)
        
    async def start(self):
        """Start all servers"""
        logger.info("Starting EVA server...")
        
        # Start event bus
        await self.event_bus.start()
        
        # Start session cleanup task
        await self.session_manager.start_cleanup_task()
        
        # Start WebSocket server
        self.ws_server = await websockets.serve(
            self.ws_handler.handle_connection,
            self.config.server.host,
            self.config.server.port + 1  # WS on port+1
        )
        
        logger.info(f"WebSocket server started on ws://{self.config.server.host}:{self.config.server.port + 1}")
        
        # Start HTTP server in background
        config = uvicorn.Config(
            app=self.app,
            host=self.config.server.host,
            port=self.config.server.port,
            log_level=self.config.log_level.lower()
        )
        self.http_server = uvicorn.Server(config)
        
        asyncio.create_task(self.http_server.serve())
        
        logger.info(f"HTTP API started on http://{self.config.server.host}:{self.config.server.port}")
        logger.info("EVA server is ready!")
        
    async def stop(self):
        """Stop all servers"""
        logger.info("Stopping EVA server...")
        
        # Stop event bus
        await self.event_bus.stop()
        
        # Close WebSocket server
        if self.ws_server:
            self.ws_server.close()
            await self.ws_server.wait_closed()
            
        # Stop HTTP server
        if self.http_server:
            self.http_server.should_exit = True
            
        logger.info("EVA server stopped")
        
    async def run_forever(self):
        """Run server until interrupted"""
        await self.start()
        
        # Setup signal handlers
        loop = asyncio.get_running_loop()
        
        def signal_handler():
            asyncio.create_task(self.stop())
            
        for sig in (signal.SIGTERM, signal.SIGINT):
            loop.add_signal_handler(sig, signal_handler)
            
        # Keep running
        try:
            await asyncio.Future()
        except asyncio.CancelledError:
            pass

async def main():
    """Main entry point"""
    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Load configuration
    config = Config.from_env()
    
    # Create and run server
    server = EVAServer(config)
    await server.run_forever()

if __name__ == "__main__":
    asyncio.run(main())
EOF

echo "[$(date '+%Y-%m-%d %H:%M:%S')] API Gateway modules created"
echo "STATUS: COMPLETE"