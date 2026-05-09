import { useState, useEffect, useCallback } from 'react';
import { Link, useParams, useNavigate } from 'react-router-dom';
import {
  FiArrowLeft, FiCheck, FiX, FiDollarSign, FiCalendar,
  FiMapPin, FiUser, FiMessageSquare, FiPlay, FiClock, FiAlertCircle
} from 'react-icons/fi';
import { get, post } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { useWebSocket } from '../context/WebSocketContext';
import './BookingDetail.css';

const FLOW = ['requested', 'quoted', 'accepted', 'scheduled', 'in_progress', 'completed'];
const TERMINAL = ['cancelled', 'disputed', 'refunded'];

// Humanized booking status labels (Phase 4.4)
const STATUS_LABELS = {
  requested: { label: 'Request Sent', emoji: '✉️', description: 'Waiting for professional to respond' },
  quoted: { label: 'Quote Received', emoji: '💰', description: 'Review the quote and accept or decline' },
  accepted: { label: 'Professional Confirmed', emoji: '✅', description: 'Your booking has been confirmed' },
  scheduled: { label: 'Scheduled', emoji: '📅', description: 'Job date and time confirmed' },
  in_progress: { label: 'Work Started', emoji: '🔨', description: 'Professional is working on your job' },
  completed: { label: 'Job Completed', emoji: '🎉', description: 'The job has been completed' },
  cancelled: { label: 'Cancelled', emoji: '❌', description: 'This booking was cancelled' },
  disputed: { label: 'Dispute Raised', emoji: '⚠️', description: 'A dispute has been raised' },
  refunded: { label: 'Refunded', emoji: '💸', description: 'Payment has been refunded' },
};

function humanizeStatus(status) {
  return STATUS_LABELS[status] || { label: status, emoji: '📋', description: '' };
}

