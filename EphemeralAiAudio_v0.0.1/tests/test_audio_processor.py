"""Tests for audio processing"""
import pytest
import numpy as np
from src.audio.audio_enhancer import AudioEnhancer
from src.audio.audio_buffer import AudioBuffer

def test_audio_normalization():
    """Test audio normalization"""
    enhancer = AudioEnhancer()
    
    # Create test audio with known max value
    audio = np.array([0.5, -0.8, 0.3, -0.4], dtype=np.float32)
    normalized = enhancer._normalize(audio)
    
    # Check max value is close to 0.95
    assert np.max(np.abs(normalized)) == pytest.approx(0.95, rel=1e-3)

def test_audio_buffer_write_read():
    """Test audio buffer write and read"""
    buffer = AudioBuffer(max_duration=1.0, sample_rate=16000)
    
    # Write test data
    test_data = np.random.randn(8000).astype(np.float32)
    buffer.write(test_data)
    
    # Read data back
    read_data = buffer.read()
    
    assert len(read_data) == len(test_data)
    assert np.allclose(read_data, test_data)

def test_audio_buffer_circular():
    """Test circular buffer behavior"""
    buffer = AudioBuffer(max_duration=0.5, sample_rate=16000)  # 8000 samples max
    
    # Write more data than buffer can hold
    data1 = np.ones(6000, dtype=np.float32)
    data2 = np.ones(4000, dtype=np.float32) * 2
    
    buffer.write(data1)
    buffer.write(data2)
    
    # Should contain last 8000 samples
    read_data = buffer.read()
    assert len(read_data) == 8000
    
    # First 2000 should be from data1, rest from data2
    assert np.allclose(read_data[:2000], 1.0)
    assert np.allclose(read_data[2000:], 2.0)
