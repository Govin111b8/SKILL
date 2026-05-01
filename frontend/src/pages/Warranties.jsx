import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { FiShield, FiCheck, FiClock, FiAlertCircle, FiRefreshCw } from 'react-icons/fi';
import { get, post } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './Warranties.css';

const STATUS_LABELS = {
  active: 'Active',
  claimed: 'Claimed',
  expired: 'Expired',
  void: 'Void',
};

function WarrantyBadge({ status }) {
  return <span className={`warranty-badge warranty-badge--${status}`}>{STATUS_LABELS[status] || status}</span>;
}

export default function Warranties() {
  const [warranties, setWarranties] = useState([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState('');
  const [claimForm, setClaimForm] = useState({ id: null, reason: '' });

  useEffect(() => { fetchWarranties(); }, []);

  async function fetchWarranties() {
    try {
      const res = await get('/warranties');
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
      const res = await post(`/warranties/${claimForm.id}/claim`, { reason: claimForm.reason });
      setMessage('Warranty claimed! A re-service booking has been created.');
      setClaimForm({ id: null, reason: '' });
      fetchWarranties();
    } catch (err) {
      setMessage('Error: ' + (err.data?.error || err.message));
    }
  }

  if (loading) return <LoadingSpinner />;

  const active = warranties.filter(w => w.status === 'active');
  const others = warranties.filter(w => w.status !== 'active');

  return (
    <div className="warranties-page">
      <div className="container">
        <div className="page-header">
          <h1><FiShield /> Service Warranties</h1>
          <p className="page-subtitle">View your active service warranties and request re-service if needed</p>
        </div>

        {message && <div className={`alert ${message.includes('Error') ? 'alert--error' : 'alert--success'}`}>{message}</div>}

        {/* Claim Form */}
        {claimForm.id && (
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

        {/* Active Warranties */}
        {active.length > 0 && (
          <div className="warranty-section">
            <h2 className="section-title"><FiCheck /> Active Warranties ({active.length})</h2>
            <div className="warranty-grid">
              {active.map(w => (
                <WarrantyCard key={w.id} warranty={w} onClaim={() => setClaimForm({ id: w.id, reason: '' })} />
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
                <WarrantyCard key={w.id} warranty={w} />
              ))}
            </div>
          </div>
        )}

        {warranties.length === 0 && (
          <div className="empty-state">
            <FiShield size={48} />
            <h3>No Warranties Yet</h3>
            <p>Warranties are automatically created after completed bookings. <Link to="/bookings">View your bookings</Link></p>
          </div>
        )}
      </div>
    </div>
  );
}

function WarrantyCard({ warranty: w, onClaim }) {
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
          <p className="warranty-pro">{w.professional_name}</p>
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
      {isActive && !isExpired && onClaim && (
        <div className="warranty-card-footer">
          <button className="btn btn-primary btn-sm" onClick={onClaim}>
            <FiRefreshCw size={14} /> Claim Warranty
          </button>
        </div>
      )}
    </div>
  );
}
