"""Integration tests for EVA"""
import pytest
import asyncio
import websockets
import json
import base64

@pytest.mark.asyncio
async def test_websocket_connection():
    """Test WebSocket connection"""
    uri = "ws://localhost:8001"
    async with websockets.connect(uri) as websocket:
        # Should receive session info
        message = await websocket.recv()
        data = json.loads(message)
        assert data["type"] == "session_created"
        assert "session_id" in data

@pytest.mark.asyncio
async def test_text_chat():
    """Test text chat functionality"""
    import httpx
    
    # Create session
    async with httpx.AsyncClient() as client:
        # Create session
        response = await client.post("http://localhost:8000/sessions")
        assert response.status_code == 200
        session_data = response.json()
        session_id = session_data["session_id"]
        
        # Send chat message
        response = await client.post(
            "http://localhost:8000/chat",
            json={
                "session_id": session_id,
                "message": "Hello EVA"
            }
        )
        assert response.status_code == 200
        chat_data = response.json()
        assert "response" in chat_data

@pytest.mark.asyncio 
async def test_audio_processing():
    """Test audio processing pipeline"""
    # This would test the full audio pipeline
    # For now, we'll just verify the components exist
    from src.audio.transcriber import Transcriber
    from src.api.audio_processor import AudioProcessor
    
    assert Transcriber is not None
    assert AudioProcessor is not None
