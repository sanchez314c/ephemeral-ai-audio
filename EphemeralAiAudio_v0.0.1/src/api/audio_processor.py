"""Audio processing integration for WebSocket"""
import base64
import json
import logging
from typing import Dict, Optional
from ..audio.transcriber import Transcriber
from ..ai.conversation_agent import ConversationAgent
from ..ai.tts_client import TTSClient

logger = logging.getLogger(__name__)

class AudioProcessor:
    """Handles audio processing pipeline"""
    
    def __init__(self, transcriber: Transcriber, conversation_agent: ConversationAgent, tts_client: TTSClient):
        self.transcriber = transcriber
        self.conversation_agent = conversation_agent
        self.tts_client = tts_client
        
    async def process_audio_message(self, session_id: str, audio_data: bytes) -> Dict:
        """Process audio through full pipeline"""
        try:
            # 1. Transcribe audio to text
            transcript = await self.transcriber.transcribe(audio_data)
            if not transcript:
                return {
                    "type": "error",
                    "message": "Failed to transcribe audio"
                }
                
            # 2. Get AI response
            response_text = await self.conversation_agent.process_message(
                session_id, 
                transcript,
                streaming=False
            )
            
            # 3. Convert response to speech
            audio_response = await self.tts_client.synthesize(
                response_text,
                voice="alloy"  # OpenAI voice
            )
            
            # 4. Return complete response
            return {
                "type": "audio_response",
                "transcript": transcript,
                "response_text": response_text,
                "audio": base64.b64encode(audio_response).decode('utf-8')
            }
            
        except Exception as e:
            logger.error(f"Audio processing error: {e}")
            return {
                "type": "error",
                "message": "Audio processing failed"
            }
