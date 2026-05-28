import { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  FiMapPin, FiPhone, FiClock, FiCheckCircle, FiAlertCircle,
  FiCamera, FiUser, FiNavigation,
} from 'react-icons/fi';
import { get } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { useWebSocket } from '../context/WebSocketContext';
import SEOMeta from '../components/SEOMeta';
import LoadingSpinner from '../components/LoadingSpinner';
import './JobTracker.css';

const STATUS_CONFIG = {
  assigned: { label: 'Professional Assigned', icon: FiUser, color: '#6366f1', step: 1 },
  en_route: { label: 'On the Way', icon: FiNavigation, color: '#f97316', step: 2 },
  arrived: { label: 'Arrived', icon: FiMapPin, color: '#3b82f6', step: 3 },
  in_progress: { label: 'Work In Progress', icon: FiClock, color: '#8b5cf6', step: 4 },
  completed: { label: 'Job Completed', icon: FiCheckCircle, color: '#10b981', step: 5 },
};

const STEPS = ['Assigned', 'On the Way', 'Arrived', 'In Progress', 'Completed'];

function ProgressBar({ status }) {
  const cfg = STATUS_CONFIG[status];
  const step = cfg?.step || 1;
  return (
    <div className="jt-progress">
      {STEPS.map((label, i) => (
        <div key={label} className={`jt-progress-step ${i + 1 <= step ? 'jt-progress-step--done' : ''} ${i + 1 === step ? 'jt-progress-step--active' : ''}`}>
          <div className="jt-step-dot">{i + 1 < step ? '✓' : i + 1 === step ? '●' : ''}</div>
          <span>{label}</span>
          {i < STEPS.length - 1 && <div className="jt-step-line" />}
        </div>
      ))}
    </div>
  );
}

export default function JobTracker() {
  const { bookingId } = useParams();
  const navigate = useNavigate();
  const { isAuthenticated } = useAuth();
  const { socket } = useWebSocket();
  const [tracking, setTracking] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const pollRef = useRef(null);

  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login');
      return;
    }
    fetchTracking();
    // Poll every 30 seconds as fallback
    pollRef.current = setInterval(fetchTracking, 30000);
    return () => clearInterval(pollRef.current);
  }, [bookingId, isAuthenticated]);

  // Real-time updates via WebSocket
  useEffect(() => {
    if (!socket) return;
    const handler = (event) => {
      try {
        const msg = JSON.parse(event.data);
        if (msg.type === 'JOB_TRACKING_UPDATE' && msg.data?.booking_id === bookingId) {
          setTracking((prev) => prev ? { ...prev, ...msg.data } : msg.data);
        }
      } catch (err) {
        // ignore parse errors
      }
    };
    socket.addEventListener('message', handler);
    return () => socket.removeEventListener('message', handler);
  }, [socket, bookingId]);

  async function fetchTracking() {
    try {
      const res = await get(`/tracking/${bookingId}`);
      setTracking(res.data);
      setError('');
    } catch (err) {
      if (err.status === 404) {
        setError('Tracking not started yet. The professional will begin tracking when they start their journey.');
      } else {
        setError(err.message || 'Failed to load tracking info.');
      }
    } finally {
      setLoading(false);
    }
  }

  if (!isAuthenticated) return null;
  if (loading) return <LoadingSpinner />;

  const cfg = tracking ? STATUS_CONFIG[tracking.status] : null;

  return (
    <div className="job-tracker-page">
      <SEOMeta title="Track Your Professional — SkillConnect" />

      <div className="jt-header">
        <button className="jt-back-btn" onClick={() => navigate(-1)}>← Back</button>
        <h1>🔴 Live Job Tracking</h1>
        <p>Booking #{bookingId?.slice(0, 8)}…</p>
      </div>

      {error ? (
        <div className="jt-error">
          <FiAlertCircle size={20} />
          <p>{error}</p>
        </div>
      ) : tracking ? (
        <div className="jt-content">
          {/* Status */}
          <div className="jt-status-card" style={{ borderColor: cfg?.color }}>
            <div className="jt-status-icon" style={{ background: cfg?.color + '20', color: cfg?.color }}>
              {cfg && <cfg.icon size={28} />}
            </div>
            <div>
              <h2 style={{ color: cfg?.color }}>{cfg?.label || tracking.status}</h2>
              {tracking.eta_minutes != null && tracking.status === 'en_route' && (
                <p className="jt-eta">ETA: ~{tracking.eta_minutes} min{tracking.eta_minutes !== 1 ? 's' : ''}</p>
              )}
              {tracking.last_location_at && (
                <p className="jt-last-update">
                  Last updated: {new Date(tracking.last_location_at).toLocaleTimeString('en-IN')}
                </p>
              )}
            </div>
          </div>

          {/* Progress bar */}
          <ProgressBar status={tracking.status} />

          {/* Professional info */}
          <div className="jt-pro-card">
            <h3>Your Professional</h3>
            <div className="jt-pro-info">
              <div className="jt-pro-avatar">{(tracking.business_name || tracking.pro_name || 'P')[0].toUpperCase()}</div>
              <div>
                <strong>{tracking.business_name || tracking.pro_name}</strong>
                {tracking.pro_phone && (
                  <a href={`tel:${tracking.pro_phone}`} className="jt-call-btn">
                    <FiPhone size={14} /> Call Professional
                  </a>
                )}
              </div>
            </div>
          </div>

          {/* Map placeholder */}
          {tracking.latitude && tracking.longitude && (
            <div className="jt-map-card">
              <h3>📍 Professional Location</h3>
              <a
                href={`https://www.google.com/maps/dir/?api=1&destination=${tracking.latitude},${tracking.longitude}`}
                target="_blank"
                rel="noopener noreferrer"
                className="jt-map-link"
              >
                <div className="jt-map-placeholder">
                  <FiMapPin size={32} />
                  <span>View on Google Maps</span>
                  <small>{Number(tracking.latitude).toFixed(4)}, {Number(tracking.longitude).toFixed(4)}</small>
                </div>
              </a>
            </div>
          )}

          {/* Before/after photos */}
          {(tracking.before_photos?.length || tracking.after_photos?.length) && (
            <div className="jt-photos-card">
              <h3><FiCamera size={16} /> Job Photos</h3>
              {tracking.before_photos?.length > 0 && (
                <div>
                  <p className="jt-photos-label">Before</p>
                  <div className="jt-photos-grid">
                    {tracking.before_photos.map((url, i) => (
                      <a key={i} href={url} target="_blank" rel="noopener noreferrer">
                        <img src={url} alt={`Before ${i + 1}`} />
                      </a>
                    ))}
                  </div>
                </div>
              )}
              {tracking.after_photos?.length > 0 && (
                <div>
                  <p className="jt-photos-label">After</p>
                  <div className="jt-photos-grid">
                    {tracking.after_photos.map((url, i) => (
                      <a key={i} href={url} target="_blank" rel="noopener noreferrer">
                        <img src={url} alt={`After ${i + 1}`} />
                      </a>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}

          {tracking.status === 'completed' && (
            <div className="jt-complete-card">
              <FiCheckCircle size={32} />
              <h3>Job Completed!</h3>
              <p>How was your experience? Leave a review to help others.</p>
              <button className="jt-review-btn" onClick={() => navigate(`/bookings`)}>
                Leave a Review
              </button>
            </div>
          )}
        </div>
      ) : (
        <div className="jt-error">
          <FiAlertCircle size={20} />
          <p>No tracking data available for this booking.</p>
        </div>
      )}
    </div>
  );
}
