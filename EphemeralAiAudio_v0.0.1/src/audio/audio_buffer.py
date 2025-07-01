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
