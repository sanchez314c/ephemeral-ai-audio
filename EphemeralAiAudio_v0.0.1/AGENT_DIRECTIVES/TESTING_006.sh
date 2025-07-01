#!/bin/bash
source ~/miniconda3/etc/profile.d/conda.sh
conda activate ./conda_env

# Testing Agent 006 - Test Suite and Demo
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Testing Agent 006 starting..."

cd /Volumes/mpRAID/Development/Projects/EphemeralAIAudio

# Create test modules
cat > tests/__init__.py << 'EOF'
"""EVA test suite"""
EOF

cat > tests/test_session_manager.py << 'EOF'
"""Tests for session management"""
import pytest
import asyncio
from datetime import datetime, timedelta
from src.core.session_manager import Session, SessionManager

@pytest.mark.asyncio
async def test_session_creation():
    """Test session creation"""
    manager = SessionManager()
    session = await manager.create_session()
    
    assert session.session_id is not None
    assert session.is_active is True
    assert session.created_at <= datetime.utcnow()
    assert session.expires_at > datetime.utcnow()

@pytest.mark.asyncio
async def test_session_expiration():
    """Test session expiration"""
    session = Session()
    session.expires_at = datetime.utcnow() - timedelta(minutes=1)
    
    assert session.is_expired() is True

@pytest.mark.asyncio
async def test_session_extension():
    """Test session extension"""
    session = Session()
    original_expiry = session.expires_at
    
    session.extend_session(60)
    
    assert session.expires_at > original_expiry

@pytest.mark.asyncio
async def test_session_retrieval():
    """Test session retrieval"""
    manager = SessionManager()
    session = await manager.create_session()
    session_id = session.session_id
    
    retrieved = await manager.get_session(session_id)
    assert retrieved is not None
    assert retrieved.session_id == session_id

@pytest.mark.asyncio
async def test_session_termination():
    """Test session termination"""
    manager = SessionManager()
    session = await manager.create_session()
    session_id = session.session_id
    
    await manager.terminate_session(session_id)
    
    retrieved = await manager.get_session(session_id)
    assert retrieved is None
EOF

cat > tests/test_audio_processor.py << 'EOF'
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
EOF

cat > tests/test_event_bus.py << 'EOF'
"""Tests for event bus"""
import pytest
import asyncio
from src.core.event_bus import Event, EventBus

@pytest.mark.asyncio
async def test_event_subscription():
    """Test event subscription and emission"""
    bus = EventBus()
    received_events = []
    
    async def handler(event):
        received_events.append(event)
    
    bus.subscribe("test_event", handler)
    await bus.start()
    
    # Emit event
    test_event = Event(
        event_type="test_event",
        data={"message": "test"}
    )
    await bus.emit(test_event)
    
    # Wait for processing
    await asyncio.sleep(0.1)
    
    assert len(received_events) == 1
    assert received_events[0].data["message"] == "test"
    
    await bus.stop()

@pytest.mark.asyncio
async def test_multiple_handlers():
    """Test multiple handlers for same event"""
    bus = EventBus()
    handler1_called = False
    handler2_called = False
    
    async def handler1(event):
        nonlocal handler1_called
        handler1_called = True
    
    async def handler2(event):
        nonlocal handler2_called
        handler2_called = True
    
    bus.subscribe("test_event", handler1)
    bus.subscribe("test_event", handler2)
    await bus.start()
    
    await bus.emit(Event(event_type="test_event", data={}))
    await asyncio.sleep(0.1)
    
    assert handler1_called
    assert handler2_called
    
    await bus.stop()
EOF

cat > demo.py << 'EOF'
"""Demo script for EVA"""
import asyncio
import os
import sys
from dotenv import load_dotenv

# Add src to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from src.core.config import Config
from src.core.session_manager import SessionManager
from src.core.event_bus import EventBus
from src.ai.llm_client import LLMClient, OpenAIProvider
from src.ai.conversation_agent import ConversationAgent

