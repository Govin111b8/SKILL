import { useState, useEffect, useCallback } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { FiCalendar, FiBriefcase, FiUser, FiAlertCircle, FiPlus, FiList } from 'react-icons/fi';
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
  return `₹${Number(amount).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
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
  const [viewMode, setViewMode] = useState('list');
  const [calendarMonth, setCalendarMonth] = useState(new Date());

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
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <div style={{ display: 'flex', gap: '0.5rem' }}>
                <button onClick={() => setViewMode('list')} className={`btn btn-sm ${viewMode === 'list' ? 'btn-primary' : 'btn-outline'}`}>
                  <FiList size={14} /> List
                </button>
                <button onClick={() => setViewMode('calendar')} className={`btn btn-sm ${viewMode === 'calendar' ? 'btn-primary' : 'btn-outline'}`}>
                  <FiCalendar size={14} /> Calendar
                </button>
              </div>
              {role === 'customer' && (
                <Link to="/search" className="btn btn-primary btn-sm" style={{ display: 'flex', alignItems: 'center', gap: '0.375rem' }}>
                  <FiPlus /> New Booking
                </Link>
              )}
            </div>
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

        {viewMode === 'calendar' ? (
          <BookingCalendar bookings={bookings} month={calendarMonth} setMonth={setCalendarMonth} />
        ) : loading ? (
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

function BookingCalendar({ bookings, month, setMonth }) {
  const year = month.getFullYear();
  const m = month.getMonth();
  const firstDay = new Date(year, m, 1).getDay();
  const daysInMonth = new Date(year, m + 1, 0).getDate();
  const days = [];
  for (let i = 0; i < firstDay; i++) days.push(null);
  for (let d = 1; d <= daysInMonth; d++) days.push(d);

  const bookingsByDay = {};
  (bookings || []).forEach(b => {
    const d = new Date(b.preferred_date || b.created_at);
    if (d.getMonth() === m && d.getFullYear() === year) {
      const day = d.getDate();
      if (!bookingsByDay[day]) bookingsByDay[day] = [];
      bookingsByDay[day].push(b);
    }
  });

  const STATUS_COLORS = {
    requested: '#fbbf24', quoted: '#60a5fa', accepted: '#34d399', confirmed: '#34d399',
    in_progress: '#818cf8', completed: '#10b981', cancelled: '#ef4444',
  };

  return (
    <div style={{ background: '#fff', borderRadius: '12px', border: '1px solid var(--gray-200, #e5e7eb)', padding: '1.5rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
        <button onClick={() => setMonth(new Date(year, m - 1, 1))} className="btn btn-outline btn-sm">&larr; Prev</button>
        <h3 style={{ margin: 0 }}>{month.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}</h3>
        <button onClick={() => setMonth(new Date(year, m + 1, 1))} className="btn btn-outline btn-sm">Next &rarr;</button>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: '2px', textAlign: 'center' }}>
        {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(d => (
          <div key={d} style={{ padding: '8px', fontWeight: 600, fontSize: '0.75rem', color: 'var(--gray-500)' }}>{d}</div>
        ))}
        {days.map((day, i) => (
          <div key={i} style={{
            padding: '8px', minHeight: '60px', borderRadius: '8px', fontSize: '0.85rem',
            background: day && bookingsByDay[day] ? '#f0fdf4' : day ? '#fafafa' : 'transparent',
            border: day ? '1px solid var(--gray-200, #e5e7eb)' : 'none',
          }}>
            {day && (
              <>
                <div style={{ fontWeight: day === new Date().getDate() && m === new Date().getMonth() && year === new Date().getFullYear() ? 700 : 400 }}>{day}</div>
                {bookingsByDay[day]?.map((b, j) => (
                  <div key={j} style={{
                    fontSize: '0.6rem', padding: '1px 4px', borderRadius: '4px', marginTop: '2px',
                    background: STATUS_COLORS[b.status] || '#e5e7eb', color: '#fff', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                  }}>
                    {b.title || b.status}
                  </div>
                ))}
              </>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
