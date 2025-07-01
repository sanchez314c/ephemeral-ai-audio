"""Speech-to-text transcription service"""
import io
import logging
from typing import Optional
import openai

logger = logging.getLogger(__name__)

class Transcriber:
    """Handles speech-to-text transcription"""
    
    def __init__(self, api_key: str):
        self.client = openai.AsyncOpenAI(api_key=api_key)
        
    async def transcribe(self, audio_data: bytes, format: str = "webm") -> Optional[str]:
        """Transcribe audio to text using OpenAI Whisper"""
        try:
            # Create a file-like object from bytes
            audio_file = io.BytesIO(audio_data)
            audio_file.name = f"audio.{format}"
            
            # Transcribe using Whisper
            response = await self.client.audio.transcriptions.create(
                model="whisper-1",
                file=audio_file
            )
            
            return response.text
            
        except Exception as e:
            logger.error(f"Transcription error: {e}")
            return None
