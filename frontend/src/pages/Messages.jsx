import { useState, useEffect, useCallback } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { FiMessageSquare, FiSearch, FiBriefcase } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { useWebSocket } from '../context/WebSocketContext';
import { get } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './Messages.css';

function timeAgo(dateStr) {
  if (!dateStr) return '';
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'now';
  if (mins < 60) return `${mins}m`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h`;
  const days = Math.floor(hrs / 24);
  if (days < 7) return `${days}d`;
  return new Date(dateStr).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

function Messages() {
  const { user } = useAuth();
  const { subscribe, isConnected } = useWebSocket();
  const navigate = useNavigate();

  const [threads, setThreads] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [search, setSearch] = useState('');

  const fetchThreads = useCallback(async () => {
    try {
      const res = await get('/messages/threads');
      setThreads(res.data || []);
    } catch (err) {
      setError(err.message || 'Failed to load conversations');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchThreads();
  }, [fetchThreads]);

  // Real-time: new messages update thread list
  useEffect(() => {
    if (!isConnected) return;

    const unsub = subscribe('message', (data) => {
      setThreads((prev) => {
        const idx = prev.findIndex((t) => t.id === data.thread_id);
        if (idx === -1) {
          // New thread — refetch
          fetchThreads();
          return prev;
        }

        const updated = [...prev];
        const thread = { ...updated[idx] };
        thread.last_message = data.body;
        thread.last_message_at = data.created_at;
        thread.last_sender_id = data.sender_id;

        // Increment unread if message is from the other person
        if (!data._self) {
          const field = user?.role === 'professional' ? 'pro_unread' : 'customer_unread';
          thread[field] = (thread[field] || 0) + 1;
        }

        updated.splice(idx, 1);
        return [thread, ...updated];
      });
    });

    return unsub;
  }, [isConnected, subscribe, user, fetchThreads]);

  // Real-time: read receipts clear unread
  useEffect(() => {
    if (!isConnected) return;
    return subscribe('messages_read', (data) => {
      setThreads((prev) =>
        prev.map((t) => {
          if (t.id !== data.threadId) return t;
          return { ...t, customer_unread: 0, pro_unread: 0 };
        }),
      );
    });
  }, [isConnected, subscribe]);

  const getUnread = (thread) => {
    if (!user) return 0;
    return user.role === 'professional' ? thread.pro_unread || 0 : thread.customer_unread || 0;
  };

  const filtered = threads.filter((t) => {
    if (!search.trim()) return true;
    const q = search.toLowerCase();
    return (
      (t.other_name || '').toLowerCase().includes(q) ||
      (t.last_message || '').toLowerCase().includes(q) ||
      (t.booking_title || '').toLowerCase().includes(q)
    );
  });

  if (loading) return <LoadingSpinner />;

  if (error) {
    return (
      <div className="messages-page">
        <div className="messages-empty">
          <p style={{ color: 'var(--danger)' }}>{error}</p>
          <button className="btn btn-primary btn-sm" style={{ marginTop: '1rem' }} onClick={fetchThreads}>
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="messages-page">
      <div className="messages-header">
        <h1>Messages</h1>
      </div>

      {threads.length > 0 && (
        <div className="messages-search">
          <FiSearch className="search-icon" size={16} />
          <input
            type="text"
            placeholder="Search conversations…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
      )}

      {filtered.length === 0 && threads.length === 0 && (
        <div className="messages-empty">
          <div className="messages-empty-icon">
            <FiMessageSquare size={32} />
          </div>
          <h3>No conversations yet</h3>
          <p>Messages with professionals and customers will appear here.</p>
        </div>
      )}

      {filtered.length === 0 && threads.length > 0 && (
        <div className="messages-empty">
          <p>No conversations matching &ldquo;{search}&rdquo;</p>
        </div>
      )}

      {filtered.length > 0 && (
        <div className="thread-list">
          {filtered.map((thread) => {
            const unread = getUnread(thread);
            const initial = (thread.other_name || '?')[0].toUpperCase();

            return (
              <Link
                key={thread.id}
                to={`/messages/${thread.id}`}
                className={`thread-item ${unread > 0 ? 'thread-item--unread' : ''}`}
              >
                <div className="thread-avatar">
                  {thread.other_avatar ? (
                    <img src={thread.other_avatar} alt={thread.other_name} />
                  ) : (
                    <div className="thread-avatar-placeholder">{initial}</div>
                  )}
                  {unread > 0 && <span className="thread-unread-dot" />}
                </div>

                <div className="thread-content">
                  <div className="thread-top-row">
                    <span className="thread-name">{thread.other_name || 'Unknown'}</span>
                    <span className="thread-time">{timeAgo(thread.last_message_at)}</span>
                  </div>
                  <div className="thread-bottom-row">
                    <span className="thread-preview">
                      {thread.last_sender_id === user?.id && 'You: '}
                      {thread.last_message || 'No messages yet'}
                    </span>
                    {unread > 0 && <span className="thread-badge">{unread > 99 ? '99+' : unread}</span>}
                  </div>
                  {thread.booking_title && (
                    <span className="thread-booking-tag">
                      <FiBriefcase size={11} />
                      {thread.booking_title}
                    </span>
                  )}
                </div>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}

export default Messages;