function formatDate(d) {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

function formatDateTime(d) {
  if (!d) return '';
  return new Date(d).toLocaleString('en-US', {
    month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit'
  });
}

function formatAmount(a) {
  if (a == null) return null;
  return `$${Number(a).toFixed(2)}`;
}

export default function BookingDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const { subscribe } = useWebSocket();

  const [booking, setBooking] = useState(null);
  const [statusLog, setStatusLog] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [actionLoading, setActionLoading] = useState(false);
  const [modal, setModal] = useState(null); // { type: 'quote' | 'schedule' | 'cancel' }

  const isCustomer = user && booking && user.id === booking.customer_id;
  const isPro = user && booking && user.id === booking.professional_id;

  const fetchBooking = useCallback(async () => {
    try {
      const res = await get(`/bookings/${id}`);
      const data = res.data || res;
      setBooking(data.booking || data);
      setStatusLog(data.status_log || data.statusLog || []);
      setError(null);
    } catch (err) {
      setError(err.message || 'Failed to load booking');
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    fetchBooking();
  }, [fetchBooking]);

  useEffect(() => {
    const unsub = subscribe('booking', (msg) => {
      if (msg.booking && String(msg.booking.id) === String(id)) {
        setBooking((prev) => prev ? { ...prev, ...msg.booking } : msg.booking);
        if (msg.booking.status_log) setStatusLog(msg.booking.status_log);
        else fetchBooking();
      }
    });
    return unsub;
  }, [subscribe, id, fetchBooking]);

  async function transition(to, payload = {}, note = '') {
    setActionLoading(true);
    try {
      await post(`/bookings/${id}/transition`, { to, note, payload });
      await fetchBooking();
      setModal(null);
    } catch (err) {
      alert(err.message || 'Action failed');
    } finally {
      setActionLoading(false);
    }
  }

  // Progress bar with humanized labels
  function renderProgress() {
    const status = booking.status;
    const isTerminal = TERMINAL.includes(status);
    const currentIdx = FLOW.indexOf(status);

    return (
      <div className="bd-progress">
        {FLOW.map((step, i) => {
          let cls = '';
          if (isTerminal) {
            cls = i === 0 ? 'cancelled' : '';
          } else if (i < currentIdx) {
            cls = 'done';
          } else if (i === currentIdx) {
            cls = 'current';
          }

          const humanized = humanizeStatus(step);

          return (
            <div key={step} style={{ display: 'contents' }}>
              {i > 0 && (
                <div className={`bd-progress-line${i <= currentIdx && !isTerminal ? ' done' : ''}`} />
              )}
              <div className={`bd-progress-step ${cls}`}>
                <div className="bd-progress-dot">
                  {cls === 'done' ? <FiCheck size={12} /> : <span style={{ fontSize: '14px' }}>{humanized.emoji}</span>}
                </div>
                <span className="bd-progress-label">
                  {humanized.label}
                </span>
              </div>
            </div>
          );
        })}
        {isTerminal && (
          <>
            <div className="bd-progress-line" />
            <div className="bd-progress-step cancelled">
              <div className="bd-progress-dot"><FiX size={12} /></div>
              <span className="bd-progress-label">{humanizeStatus(status).label}</span>
            </div>
          </>
        )}
      </div>
    );
  }

  function renderActions() {
    const s = booking.status;
    const buttons = [];

    if (isCustomer) {
      if (s === 'quoted') {
        buttons.push(
          <Link key="pay" to={`/bookings/${id}/pay`} className="btn btn-primary">
            <FiDollarSign /> Pay & Accept Quote
          </Link>
        );
      }
      if (!['completed', 'cancelled', 'disputed', 'refunded'].includes(s)) {
        buttons.push(
          <button key="cancel" className="btn btn-outline" style={{ borderColor: 'var(--danger)', color: 'var(--danger)' }}
            disabled={actionLoading} onClick={() => setModal({ type: 'cancel' })}>
            <FiX /> Cancel Booking
          </button>
        );
      }
      if (['in_progress', 'completed'].includes(s)) {
        buttons.push(
          <Link key="dispute" to={`/disputes`} className="btn btn-outline btn-sm" style={{ borderColor: '#f59e0b', color: '#92400e' }}>
            <FiAlertCircle /> Raise Dispute
          </Link>
        );
      }
    }

    if (isPro) {
      if (s === 'requested') {
        buttons.push(
          <button key="quote" className="btn btn-primary" disabled={actionLoading}
            onClick={() => setModal({ type: 'quote' })}>
            <FiDollarSign /> Send Quote
          </button>
        );
      }
      if (s === 'accepted') {
        buttons.push(
          <button key="schedule" className="btn btn-primary" disabled={actionLoading}
            onClick={() => setModal({ type: 'schedule' })}>
            <FiCalendar /> Schedule
          </button>
        );
      }
      if (s === 'scheduled') {
        buttons.push(
          <button key="start" className="btn btn-primary" disabled={actionLoading}
            onClick={() => transition('in_progress')}>
            <FiPlay /> Start Job
          </button>
        );
      }
      if (s === 'in_progress') {
        buttons.push(
          <button key="complete" className="btn btn-primary" style={{ background: 'var(--success)' }}
            disabled={actionLoading} onClick={() => setModal({ type: 'complete' })}>
            <FiCheck /> Complete
          </button>
        );
      }
    }

    if (buttons.length === 0) return null;

    return (
      <div className="bd-actions-card">
        <h2>Actions</h2>
        <div className="bd-actions">
          {buttons}
          <Link to={`/messages?booking=${id}`} className="bd-chat-link">
            <FiMessageSquare /> Message
          </Link>
        </div>
      </div>
    );
  }

  function renderQuoteBox() {
    if (!booking.quoted_amount) return null;
    const showAccept = isCustomer && booking.status === 'quoted';

    return (
      <div className="bd-quote-box">
        <div className="quote-label">Quoted Amount</div>
        <div className="quote-amount">{formatAmount(booking.quoted_amount)}</div>
        {showAccept && (
          <div className="quote-actions">
            <button className="btn btn-primary btn-sm" disabled={actionLoading}
              onClick={() => transition('accepted')}>
              <FiCheck /> Accept
            </button>
            <button className="btn btn-outline btn-sm" disabled={actionLoading}
              onClick={() => setModal({ type: 'cancel' })}>
              Decline
            </button>
          </div>
        )}
      </div>
    );
  }

  function renderModal() {
    if (!modal) return null;

    return (
      <div className="bd-modal-overlay" onClick={() => setModal(null)}>
        <div className="bd-modal" onClick={(e) => e.stopPropagation()}>
          {modal.type === 'quote' && <QuoteModal onSubmit={(amt, note) => transition('quoted', { quoted_amount: amt }, note)} loading={actionLoading} onClose={() => setModal(null)} />}
          {modal.type === 'schedule' && <ScheduleModal onSubmit={(dt, note) => transition('scheduled', { scheduled_for: dt }, note)} loading={actionLoading} onClose={() => setModal(null)} />}
          {modal.type === 'cancel' && <CancelModal onSubmit={(reason) => transition('cancelled', { cancellation_reason: reason })} loading={actionLoading} onClose={() => setModal(null)} />}
          {modal.type === 'complete' && <CompleteModal onSubmit={(amt, note) => transition('completed', { final_amount: amt }, note)} loading={actionLoading} onClose={() => setModal(null)} />}
        </div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="booking-detail">
        <div className="container">
          <div className="bd-loading">
            <div className="skel-block"><div className="skel skel-title" /><div className="skel skel-row" /><div className="skel skel-row" /></div>
            <div className="skel-block"><div className="skel skel-title" /><div className="skel skel-row" /><div className="skel skel-row" /></div>
          </div>
        </div>
      </div>
    );
  }

  if (error || !booking) {
    return (
      <div className="booking-detail">
        <div className="container">
          <div className="bd-error">
            <FiAlertCircle size={40} style={{ color: 'var(--gray-300)', marginBottom: '1rem' }} />
            <h2>Booking not found</h2>
            <p>{error || 'This booking does not exist or you do not have access.'}</p>
            <Link to="/bookings" className="btn btn-primary">Back to Bookings</Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="booking-detail">
      <div className="container">
        <Link to="/bookings" className="bd-back"><FiArrowLeft /> Back to Bookings</Link>

        {/* Top Info */}
        <div className="bd-top">
          <div className="bd-top-header">
            <h1>{booking.title}</h1>
            <span className={`status-badge status-badge--${booking.status}`}>
              {humanizeStatus(booking.status).emoji} {humanizeStatus(booking.status).label}
            </span>
          </div>

          <div className="bd-info-grid">
            <div className="bd-info-item">
              <span className="bd-info-label"><FiUser style={{ display: 'inline', marginRight: 4 }} />{isCustomer ? 'Professional' : 'Customer'}</span>
              <span className="bd-info-value">{isCustomer ? booking.professional_name : booking.customer_name || '—'}</span>
            </div>
            <div className="bd-info-item">
              <span className="bd-info-label"><FiCalendar style={{ display: 'inline', marginRight: 4 }} />Preferred Date</span>
              <span className="bd-info-value">{formatDate(booking.preferred_date)}</span>
            </div>
            {booking.scheduled_for && (
              <div className="bd-info-item">
                <span className="bd-info-label"><FiClock style={{ display: 'inline', marginRight: 4 }} />Scheduled</span>
                <span className="bd-info-value">{formatDateTime(booking.scheduled_for)}</span>
              </div>
            )}
            <div className="bd-info-item">
              <span className="bd-info-label"><FiMapPin style={{ display: 'inline', marginRight: 4 }} />Service Address</span>
              <span className="bd-info-value">{booking.service_address || '—'}</span>
            </div>
            {booking.final_amount != null && (
              <div className="bd-info-item">
                <span className="bd-info-label"><FiDollarSign style={{ display: 'inline', marginRight: 4 }} />Final Amount</span>
                <span className="bd-info-value" style={{ fontWeight: 700, color: 'var(--success)' }}>{formatAmount(booking.final_amount)}</span>
              </div>
            )}
          </div>

          {booking.description && (
            <div className="bd-description">
              <h3>Description</h3>
              <p>{booking.description}</p>
            </div>
          )}
        </div>

        {/* Quote box */}
        {renderQuoteBox()}

        {/* Progress & Log */}
        <div className="bd-timeline-card">
          <h2>Status Progress</h2>
          {/* Current status description */}
          <div className="bd-status-description" style={{ padding: '8px 16px', marginBottom: '12px', background: '#f0f9ff', borderRadius: '8px', fontSize: '0.85rem', color: '#0369a1' }}>
            {humanizeStatus(booking.status).description}
          </div>
          {renderProgress()}

          {statusLog.length > 0 && (
            <div className="bd-log">
              {statusLog.map((entry, i) => (
                <div key={i} className="bd-log-item">
                  <div className={`bd-log-dot${i === 0 ? ' active' : ''}`} />
                  <div className="bd-log-content">
                    <div className="bd-log-status">
                      {humanizeStatus(entry.to_status).emoji} {humanizeStatus(entry.to_status).label}
                    </div>
                    {entry.note && <div className="bd-log-note">{entry.note}</div>}
                  </div>
                  <div className="bd-log-time">{formatDateTime(entry.created_at || entry.timestamp)}</div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Actions */}
        {renderActions()}

        {/* Modals */}
        {renderModal()}
      </div>
    </div>
  );
}

/* ---- Modals ---- */

function QuoteModal({ onSubmit, loading, onClose }) {
  const [amount, setAmount] = useState('');
  const [note, setNote] = useState('');
  return (
    <>
      <h3>Send Quote</h3>
      <div className="form-group">
        <label>Amount ($)</label>
        <input type="number" min="0" step="0.01" placeholder="e.g. 150.00" value={amount} onChange={(e) => setAmount(e.target.value)} />
      </div>
      <div className="form-group">
        <label>Note (optional)</label>
        <textarea rows={3} placeholder="Add details about the quote..." value={note} onChange={(e) => setNote(e.target.value)} />
      </div>
      <div className="bd-modal-actions">
        <button className="btn btn-ghost" onClick={onClose} disabled={loading}>Cancel</button>
        <button className="btn btn-primary" onClick={() => onSubmit(parseFloat(amount), note)} disabled={!amount || loading}>
          {loading ? 'Sending...' : 'Send Quote'}
        </button>
      </div>
    </>
  );
}

function ScheduleModal({ onSubmit, loading, onClose }) {
  const [date, setDate] = useState('');
  const [note, setNote] = useState('');
  return (
    <>
      <h3>Schedule Job</h3>
      <div className="form-group">
        <label>Date & Time</label>
        <input type="datetime-local" value={date} onChange={(e) => setDate(e.target.value)} />
      </div>
      <div className="form-group">
        <label>Note (optional)</label>
        <textarea rows={3} placeholder="Scheduling details..." value={note} onChange={(e) => setNote(e.target.value)} />
      </div>
      <div className="bd-modal-actions">
        <button className="btn btn-ghost" onClick={onClose} disabled={loading}>Cancel</button>
        <button className="btn btn-primary" onClick={() => onSubmit(date, note)} disabled={!date || loading}>
          {loading ? 'Scheduling...' : 'Schedule'}
        </button>
      </div>
    </>
  );
}

function CancelModal({ onSubmit, loading, onClose }) {
  const [reason, setReason] = useState('');
  return (
    <>
      <h3>Cancel Booking</h3>
      <p style={{ fontSize: '0.9rem', color: 'var(--gray-500)', marginBottom: '1rem' }}>
        Are you sure you want to cancel this booking? This cannot be undone.
      </p>
      <div className="form-group">
        <label>Reason</label>
        <textarea rows={3} placeholder="Please provide a reason..." value={reason} onChange={(e) => setReason(e.target.value)} />
      </div>
      <div className="bd-modal-actions">
        <button className="btn btn-ghost" onClick={onClose} disabled={loading}>Go Back</button>
        <button className="btn btn-primary" style={{ background: 'var(--danger)' }} onClick={() => onSubmit(reason)} disabled={!reason || loading}>
          {loading ? 'Cancelling...' : 'Cancel Booking'}
        </button>
      </div>
    </>
  );
}

function CompleteModal({ onSubmit, loading, onClose }) {
  const [amount, setAmount] = useState('');
  const [note, setNote] = useState('');
  return (
    <>
      <h3>Complete Job</h3>
      <div className="form-group">
        <label>Final Amount ($)</label>
        <input type="number" min="0" step="0.01" placeholder="e.g. 150.00" value={amount} onChange={(e) => setAmount(e.target.value)} />
      </div>
      <div className="form-group">
        <label>Note (optional)</label>
        <textarea rows={3} placeholder="Completion notes..." value={note} onChange={(e) => setNote(e.target.value)} />
      </div>
      <div className="bd-modal-actions">
        <button className="btn btn-ghost" onClick={onClose} disabled={loading}>Cancel</button>
        <button className="btn btn-primary" style={{ background: 'var(--success)' }} onClick={() => onSubmit(parseFloat(amount) || undefined, note)} disabled={loading}>
          {loading ? 'Completing...' : 'Mark Complete'}
        </button>
      </div>
    </>
  );
}
