// EVA Frontend Application
// Voice button SVG templates (static, no user data)
const MIC_SVG = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="8" y1="23" x2="16" y2="23"/></svg>';
const REC_SVG = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="5" fill="currentColor"/></svg>';

let sessionId = null;
let ws = null;
let isRecording = false;
let mediaRecorder = null;
let audioChunks = [];
let messageCount = 0;

const chatContainer = document.getElementById('chatContainer');
const messageInput = document.getElementById('messageInput');
const sendButton = document.getElementById('sendButton');
const voiceButton = document.getElementById('voiceButton');

// Audio playback
const audioContext = new (window.AudioContext || window.webkitAudioContext)();

// Status bar elements
const statusBarIndicator = document.getElementById('statusBarIndicator');
const statusBarText = document.getElementById('statusBarText');
const statusBarSession = document.getElementById('statusBarSession');

function updateStatus(connected, text, sessionText) {
    if (statusBarIndicator) {
        statusBarIndicator.classList.toggle('offline', !connected);
    }
    if (statusBarText) statusBarText.textContent = text || (connected ? 'Status: Ready' : 'Status: Offline');
    if (sessionText && statusBarSession) statusBarSession.textContent = sessionText;
}

// About modal
function openAboutModal() {
    const overlay = document.getElementById('aboutOverlay');
    if (overlay) overlay.classList.add('active');
}

function closeAboutModal() {
    const overlay = document.getElementById('aboutOverlay');
    if (overlay) overlay.classList.remove('active');
}

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeAboutModal();
});

document.getElementById('aboutOverlay')?.addEventListener('click', (e) => {
    if (e.target === e.currentTarget) closeAboutModal();
});

window.openAboutModal = openAboutModal;
window.closeAboutModal = closeAboutModal;

// Create session on load
async function createSession() {
    try {
        const response = await fetch('/sessions', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
        const data = await response.json();
        sessionId = data.session_id;
        updateStatus(true, 'Status: Ready', 'Session active');
        connectWebSocket();
    } catch (error) {
        console.error('Failed to create session:', error);
        updateStatus(false, 'Status: Failed', 'No session');
    }
}

// Connect to WebSocket
function connectWebSocket() {
    const wsPort = parseInt(window.location.port || '8000') + 1;
    ws = new WebSocket(`ws://${window.location.hostname}:${wsPort}`);

    ws.onopen = () => {
        updateStatus(true, 'Status: Connected', 'Session active');
    };

    ws.onmessage = async (event) => {
        const data = JSON.parse(event.data);

        if (data.type === 'session_created') {
            sessionId = data.session_id;
        } else if (data.type === 'audio_response') {
            addMessage(data.transcript, 'user');
            addMessage(data.response_text, 'assistant');
            if (data.audio) {
                playAudioResponse(data.audio);
            }
            updateStatus(true, 'Status: Ready', messageCount + ' messages');
        } else if (data.type === 'error') {
            addMessage('Error: ' + data.message, 'system');
        }
    };

    ws.onclose = () => {
        updateStatus(false, 'Status: Disconnected', 'Reconnecting...');
        setTimeout(connectWebSocket, 3000);
    };
}

// Play audio response
async function playAudioResponse(base64Audio) {
    try {
        const audioData = atob(base64Audio);
        const arrayBuffer = new ArrayBuffer(audioData.length);
        const view = new Uint8Array(arrayBuffer);

        for (let i = 0; i < audioData.length; i++) {
            view[i] = audioData.charCodeAt(i);
        }

        const audioBuffer = await audioContext.decodeAudioData(arrayBuffer);
        const source = audioContext.createBufferSource();
        source.buffer = audioBuffer;
        source.connect(audioContext.destination);
        source.start(0);
    } catch (error) {
        console.error('Failed to play audio:', error);
    }
}

// Send text message
async function sendMessage() {
    const message = messageInput.value.trim();
    if (!message || !sessionId) return;

    addMessage(message, 'user');
    messageInput.value = '';
    sendButton.disabled = true;
    updateStatus(true, 'Status: Thinking...', messageCount + ' messages');

    try {
        const response = await fetch('/chat', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                session_id: sessionId,
                message: message
            })
        });

        const data = await response.json();
        addMessage(data.response, 'assistant');
        updateStatus(true, 'Status: Ready', messageCount + ' messages');
    } catch (error) {
        console.error('Failed to send message:', error);
        addMessage('Failed to get a response. Please try again.', 'system');
        updateStatus(true, 'Status: Error', messageCount + ' messages');
    } finally {
        sendButton.disabled = false;
    }
}

// Voice recording
async function startRecording() {
    try {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        mediaRecorder = new MediaRecorder(stream, { mimeType: 'audio/webm' });
        audioChunks = [];

        mediaRecorder.ondataavailable = (event) => {
            audioChunks.push(event.data);
        };

        mediaRecorder.onstop = async () => {
            const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
            await sendAudioToServer(audioBlob);
            stream.getTracks().forEach(track => track.stop());
        };

        mediaRecorder.start();
        isRecording = true;
        voiceButton.classList.add('recording');
        voiceButton.innerHTML = REC_SVG + ' Recording...';
        updateStatus(true, 'Status: Recording...', messageCount + ' messages');
    } catch (error) {
        console.error('Failed to start recording:', error);
        updateStatus(true, 'Status: Mic denied', messageCount + ' messages');
    }
}

function stopRecording() {
    if (mediaRecorder && isRecording) {
        mediaRecorder.stop();
        isRecording = false;
        voiceButton.classList.remove('recording');
        voiceButton.innerHTML = MIC_SVG + ' Hold to Talk';
        updateStatus(true, 'Status: Processing...', messageCount + ' messages');
    }
}

// Send audio to server
async function sendAudioToServer(audioBlob) {
    if (!ws || ws.readyState !== WebSocket.OPEN) {
        addMessage('WebSocket not connected', 'system');
        return;
    }

    const reader = new FileReader();
    reader.onloadend = () => {
        const base64Audio = reader.result.split(',')[1];
        ws.send(JSON.stringify({
            type: 'audio_chunk',
            audio: base64Audio
        }));
    };
    reader.readAsDataURL(audioBlob);
}

// Add message to chat
function addMessage(text, sender) {
    messageCount++;
    const messageDiv = document.createElement('div');
    messageDiv.className = 'message ' + sender + '-message';
    messageDiv.textContent = text;
    chatContainer.appendChild(messageDiv);
    chatContainer.scrollTop = chatContainer.scrollHeight;
}

// Event listeners
sendButton.addEventListener('click', sendMessage);
messageInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') sendMessage();
});

voiceButton.addEventListener('mousedown', startRecording);
voiceButton.addEventListener('mouseup', stopRecording);
voiceButton.addEventListener('mouseleave', stopRecording);
voiceButton.addEventListener('touchstart', (e) => { e.preventDefault(); startRecording(); });
voiceButton.addEventListener('touchend', stopRecording);

// Initialize
createSession();
