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
