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
