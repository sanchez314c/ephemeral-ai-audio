"""Main server orchestration"""
import asyncio
import uvicorn
import websockets
from typing import Optional
import logging
import signal
import sys

from ..core.session_manager import SessionManager
from ..core.event_bus import EventBus
from ..core.config import Config
from ..ai.llm_client import LLMClient, OpenAIProvider, AnthropicProvider
from ..ai.tts_client import TTSClient, ElevenLabsProvider, OpenAITTSProvider
from ..ai.conversation_agent import ConversationAgent
from .websocket_handler import WebSocketHandler
from .rest_api import create_rest_api
from ..audio.transcriber import Transcriber
from .audio_processor import AudioProcessor

logger = logging.getLogger(__name__)

class EVAServer:
    """Main server class for EVA"""
    
    def __init__(self, config: Config):
        self.config = config
        self.session_manager = SessionManager(max_sessions=config.server.max_sessions)
        self.event_bus = EventBus()
        
        # Initialize AI clients
        self._init_ai_clients()
        
        # Initialize handlers
        self.ws_handler = WebSocketHandler(self.session_manager, self.event_bus)
        self.app = create_rest_api(
            self.session_manager,
            self.conversation_agent,
            self.tts_client
        )
        
        # Server instances
        self.ws_server = None
        self.http_server = None
        
    def _init_ai_clients(self):
        """Initialize AI service clients"""
        # LLM providers
        llm_providers = []
        
        if self.config.ai.openai_api_key:
            llm_providers.append(
                OpenAIProvider(
                    api_key=self.config.ai.openai_api_key,
                    model=self.config.ai.model_name
                )
            )
            
        if self.config.ai.anthropic_api_key:
            llm_providers.append(
                AnthropicProvider(
                    api_key=self.config.ai.anthropic_api_key
                )
            )
            
        if not llm_providers:
            raise ValueError("No LLM providers configured")
            
        self.llm_client = LLMClient(providers=llm_providers)
        
        # TTS providers
        tts_providers = {}
        
        if self.config.ai.elevenlabs_api_key:
            tts_providers["elevenlabs"] = ElevenLabsProvider(
                api_key=self.config.ai.elevenlabs_api_key
            )
            
        if self.config.ai.openai_api_key:
            tts_providers["openai"] = OpenAITTSProvider(
                api_key=self.config.ai.openai_api_key
            )
            
        if not tts_providers:
            raise ValueError("No TTS providers configured")
            
        self.tts_client = TTSClient(providers=tts_providers)
        
        # Conversation agent
        self.conversation_agent = ConversationAgent(self.llm_client)

        # Audio processing pipeline
        if self.config.ai.openai_api_key:
            self.transcriber = Transcriber(self.config.ai.openai_api_key)
            self.audio_processor = AudioProcessor(
                self.transcriber,
                self.conversation_agent,
                self.tts_client
            )
            self.ws_handler.audio_processor = self.audio_processor

    async def start(self):
        """Start all servers"""
        logger.info("Starting EVA server...")
        
        # Start event bus
        await self.event_bus.start()
        
        # Start session cleanup task
        await self.session_manager.start_cleanup_task()
        
        # Start WebSocket server
        self.ws_server = await websockets.serve(
            self.ws_handler.handle_connection,
            self.config.server.host,
            self.config.server.port + 1  # WS on port+1
        )
        
        logger.info(f"WebSocket server started on ws://{self.config.server.host}:{self.config.server.port + 1}")
        
        # Start HTTP server in background
        config = uvicorn.Config(
            app=self.app,
            host=self.config.server.host,
            port=self.config.server.port,
            log_level=self.config.log_level.lower()
        )
        self.http_server = uvicorn.Server(config)
        
        asyncio.create_task(self.http_server.serve())
        
        logger.info(f"HTTP API started on http://{self.config.server.host}:{self.config.server.port}")
        logger.info("EVA server is ready!")
        
    async def stop(self):
        """Stop all servers"""
        logger.info("Stopping EVA server...")
        
        # Stop event bus
        await self.event_bus.stop()
        
        # Close WebSocket server
        if self.ws_server:
            self.ws_server.close()
            await self.ws_server.wait_closed()
            
        # Stop HTTP server
        if self.http_server:
            self.http_server.should_exit = True
            
        logger.info("EVA server stopped")
        
    async def run_forever(self):
        """Run server until interrupted"""
        await self.start()
        
        # Setup signal handlers
        loop = asyncio.get_running_loop()
        
        def signal_handler():
            asyncio.create_task(self.stop())
            
        for sig in (signal.SIGTERM, signal.SIGINT):
            loop.add_signal_handler(sig, signal_handler)
            
        # Keep running
        try:
            await asyncio.Future()
        except asyncio.CancelledError:
            pass

async def main():
    """Main entry point"""
    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Load configuration
    config = Config.from_env()
    
    # Create and run server
    server = EVAServer(config)
    await server.run_forever()

if __name__ == "__main__":
    asyncio.run(main())
