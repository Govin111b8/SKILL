import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { FiShield, FiCheck, FiClock, FiAlertCircle, FiRefreshCw, FiTool } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { get, post } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './Warranties.css';

const STATUS_LABELS = {
  active: 'Active',
  claimed: 'Claimed',
  expired: 'Expired',
  void: 'Resolved',
};

function WarrantyBadge({ status }) {
  return <span className={`warranty-badge warranty-badge--${status}`}>{STATUS_LABELS[status] || status}</span>;
}

export default function Warranties() {
  const { user } = useAuth();
  const [warranties, setWarranties] = useState([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState('');
  const [claimForm, setClaimForm] = useState({ id: null, reason: '' });

  const isPro = user?.role === 'professional';

  useEffect(() => { fetchWarranties(); }, []);

  async function fetchWarranties() {
    try {
      const endpoint = isPro ? '/warranties/professional' : '/warranties';
      const res = await get(endpoint);
      setWarranties((res.data || res).warranties || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }

  async function handleClaim(e) {
    e.preventDefault();
    if (!claimForm.reason.trim()) {
      setMessage('Please describe the issue');
      return;
    }
    try {
      await post(`/warranties/${claimForm.id}/claim`, { reason: claimForm.reason });
      setMessage('Warranty claimed! A re-service booking has been created.');
      setClaimForm({ id: null, reason: '' });
      fetchWarranties();
    } catch (err) {
      setMessage('Error: ' + (err.data?.error || err.message));
    }
  }

  async function handleResolve(id) {
    try {
      await post(`/warranties/${id}/resolve`);
      setMessage('Warranty claim resolved successfully.');
      fetchWarranties();
    } catch (err) {
      setMessage('Error: ' + (err.data?.error || err.message));
    }
  }

  if (loading) return <LoadingSpinner />;

  const active = warranties.filter(w => w.status === 'active');
  const claimed = warranties.filter(w => w.status === 'claimed');
  const others = warranties.filter(w => w.status !== 'active' && w.status !== 'claimed');

  return (
    <div className="warranties-page">
      <div className="container">
        <div className="page-header">
          <h1><FiShield /> {isPro ? 'Warranty Claims' : 'Service Warranties'}</h1>
          <p className="page-subtitle">
            {isPro
              ? 'Review and resolve warranty claims from your customers'
              : 'View your active service warranties and request re-service if needed'}
          </p>
        </div>

        {message && <div className={`alert ${message.includes('Error') ? 'alert--error' : 'alert--success'}`}>{message}</div>}

        {/* Claim Form (customer only) */}
        {!isPro && claimForm.id && (
          <div className="warranty-form-card">
            <h3><FiRefreshCw /> Claim Warranty — Request Re-Service</h3>
            <form onSubmit={handleClaim}>
              <div className="form-group">
                <label>What went wrong? *</label>
                <textarea
                  value={claimForm.reason}
                  onChange={e => setClaimForm(f => ({ ...f, reason: e.target.value }))}
                  placeholder="Describe the issue that needs to be fixed..."
                  className="form-input"
                  rows={3}
                  required
                />
              </div>
              <div className="form-actions">
                <button type="button" className="btn btn-outline" onClick={() => setClaimForm({ id: null, reason: '' })}>Cancel</button>
                <button type="submit" className="btn btn-primary">Claim & Request Re-Service</button>
              </div>
            </form>
          </div>
        )}

        {/* Claimed Warranties — professional action required */}
        {claimed.length > 0 && (
          <div className="warranty-section">
            <h2 className="section-title"><FiAlertCircle /> {isPro ? 'Pending Claims' : 'Claimed'} ({claimed.length})</h2>
            <div className="warranty-grid">
              {claimed.map(w => (
                <WarrantyCard
                  key={w.id}
                  warranty={w}
                  isPro={isPro}
                  onResolve={isPro ? () => handleResolve(w.id) : undefined}
                />
              ))}
            </div>
          </div>
        )}

        {/* Active Warranties */}
        {active.length > 0 && (
          <div className="warranty-section">
            <h2 className="section-title"><FiCheck /> Active Warranties ({active.length})</h2>
            <div className="warranty-grid">
              {active.map(w => (
                <WarrantyCard
                  key={w.id}
                  warranty={w}
                  isPro={isPro}
                  onClaim={!isPro ? () => setClaimForm({ id: w.id, reason: '' }) : undefined}
                />
              ))}
            </div>
          </div>
        )}

        {/* Past Warranties */}
        {others.length > 0 && (
          <div className="warranty-section">
            <h2 className="section-title"><FiClock /> Past Warranties ({others.length})</h2>
            <div className="warranty-grid">
              {others.map(w => (
                <WarrantyCard key={w.id} warranty={w} isPro={isPro} />
              ))}
            </div>
          </div>
        )}

        {warranties.length === 0 && (
          <div className="empty-state">
            <FiShield size={48} />
            <h3>No Warranties Yet</h3>
            <p>
              {isPro
                ? 'No warranty claims from your customers.'
                : <>Warranties are automatically created after completed bookings. <Link to="/bookings">View your bookings</Link></>}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}

function WarrantyCard({ warranty: w, onClaim, onResolve, isPro }) {
  const isActive = w.status === 'active';
  const expiresAt = new Date(w.expires_at);
  const now = new Date();
  const daysLeft = Math.max(0, Math.ceil((expiresAt - now) / (1000 * 60 * 60 * 24)));
  const isExpired = daysLeft === 0 && isActive;

  return (
    <div className={`warranty-card ${isActive ? 'warranty-card--active' : ''}`}>
      <div className="warranty-card-header">
        <div>
          <h3>{w.booking_title || 'Service'}</h3>
          <p className="warranty-pro">
            {isPro ? `Customer: ${w.customer_name}` : w.professional_name}
          </p>
        </div>
        <WarrantyBadge status={isExpired ? 'expired' : w.status} />
      </div>
      <div className="warranty-card-body">
        <div className="warranty-detail">
          <span className="detail-label">Category</span>
          <span>{w.category_name || '—'}</span>
        </div>
        <div className="warranty-detail">
          <span className="detail-label">Duration</span>
          <span>{w.warranty_days} days</span>
        </div>
        <div className="warranty-detail">
          <span className="detail-label">Started</span>
          <span>{new Date(w.starts_at).toLocaleDateString()}</span>
        </div>
        <div className="warranty-detail">
          <span className="detail-label">Expires</span>
          <span>{expiresAt.toLocaleDateString()}</span>
        </div>
        {isPro && w.customer_phone && (
          <div className="warranty-detail">
            <span className="detail-label">Customer Phone</span>
            <span>{w.customer_phone}</span>
          </div>
        )}
        {isActive && !isExpired && (
          <div className="warranty-remaining">
            <FiClock size={14} />
            <span>{daysLeft} day{daysLeft !== 1 ? 's' : ''} remaining</span>
          </div>
        )}
        {w.claim_reason && (
          <div className="warranty-claim-info">
            <strong>Claim reason:</strong> {w.claim_reason}
          </div>
        )}
      </div>
      <div className="warranty-card-footer">
        {isActive && !isExpired && !isPro && onClaim && (
          <button className="btn btn-primary btn-sm" onClick={onClaim}>
            <FiRefreshCw size={14} /> Claim Warranty
          </button>
        )}
        {w.status === 'claimed' && isPro && onResolve && (
          <button className="btn btn-success btn-sm" onClick={onResolve}>
            <FiTool size={14} /> Mark as Resolved
          </button>
        )}
      </div>
    </div>
  );
}
