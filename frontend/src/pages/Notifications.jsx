import { useState, useEffect, useCallback, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiCalendar, FiMessageSquare, FiStar, FiUsers, FiBell, FiCheck, FiAlertCircle } from 'react-icons/fi';
import { get, put } from '../api/client';
import { useWebSocket } from '../context/WebSocketContext';
import './Notifications.css';

const TYPE_META = {
  booking_request:     { icon: FiCalendar,      cls: 'booking' },
  booking_quoted:      { icon: FiCalendar,      cls: 'booking' },
  booking_accepted:    { icon: FiCalendar,      cls: 'booking' },
  booking_scheduled:   { icon: FiCalendar,      cls: 'booking' },
  booking_in_progress: { icon: FiCalendar,      cls: 'booking' },
  booking_completed:   { icon: FiCheck,         cls: 'booking' },
  booking_cancelled:   { icon: FiAlertCircle,   cls: 'booking' },
  message:             { icon: FiMessageSquare, cls: 'message' },
  review:              { icon: FiStar,          cls: 'review' },
  contact:             { icon: FiUsers,         cls: 'contact' },
};

function timeAgo(dateStr) {
  const now = Date.now();
  const diff = now - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'Just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  if (days < 7) return `${days}d ago`;
  return new Date(dateStr).toLocaleDateString();
}

function isToday(dateStr) {
  const d = new Date(dateStr);
  const now = new Date();
  return d.getFullYear() === now.getFullYear() &&
         d.getMonth() === now.getMonth() &&
         d.getDate() === now.getDate();
}

function Notifications() {
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filter, setFilter] = useState('all'); // 'all' | 'unread'
  const [markingAll, setMarkingAll] = useState(false);
  const newIdsRef = useRef(new Set());

  const navigate = useNavigate();
  const { subscribe, resetUnreadNotificationCount } = useWebSocket();

  const fetchNotifications = useCallback(async () => {
    try {
      setError(null);
      const res = await get('/notifications');
      setNotifications(res.data || []);
    } catch (err) {
      setError(err.message || 'Failed to load notifications');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchNotifications();
  }, [fetchNotifications]);

  // Reset unread badge when visiting the page
  useEffect(() => {
    resetUnreadNotificationCount();
  }, [resetUnreadNotificationCount]);

  // Real-time: push new notifications to top
  useEffect(() => {
    const unsub = subscribe('notification', (data) => {
      const newNotif = data.data || data;
      if (!newNotif.id) return;

      newIdsRef.current.add(newNotif.id);
      setNotifications((prev) => {
        if (prev.some((n) => n.id === newNotif.id)) return prev;
        return [newNotif, ...prev];
      });

      // Auto-clear the "new" animation after a delay
      setTimeout(() => {
        newIdsRef.current.delete(newNotif.id);
      }, 3000);
    });
    return unsub;
  }, [subscribe]);

  async function handleClick(notif) {
    // Mark as read
    if (!notif.read_at) {
      try {
        await put(`/notifications/${notif.id}/read`);
        setNotifications((prev) =>
          prev.map((n) => n.id === notif.id ? { ...n, read_at: new Date().toISOString() } : n)
        );
      } catch (err) { console.error('Mark notification read failed:', err.message); }
    }

    if (notif.link_url) {
      navigate(notif.link_url);
    }
  }

  async function handleMarkAllRead() {
    setMarkingAll(true);
    try {
      await put('/notifications/read-all');
      setNotifications((prev) =>
        prev.map((n) => ({ ...n, read_at: n.read_at || new Date().toISOString() }))
      );
      resetUnreadNotificationCount();
    } catch (err) { console.error('Mark all read failed:', err.message); }
    setMarkingAll(false);
  }

  const filtered = filter === 'unread'
    ? notifications.filter((n) => !n.read_at)
    : notifications;

  const unreadCount = notifications.filter((n) => !n.read_at).length;

  const todayItems = filtered.filter((n) => isToday(n.created_at));
  const earlierItems = filtered.filter((n) => !isToday(n.created_at));

  function renderIcon(type) {
    const meta = TYPE_META[type] || { icon: FiBell, cls: 'default' };
    const Icon = meta.icon;
    return (
      <div className={`notification-icon notification-icon--${meta.cls}`}>
        <Icon size={18} />
      </div>
    );
  }

  function renderItem(notif) {
    const isNew = newIdsRef.current.has(notif.id);
    return (
      <div
        key={notif.id}
        className={`notification-item${notif.read_at ? '' : ' unread'}${isNew ? ' new-item' : ''}`}
        onClick={() => handleClick(notif)}
        role="button"
        tabIndex={0}
        onKeyDown={(e) => e.key === 'Enter' && handleClick(notif)}
      >
        {renderIcon(notif.type)}
        <div className="notification-body">
          <div className="notification-title">{notif.title}</div>
          {notif.body && <div className="notification-text">{notif.body}</div>}
          <div className="notification-time">{timeAgo(notif.created_at)}</div>
        </div>
        {!notif.read_at && <div className="notification-unread-dot" />}
      </div>
    );
  }

  if (loading) {
    return (
      <div className="notifications-page">
        <div className="container">
          <div className="notifications-header">
            <h1>Notifications</h1>
          </div>
          <div className="notifications-list">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="notification-skeleton">
                <div className="skel skel-icon" />
                <div className="skel-body">
                  <div className="skel skel-line" />
                  <div className="skel skel-line" />
                  <div className="skel skel-line" />
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="notifications-page">
      <div className="container">
        <div className="notifications-header">
          <h1>Notifications</h1>
          <div className="notifications-header-actions">
            {unreadCount > 0 && (
              <button
                className="mark-all-btn"
                onClick={handleMarkAllRead}
                disabled={markingAll}
              >
                {markingAll ? 'Marking…' : 'Mark all as read'}
              </button>
            )}
          </div>
        </div>

        {error && (
          <div className="notifications-error">
            <FiAlertCircle /> {error}
          </div>
        )}

        <div className="notifications-filter">
          <button
            className={`filter-tab${filter === 'all' ? ' active' : ''}`}
            onClick={() => setFilter('all')}
          >
            All
            <span className="filter-count">{notifications.length}</span>
          </button>
          <button
            className={`filter-tab${filter === 'unread' ? ' active' : ''}`}
            onClick={() => setFilter('unread')}
          >
            Unread
            <span className="filter-count">{unreadCount}</span>
          </button>
        </div>

        {filtered.length === 0 ? (
          <div className="notifications-empty">
            <div className="notifications-empty-icon">🔔</div>
            <h3>{filter === 'unread' ? 'All caught up!' : 'No notifications yet'}</h3>
            <p>
              {filter === 'unread'
                ? 'You have no unread notifications.'
                : "When you get bookings, messages, or reviews, they'll appear here."}
            </p>
          </div>
        ) : (
          <div className="notifications-list">
            {todayItems.length > 0 && (
              <>
                <div className="notifications-group-label">Today</div>
                {todayItems.map(renderItem)}
              </>
            )}
            {earlierItems.length > 0 && (
              <>
                <div className="notifications-group-label">Earlier</div>
                {earlierItems.map(renderItem)}
              </>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

export default Notifications;
