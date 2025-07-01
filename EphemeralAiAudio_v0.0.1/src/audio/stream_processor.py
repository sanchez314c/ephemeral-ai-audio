"""Real-time audio stream processing"""
import numpy as np
import asyncio
from typing import Callable, Optional, List
import pyaudio
import webrtcvad
import logging
from dataclasses import dataclass
from collections import deque

logger = logging.getLogger(__name__)

@dataclass
class AudioChunk:
    """Represents a chunk of audio data"""
    data: bytes
    timestamp: float
    is_speech: bool = False
    energy: float = 0.0

class StreamProcessor:
    """Real-time audio stream processor with VAD"""
    
    def __init__(self, 
                 sample_rate: int = 16000,
                 chunk_size: int = 480,  # 30ms at 16kHz
                 vad_aggressiveness: int = 3):
        self.sample_rate = sample_rate
        self.chunk_size = chunk_size
        self.vad = webrtcvad.Vad(vad_aggressiveness)
        self.audio = None
        self.stream = None
        self.is_running = False
        
        # Audio buffer for speech segments
        self.speech_buffer = deque(maxlen=100)
        self.silence_chunks = 0
        self.max_silence_chunks = 10  # 300ms of silence
        
    async def start(self, input_device: Optional[int] = None):
        """Start audio stream"""
        self.audio = pyaudio.PyAudio()
        self.stream = self.audio.open(
            format=pyaudio.paInt16,
            channels=1,
            rate=self.sample_rate,
            input=True,
            input_device_index=input_device,
            frames_per_buffer=self.chunk_size,
            stream_callback=None
        )
        self.is_running = True
        logger.info("Audio stream started")
        
    async def stop(self):
        """Stop audio stream"""
        self.is_running = False
        if self.stream:
            self.stream.stop_stream()
            self.stream.close()
        if self.audio:
            self.audio.terminate()
        logger.info("Audio stream stopped")
        
    async def process_stream(self, callback: Callable[[AudioChunk], None]):
        """Process audio stream with callback"""
        while self.is_running:
            try:
                # Read audio chunk
                data = self.stream.read(self.chunk_size, exception_on_overflow=False)
                
                # Convert to numpy array
                audio_array = np.frombuffer(data, dtype=np.int16)
                
                # Calculate energy
                energy = np.sqrt(np.mean(audio_array.astype(float)**2))
                
                # VAD detection
                is_speech = self.vad.is_speech(data, self.sample_rate)
                
                chunk = AudioChunk(
                    data=data,
                    timestamp=asyncio.get_event_loop().time(),
                    is_speech=is_speech,
                    energy=energy
                )
                
                # Handle speech segments
                if is_speech:
                    self.speech_buffer.append(chunk)
                    self.silence_chunks = 0
                else:
                    self.silence_chunks += 1
                    if self.silence_chunks > self.max_silence_chunks and self.speech_buffer:
                        # End of speech segment detected
                        await self._process_speech_segment(callback)
                        
                # Process chunk
                await callback(chunk)
                
            except Exception as e:
                logger.error(f"Stream processing error: {e}")
                await asyncio.sleep(0.01)
                
    async def _process_speech_segment(self, callback: Callable):
        """Process accumulated speech segment"""
        if not self.speech_buffer:
            return
            
        # Combine all chunks in buffer
        combined_data = b''.join([chunk.data for chunk in self.speech_buffer])
        
        # Create combined chunk
        segment_chunk = AudioChunk(
            data=combined_data,
            timestamp=self.speech_buffer[0].timestamp,
            is_speech=True,
            energy=np.mean([chunk.energy for chunk in self.speech_buffer])
        )
        
        # Clear buffer
        self.speech_buffer.clear()
        
        # Process segment
        await callback(segment_chunk)
