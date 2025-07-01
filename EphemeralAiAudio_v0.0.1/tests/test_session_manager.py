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
