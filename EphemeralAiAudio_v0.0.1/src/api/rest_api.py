"""REST API endpoints for EVA"""
from fastapi import FastAPI, HTTPException, UploadFile, File, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import logging
import io
import json
import os

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
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Security headers middleware
    from starlette.middleware.base import BaseHTTPMiddleware

    class SecurityHeadersMiddleware(BaseHTTPMiddleware):
        async def dispatch(self, request, call_next):
            response = await call_next(request)
            response.headers["X-Content-Type-Options"] = "nosniff"
            response.headers["X-Frame-Options"] = "DENY"
            response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
            return response

    app.add_middleware(SecurityHeadersMiddleware)

    # Serve static files
    static_dir = os.path.join(os.path.dirname(__file__), "static")
    if os.path.exists(static_dir):
        app.mount("/static", StaticFiles(directory=static_dir), name="static")
    
    @app.get("/")
    async def root():
        """Serve the main web interface"""
        index_path = os.path.join(static_dir, "index.html")
        if os.path.exists(index_path):
            return FileResponse(index_path)
        return {"message": "EVA API - Use /docs for API documentation"}
    
    @app.get("/health")
    async def health_check():
        """Health check endpoint"""
        return {"status": "healthy", "service": "EVA"}
    
    @app.post("/sessions")
    async def create_session(request: SessionRequest):
        """Create new ephemeral session"""
        session = await session_manager.create_session()
        if request.config:
            # Only allow known config keys
            allowed_keys = {"language", "voice_preference", "response_style"}
            filtered = {k: v for k, v in request.config.items() if k in allowed_keys}
            session.context.update(filtered)
            
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
        # Validate file size (25MB max - Whisper limit)
        content = await file.read(25 * 1024 * 1024 + 1)
        if len(content) > 25 * 1024 * 1024:
            raise HTTPException(status_code=413, detail="File too large (25MB max)")

        allowed_types = {"audio/webm", "audio/wav", "audio/mp3", "audio/ogg", "audio/mpeg", "audio/x-wav"}
        if file.content_type and file.content_type not in allowed_types:
            raise HTTPException(status_code=415, detail="Unsupported audio format")

        return {
            "transcription": "Transcription endpoint not yet implemented",
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
            raise HTTPException(status_code=500, detail="Speech synthesis failed")
    
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
            raise HTTPException(status_code=500, detail="Chat processing failed")
    
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
