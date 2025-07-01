#!/bin/bash
source ~/miniconda3/etc/profile.d/conda.sh
conda activate ./conda_env

# Audio Processing Agent 003 - Real-time Audio Pipeline
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Audio Processing Agent 003 starting..."

cd /Volumes/mpRAID/Development/Projects/EphemeralAIAudio

# Create audio processing modules
cat > src/audio/__init__.py << 'EOF'
"""Audio processing components for EVA"""
EOF

cat > src/audio/stream_processor.py << 'EOF'
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
EOF

cat > src/audio/audio_enhancer.py << 'EOF'
"""Audio enhancement and noise reduction"""
import numpy as np
from scipy import signal
from typing import Tuple
import logging

logger = logging.getLogger(__name__)

class AudioEnhancer:
    """Enhance audio quality with noise reduction"""
    
    def __init__(self, sample_rate: int = 16000):
        self.sample_rate = sample_rate
        self.noise_profile = None
        self.noise_gate_threshold = 0.02
        
    def enhance(self, audio_data: np.ndarray) -> np.ndarray:
        """Apply audio enhancement pipeline"""
        # Normalize
        audio = self._normalize(audio_data)
        
        # Apply filters
        audio = self._apply_bandpass_filter(audio)
        audio = self._apply_noise_gate(audio)
        
        # Spectral subtraction if noise profile exists
        if self.noise_profile is not None:
            audio = self._spectral_subtraction(audio)
            
        return audio
        
    def _normalize(self, audio: np.ndarray) -> np.ndarray:
        """Normalize audio amplitude"""
        max_val = np.max(np.abs(audio))
        if max_val > 0:
            return audio / max_val * 0.95
        return audio
        
    def _apply_bandpass_filter(self, audio: np.ndarray) -> np.ndarray:
        """Apply bandpass filter for voice frequencies"""
        # Voice frequency range: 80Hz - 8kHz
        nyquist = self.sample_rate / 2
        low = 80 / nyquist
        high = min(8000 / nyquist, 0.99)
        
        b, a = signal.butter(4, [low, high], btype='band')
        return signal.filtfilt(b, a, audio)
        
    def _apply_noise_gate(self, audio: np.ndarray) -> np.ndarray:
        """Apply noise gate to reduce background noise"""
        envelope = self._get_envelope(audio)
        gate_mask = envelope > self.noise_gate_threshold
        
        # Smooth the gate to avoid clicks
        gate_mask = signal.medfilt(gate_mask.astype(float), 21)
        
        return audio * gate_mask
        
    def _get_envelope(self, audio: np.ndarray, window_size: int = 256) -> np.ndarray:
        """Get audio envelope"""
        return np.convolve(np.abs(audio), np.ones(window_size)/window_size, mode='same')
        
    def _spectral_subtraction(self, audio: np.ndarray) -> np.ndarray:
        """Apply spectral subtraction for noise reduction"""
        # FFT
        audio_fft = np.fft.rfft(audio)
        audio_magnitude = np.abs(audio_fft)
        audio_phase = np.angle(audio_fft)
        
        # Subtract noise profile
        enhanced_magnitude = audio_magnitude - self.noise_profile
        enhanced_magnitude = np.maximum(enhanced_magnitude, 0)
        
        # Reconstruct
        enhanced_fft = enhanced_magnitude * np.exp(1j * audio_phase)
        return np.fft.irfft(enhanced_fft, len(audio))
        
    def update_noise_profile(self, noise_sample: np.ndarray):
        """Update noise profile from noise sample"""
        noise_fft = np.fft.rfft(noise_sample)
        self.noise_profile = np.abs(noise_fft) * 0.8
        logger.info("Noise profile updated")
EOF

cat > src/audio/audio_buffer.py << 'EOF'
"""Circular audio buffer for real-time processing"""
import numpy as np
from typing import Optional
import threading

class AudioBuffer:
    """Thread-safe circular audio buffer"""
    
    def __init__(self, max_duration: float = 30.0, sample_rate: int = 16000):
        self.max_samples = int(max_duration * sample_rate)
        self.buffer = np.zeros(self.max_samples, dtype=np.float32)
        self.write_pos = 0
        self.read_pos = 0
        self.sample_rate = sample_rate
        self.lock = threading.Lock()
        
    def write(self, data: np.ndarray):
        """Write audio data to buffer"""
        with self.lock:
            data_len = len(data)
            
            # Handle wrap-around
            if self.write_pos + data_len <= self.max_samples:
                self.buffer[self.write_pos:self.write_pos + data_len] = data
            else:
                first_part = self.max_samples - self.write_pos
                self.buffer[self.write_pos:] = data[:first_part]
                self.buffer[:data_len - first_part] = data[first_part:]
                
            self.write_pos = (self.write_pos + data_len) % self.max_samples
            
    def read(self, num_samples: Optional[int] = None) -> np.ndarray:
        """Read audio data from buffer"""
        with self.lock:
            if num_samples is None:
                # Read all available data
                if self.write_pos >= self.read_pos:
                    data = self.buffer[self.read_pos:self.write_pos]
                else:
                    data = np.concatenate([
                        self.buffer[self.read_pos:],
                        self.buffer[:self.write_pos]
                    ])
                self.read_pos = self.write_pos
            else:
                # Read specific number of samples
                if self.read_pos + num_samples <= self.max_samples:
                    data = self.buffer[self.read_pos:self.read_pos + num_samples]
                else:
                    first_part = self.max_samples - self.read_pos
                    data = np.concatenate([
                        self.buffer[self.read_pos:],
                        self.buffer[:num_samples - first_part]
                    ])
                self.read_pos = (self.read_pos + num_samples) % self.max_samples
                
            return data
            
    def get_duration(self) -> float:
        """Get duration of buffered audio in seconds"""
        with self.lock:
            if self.write_pos >= self.read_pos:
                samples = self.write_pos - self.read_pos
            else:
                samples = self.max_samples - self.read_pos + self.write_pos
            return samples / self.sample_rate
            
    def clear(self):
        """Clear the buffer"""
        with self.lock:
            self.buffer.fill(0)
            self.write_pos = 0
            self.read_pos = 0
EOF

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Audio Processing modules created"
echo "STATUS: COMPLETE"