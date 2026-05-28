import { useState, useEffect, useRef, useCallback } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { FiArrowLeft, FiSend, FiBriefcase, FiCheck, FiCheckCircle } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { useWebSocket } from '../context/WebSocketContext';
import { get, post } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './Chat.css';

function formatTime(dateStr) {
  if (!dateStr) return '';
  return new Date(dateStr).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });
}

function formatDateLabel(dateStr) {
  const d = new Date(dateStr);
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const msgDate = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const diffDays = Math.round((today - msgDate) / 86400000);

  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return d.toLocaleDateString(undefined, { weekday: 'long' });
  return d.toLocaleDateString(undefined, { month: 'long', day: 'numeric', year: 'numeric' });
}

function getDateKey(dateStr) {
  const d = new Date(dateStr);
  return `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
}

function Chat() {
  const { threadId } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const { subscribe, isConnected, sendTyping, sendReadReceipt } = useWebSocket();

  const [messages, setMessages] = useState([]);
  const [thread, setThread] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [inputText, setInputText] = useState('');
  const [sending, setSending] = useState(false);
  const [typingUser, setTypingUser] = useState(null);
  const [showQuickReplies, setShowQuickReplies] = useState(false);
  const [quickReplies, setQuickReplies] = useState([]);
  const [attachFile, setAttachFile] = useState(null);

  const messagesEndRef = useRef(null);
  const textareaRef = useRef(null);
  const typingTimerRef = useRef(null);
  const isTypingRef = useRef(false);

  // Scroll to bottom
  const scrollToBottom = useCallback((smooth = true) => {
    messagesEndRef.current?.scrollIntoView({ behavior: smooth ? 'smooth' : 'auto' });
  }, []);

  // Fetch thread + messages
  useEffect(() => {
    let cancelled = false;

    async function fetchMessages() {
      try {
        const res = await get(`/messages/threads/${threadId}`);
        if (cancelled) return;
        setMessages(res.data || []);
        setThread(res.thread || null);
      } catch (err) {
        if (!cancelled) setError(err.message || 'Failed to load messages');
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    fetchMessages();
    return () => { cancelled = true; };
  }, [threadId]);

  // Auto-scroll on messages change
  useEffect(() => {
    if (!loading && messages.length > 0) {
      scrollToBottom(false);
    }
  }, [loading, messages.length, scrollToBottom]);

  // Send read receipt on open
  useEffect(() => {
    if (!loading && isConnected && threadId) {
      sendReadReceipt(threadId);
    }
  }, [loading, isConnected, threadId, sendReadReceipt]);

  // Real-time: incoming messages
  useEffect(() => {
    if (!isConnected) return;

    const unsub = subscribe('message', (data) => {
      if (String(data.thread_id) !== String(threadId)) return;

      setMessages((prev) => {
        // Avoid duplicates
        if (prev.some((m) => m.id === data.id)) return prev;
        return [...prev, {
          id: data.id || `rt-${Date.now()}`,
          thread_id: data.thread_id,
          sender_id: data.sender_id,
          body: data.body,
          created_at: data.created_at,
          is_system: false,
          read_at: null,
        }];
      });

      // Mark as read if from the other person
      if (!data._self) {
        sendReadReceipt(threadId);
      }

      setTimeout(() => scrollToBottom(true), 50);
    });

    return unsub;
  }, [isConnected, subscribe, threadId, sendReadReceipt, scrollToBottom]);

  // Real-time: typing indicator
  useEffect(() => {
    if (!isConnected) return;

    const unsub = subscribe('typing', (data) => {
      if (String(data.threadId) !== String(threadId)) return;
      if (String(data.userId) === String(user?.id)) return;

      if (data.typing) {
        setTypingUser(data.userId);
      } else {
        setTypingUser(null);
      }
    });

    return unsub;
  }, [isConnected, subscribe, threadId, user]);

  // Clear typing indicator timeout
  useEffect(() => {
    if (!typingUser) return;
    const timer = setTimeout(() => setTypingUser(null), 5000);
    return () => clearTimeout(timer);
  }, [typingUser]);

  // Real-time: read receipts
  useEffect(() => {
    if (!isConnected) return;

    const unsub = subscribe('messages_read', (data) => {
      if (String(data.threadId) !== String(threadId)) return;
      if (String(data.by) === String(user?.id)) return;

      setMessages((prev) =>
        prev.map((m) => {
          if (String(m.sender_id) === String(user?.id) && !m.read_at) {
            return { ...m, read_at: data.at || new Date().toISOString() };
          }
          return m;
        }),
      );
    });

    return unsub;
  }, [isConnected, subscribe, threadId, user]);

  // Handle typing event emission
  const handleTyping = useCallback(() => {
    if (!isConnected) return;

    const otherId = thread
      ? (String(thread.customer_id) === String(user?.id) ? thread.professional_id : thread.customer_id)
      : null;

    if (!isTypingRef.current) {
      isTypingRef.current = true;
      sendTyping(threadId, otherId, true);
    }

    clearTimeout(typingTimerRef.current);
    typingTimerRef.current = setTimeout(() => {
      isTypingRef.current = false;
      sendTyping(threadId, otherId, false);
    }, 2000);
  }, [isConnected, sendTyping, threadId, thread, user]);

  // Auto-resize textarea
  const handleInput = (e) => {
    setInputText(e.target.value);
    handleTyping();

    const ta = textareaRef.current;
    if (ta) {
      ta.style.height = 'auto';
      ta.style.height = Math.min(ta.scrollHeight, 120) + 'px';
    }
  };

  // Send message
  const handleSend = async () => {
    const text = inputText.trim();
    if (!text || sending) return;

    // Stop typing indicator
    clearTimeout(typingTimerRef.current);
    if (isTypingRef.current) {
      isTypingRef.current = false;
      const otherId = thread
        ? (String(thread.customer_id) === String(user?.id) ? thread.professional_id : thread.customer_id)
        : null;
      sendTyping(threadId, otherId, false);
    }

    setSending(true);
    setInputText('');
    if (textareaRef.current) textareaRef.current.style.height = 'auto';

    // Optimistic add
    const tempMsg = {
      id: `temp-${Date.now()}`,
      thread_id: threadId,
      sender_id: user?.id,
      body: text,
      created_at: new Date().toISOString(),
      is_system: false,
      read_at: null,
      _pending: true,
    };
    setMessages((prev) => [...prev, tempMsg]);
    setTimeout(() => scrollToBottom(true), 50);

    try {
      const res = await post(`/messages/threads/${threadId}`, { body: text });
      // Replace temp with real
      setMessages((prev) =>
        prev.map((m) => (m.id === tempMsg.id ? { ...res.data, _pending: false } : m)),
      );
    } catch {
      // Remove temp on error and restore input
      setMessages((prev) => prev.filter((m) => m.id !== tempMsg.id));
      setInputText(text);
    } finally {
      setSending(false);
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  // Build date-grouped messages
  const groupedMessages = [];
  let lastDateKey = null;
  for (const msg of messages) {
    const dk = getDateKey(msg.created_at);
    if (dk !== lastDateKey) {
      groupedMessages.push({ type: 'date', key: dk, label: formatDateLabel(msg.created_at) });
      lastDateKey = dk;
    }
    groupedMessages.push({ type: 'message', key: msg.id, data: msg });
  }

  const otherName = thread?.other_name || 'Chat';
  const otherAvatar = thread?.other_avatar;
  const otherInitial = ((otherName || '?')[0] || '?').toUpperCase();

  if (loading) {
    return (
      <div className="chat-page">
        <div className="chat-loading">
          <LoadingSpinner />
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="chat-page">
        <div className="chat-error">
          <p>{error}</p>
          <button className="btn btn-primary btn-sm" onClick={() => navigate('/messages')}>
            Back to Messages
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="chat-page">
      {/* Header */}
      <div className="chat-header">
        <button className="chat-back-btn" onClick={() => navigate('/messages')} aria-label="Back">
          <FiArrowLeft size={20} />
        </button>
        <div className="chat-header-avatar">
          {otherAvatar ? (
            <img src={otherAvatar} alt={otherName} />
          ) : (
            <div className="chat-header-avatar-placeholder">{otherInitial}</div>
          )}
        </div>
        <div className="chat-header-info">
          <div className="chat-header-name">{otherName}</div>
          {isConnected && (
            <div className="chat-header-status">Online</div>
          )}
        </div>
      </div>

      {/* Booking banner */}
      {thread?.booking_id && thread?.booking_title && (
        <div className="chat-booking-banner">
          <FiBriefcase size={14} />
          <span>{thread.booking_title}</span>
          <Link to={`/bookings/${thread.booking_id}`}>View Booking</Link>
        </div>
      )}

      {/* Messages */}
      <div className="chat-messages">
        {groupedMessages.map((item) => {
          if (item.type === 'date') {
            return (
              <div key={item.key} className="chat-date-separator">
                <span>{item.label}</span>
              </div>
            );
          }

          const msg = item.data;
          const isSent = String(msg.sender_id) === String(user?.id);

          if (msg.is_system) {
            return (
              <div key={msg.id} className="chat-system">
                {msg.body}
              </div>
            );
          }

          return (
            <div key={msg.id} className={`chat-bubble-wrap chat-bubble-wrap--${isSent ? 'sent' : 'received'}`}>
              <div className={`chat-bubble chat-bubble--${isSent ? 'sent' : 'received'}`}>
                {msg.body}
              </div>
              <div className="chat-bubble-meta">
                <span className="chat-bubble-time">{formatTime(msg.created_at)}</span>
                {isSent && (
                  <span className={`chat-read-check ${msg.read_at ? 'chat-read-check--read' : ''}`}>
                    {msg.read_at ? <FiCheckCircle size={12} /> : <FiCheck size={12} />}
                  </span>
                )}
              </div>
            </div>
          );
        })}
        <div ref={messagesEndRef} />
      </div>

      {/* Typing indicator */}
      {typingUser && (
        <div className="chat-typing-indicator">
          <div className="typing-dots">
            <span />
            <span />
            <span />
          </div>
          {otherName} is typing…
        </div>
      )}

      {/* Quick Replies */}
      {showQuickReplies && quickReplies.length > 0 && (
        <div style={{ padding: '0.5rem 1rem', display: 'flex', gap: '0.5rem', flexWrap: 'wrap', background: '#f9fafb', borderTop: '1px solid #e5e7eb' }}>
          {quickReplies.map((qr, i) => (
            <button key={i} onClick={() => { setInputText(qr.content); setShowQuickReplies(false); }}
              style={{ padding: '4px 10px', background: '#fff', border: '1px solid #d1d5db', borderRadius: '16px', fontSize: '0.75rem', cursor: 'pointer' }}>
              {qr.title || qr.content?.slice(0, 30)}
            </button>
          ))}
        </div>
      )}

      {/* Input */}
      <div className="chat-input-area">
        <div style={{ display: 'flex', gap: '4px', alignItems: 'center' }}>
          <label style={{ cursor: 'pointer', padding: '6px', color: 'var(--gray-500)' }} title="Attach file">
            <input type="file" hidden onChange={e => {
              const file = e.target.files?.[0];
              if (file) {
                setAttachFile(file);
                setInputText(`📎 ${file.name}`);
              }
            }} />
            📎
          </label>
          <button type="button" onClick={async () => {
            if (!showQuickReplies && quickReplies.length === 0) {
              try {
                const res = await get('/quick-replies');
                setQuickReplies(res.data || []);
              } catch (e) { /* silent */ }
            }
            setShowQuickReplies(!showQuickReplies);
          }} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: '6px', fontSize: '1rem' }} title="Quick replies">
            ⚡
          </button>
        </div>
        <textarea
          ref={textareaRef}
          rows={1}
          placeholder="Type a message…"
          value={inputText}
          onChange={handleInput}
          onKeyDown={handleKeyDown}
        />
        <button
          className="chat-send-btn"
          onClick={handleSend}
          disabled={!inputText.trim() || sending}
          aria-label="Send message"
        >
          <FiSend size={18} />
        </button>
      </div>
    </div>
  );
}

export default Chat;
