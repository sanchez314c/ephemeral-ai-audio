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