async def demo_conversation():
    """Demonstrate conversation functionality"""
    load_dotenv()
    
    # Initialize components
    config = Config.from_env()
    
    if not config.ai.openai_api_key:
        print("Please set OPENAI_API_KEY environment variable")
        return
        
    # Create LLM client
    llm_client = LLMClient([
        OpenAIProvider(config.ai.openai_api_key, "gpt-3.5-turbo")
    ])
    
    # Create conversation agent
    agent = ConversationAgent(llm_client)
    
    # Create session
    session_manager = SessionManager()
    session = await session_manager.create_session()
    
    print(f"Created session: {session.session_id}")
    print("\nDemo Conversation:")
    print("-" * 50)
    
    # Simulate conversation
    messages = [
        "Hello! I'm testing the voice agent.",
        "What's the weather like today?",
        "Can you help me set a reminder?"
    ]
    
    for message in messages:
        print(f"\nUser: {message}")
        
        response = await agent.process_message(
            session.session_id,
            message,
            streaming=False
        )
        
        print(f"Assistant: {response}")
        
    print("\n" + "-" * 50)
    print("Demo completed!")

if __name__ == "__main__":
    asyncio.run(demo_conversation())
EOF

cat > run_tests.sh << 'EOF'
#!/bin/bash
source ~/miniconda3/etc/profile.d/conda.sh
conda activate ./conda_env

echo "Running EVA test suite..."
python -m pytest tests/ -v --tb=short

echo ""
echo "Running demo..."
python demo.py
EOF

chmod +x run_tests.sh

cat > README.md << 'EOF'
# Ephemeral Voice Agent (EVA)

EVA is a real-time voice interaction system that provides ephemeral, context-aware conversations using advanced AI models.

## Features

- Real-time audio streaming with WebSocket support
- Multi-provider LLM support (OpenAI, Anthropic)
- Multi-provider TTS support (ElevenLabs, OpenAI)
- Voice Activity Detection (VAD)
- Audio enhancement and noise reduction
- Ephemeral session management
- REST and WebSocket APIs

## Architecture

EVA is built with a modular architecture:

- **Core Engine**: Session management, event bus, configuration
- **Audio Processing**: Real-time stream processing, VAD, enhancement
- **AI Integration**: LLM clients, TTS clients, conversation agent
- **API Gateway**: WebSocket handler, REST endpoints

## Installation

1. Create and activate the conda environment:
```bash
conda activate ./conda_env
```

2. Set up environment variables:
```bash
export OPENAI_API_KEY="your-key"
export ANTHROPIC_API_KEY="your-key"  # Optional
export ELEVENLABS_API_KEY="your-key"  # Optional
```

## Running EVA

Start the server:
```bash
python -m src.api.server
```

The server will start:
- REST API: http://localhost:8000
- WebSocket: ws://localhost:8001

## API Endpoints

### REST API

- `POST /sessions` - Create new session
- `GET /sessions/{session_id}` - Get session info
- `DELETE /sessions/{session_id}` - Terminate session
- `POST /chat` - Send chat message
- `POST /synthesize` - Text-to-speech
- `POST /transcribe` - Speech-to-text

### WebSocket Protocol

Connect to `ws://localhost:8001` and exchange messages:

```json
// Audio streaming
{
  "type": "audio_chunk",
  "audio": "base64_encoded_audio"
}

// Control messages
{
  "type": "control",
  "action": "start_recording"
}
```

## Testing

Run the test suite:
```bash
./run_tests.sh
```

## Development

Built using the A² Framework v2.7 with multiple specialized agents:
- DevOps Agent: Environment setup
- Core Engine Agent: Main framework
- Audio Processing Agent: Real-time audio
- AI Integration Agent: LLM/TTS services
- API Gateway Agent: WebSocket/REST APIs
- Testing Agent: Test suite and demos

## License

Proprietary - All rights reserved
EOF

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Testing suite and documentation created"
echo "STATUS: COMPLETE"