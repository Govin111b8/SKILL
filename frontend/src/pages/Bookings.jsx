import { useState, useEffect, useCallback } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { FiCalendar, FiBriefcase, FiUser, FiAlertCircle, FiPlus } from 'react-icons/fi';
import { get } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { useWebSocket } from '../context/WebSocketContext';
import './Bookings.css';

const TABS = [
  { key: 'all', label: 'All' },
  { key: 'active', label: 'Active', statuses: ['requested', 'quoted', 'accepted', 'scheduled', 'in_progress'] },
  { key: 'completed', label: 'Completed', statuses: ['completed'] },
  { key: 'cancelled', label: 'Cancelled', statuses: ['cancelled', 'disputed', 'refunded'] },
];

function formatDate(dateStr) {
  if (!dateStr) return '';
  return new Date(dateStr).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

function formatAmount(amount) {
  if (amount == null) return '';
  return `$${Number(amount).toFixed(2)}`;
}

function StatusBadge({ status }) {
  const label = status === 'in_progress' ? 'In Progress' : status;
  return <span className={`status-badge status-badge--${status}`}>{label}</span>;
}

function BookingSkeleton() {
  return (
    <div className="booking-skeleton">
      <div className="skel skel-icon" />
      <div className="skel-body">
        <div className="skel skel-line" />
        <div className="skel skel-line" />
      </div>
      <div className="skel-right">
        <div className="skel skel-badge" />
        <div className="skel skel-amount" />
      </div>
    </div>
  );
}

export default function Bookings() {
  const { user } = useAuth();
  const { subscribe } = useWebSocket();
  const navigate = useNavigate();

  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [activeTab, setActiveTab] = useState('all');

  const role = user?.role === 'professional' ? 'pro' : 'customer';

  const fetchBookings = useCallback(async () => {
    try {
      const res = await get(`/bookings?role=${role}`);
      setBookings(res.data || res || []);
      setError(null);
    } catch (err) {
      setError(err.message || 'Failed to load bookings');
    } finally {
      setLoading(false);
    }
  }, [role]);

  useEffect(() => {
    fetchBookings();
  }, [fetchBookings]);

  useEffect(() => {
    const unsub = subscribe('booking', (msg) => {
      if (msg.action === 'created' && msg.booking) {
        setBookings((prev) => [msg.booking, ...prev]);
      } else if (msg.action === 'updated' && msg.booking) {
        setBookings((prev) =>
          prev.map((b) => (b.id === msg.booking.id ? { ...b, ...msg.booking } : b))
        );
      }
    });
    return unsub;
  }, [subscribe]);

  const filtered = activeTab === 'all'
    ? bookings
    : bookings.filter((b) => {
        const tab = TABS.find((t) => t.key === activeTab);
        return tab?.statuses?.includes(b.status);
      });

  const getCounts = (key) => {
    if (key === 'all') return bookings.length;
    const tab = TABS.find((t) => t.key === key);
    return bookings.filter((b) => tab?.statuses?.includes(b.status)).length;
  };

  return (
    <div className="bookings-page">
      <div className="container">
        <div className="bookings-header">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <h1>My Bookings</h1>
              <p>Manage your service bookings</p>
            </div>
            {role === 'customer' && (
              <Link to="/search" className="btn btn-primary btn-sm" style={{ display: 'flex', alignItems: 'center', gap: '0.375rem' }}>
                <FiPlus /> New Booking
              </Link>
            )}
          </div>
        </div>

        {error && (
          <div className="bookings-error">
            <FiAlertCircle /> {error}
          </div>
        )}

        <div className="bookings-tabs">
          {TABS.map((tab) => (
            <button
              key={tab.key}
              className={`bookings-tab${activeTab === tab.key ? ' active' : ''}`}
              onClick={() => setActiveTab(tab.key)}
            >
              {tab.label}
              <span className="tab-count">{getCounts(tab.key)}</span>
            </button>
          ))}
        </div>

        {loading ? (
          <div className="bookings-list">
            {[...Array(4)].map((_, i) => <BookingSkeleton key={i} />)}
          </div>
        ) : filtered.length === 0 ? (
          <div className="bookings-empty">
            <div className="bookings-empty-icon"><FiBriefcase /></div>
            <h3>No bookings found</h3>
            <p>
              {activeTab === 'all'
                ? "You don't have any bookings yet."
                : `No ${activeTab} bookings to show.`}
            </p>
            {role === 'customer' && (
              <Link to="/search" className="btn btn-primary">Find a Professional</Link>
            )}
          </div>
        ) : (
          <div className="bookings-list">
            {filtered.map((booking) => (
              <div
                key={booking.id}
                className="booking-card"
                onClick={() => navigate(`/bookings/${booking.id}`)}
                role="link"
                tabIndex={0}
                onKeyDown={(e) => e.key === 'Enter' && navigate(`/bookings/${booking.id}`)}
              >
                <div className="booking-card-icon">
                  <FiBriefcase />
                </div>
                <div className="booking-card-body">
                  <div className="booking-card-title">{booking.title}</div>
                  <div className="booking-card-meta">
                    <span><FiUser /> {booking.professional_name || booking.customer_name || 'N/A'}</span>
                    {booking.preferred_date && (
                      <span><FiCalendar /> {formatDate(booking.preferred_date)}</span>
                    )}
                  </div>
                </div>
                <div className="booking-card-right">
                  <StatusBadge status={booking.status} />
                  {(booking.quoted_amount || booking.final_amount) && (
                    <span className="booking-card-amount">
                      {formatAmount(booking.final_amount || booking.quoted_amount)}
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
