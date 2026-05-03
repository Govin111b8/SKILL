import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { FiAlertTriangle, FiCheck, FiClock, FiFileText, FiUpload, FiMessageSquare } from 'react-icons/fi';
import { get, post } from '../api/client';
import { useAuth } from '../context/AuthContext';
import LoadingSpinner from '../components/LoadingSpinner';
import './Disputes.css';

const STATUS_LABELS = {
  open: 'Open',
  under_review: 'Under Review',
  evidence_requested: 'Evidence Requested',
  resolved_customer: 'Resolved (Customer)',
  resolved_professional: 'Resolved (Professional)',
  escalated: 'Escalated',
  closed: 'Closed',
};

function StatusBadge({ status }) {
  return <span className={`dispute-badge dispute-badge--${status}`}>{STATUS_LABELS[status] || status}</span>;
}

export default function Disputes() {
  const { user } = useAuth();
  const [disputes, setDisputes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ booking_id: '', reason: '', description: '' });
  const [bookings, setBookings] = useState([]);
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState('');
  const [evidenceForm, setEvidenceForm] = useState({ id: null, urls: '' });

  useEffect(() => {
    fetchDisputes();
  }, []);

  async function fetchDisputes() {
    try {
      const res = await get('/disputes');
      setDisputes((res.data || res).disputes || []);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  async function fetchBookings() {
    try {
      const res = await get('/bookings');
      setBookings((res.data || res) || []);
    } catch { /* ignore */ }
  }

  function openForm() {
    setShowForm(true);
    fetchBookings();
  }

  async function handleSubmit(e) {
    e.preventDefault();
    if (!form.booking_id || !form.reason || !form.description) {
      setMessage('All fields are required');
      return;
    }
    setSubmitting(true);
    setMessage('');
    try {
      await post('/disputes', form);
      setMessage('Dispute raised successfully');
      setShowForm(false);
      setForm({ booking_id: '', reason: '', description: '' });
      fetchDisputes();
    } catch (err) {
      setMessage('Error: ' + (err.data?.error || err.message));
    } finally {
      setSubmitting(false);
    }
  }

  async function handleAddEvidence(e) {
    e.preventDefault();
    if (!evidenceForm.urls.trim()) return;
    try {
      const urls = evidenceForm.urls.split(',').map(u => u.trim()).filter(Boolean);
      await post(`/disputes/${evidenceForm.id}/evidence`, { urls });
      setEvidenceForm({ id: null, urls: '' });
      setMessage('Evidence added successfully');
      fetchDisputes();
    } catch (err) {
      setMessage('Error: ' + (err.data?.error || err.message));
    }
  }

  if (loading) return <LoadingSpinner />;

  return (
    <div className="disputes-page">
      <div className="container">
        <div className="page-header">
          <div>
            <h1><FiAlertTriangle /> Disputes</h1>
            <p className="page-subtitle">Manage disputes for your bookings</p>
          </div>
          <button className="btn btn-primary" onClick={openForm}>
            <FiFileText /> Raise Dispute
          </button>
        </div>

        {message && <div className={`alert ${message.includes('Error') ? 'alert--error' : 'alert--success'}`}>{message}</div>}

        {/* Raise Dispute Form */}
        {showForm && (
          <div className="dispute-form-card">
            <h3>Raise a New Dispute</h3>
            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label>Booking *</label>
                <select
                  value={form.booking_id}
                  onChange={e => setForm(f => ({ ...f, booking_id: e.target.value }))}
                  className="form-input"
                  required
                >
                  <option value="">Select a booking</option>
                  {bookings.map(b => (
                    <option key={b.id} value={b.id}>{b.title} — {b.status}</option>
                  ))}
                </select>
              </div>
              <div className="form-group">
                <label>Reason *</label>
                <select
                  value={form.reason}
                  onChange={e => setForm(f => ({ ...f, reason: e.target.value }))}
                  className="form-input"
                  required
                >
                  <option value="">Select reason</option>
                  <option value="poor_quality">Poor Quality Work</option>
                  <option value="no_show">Professional No-Show</option>
                  <option value="overcharging">Overcharging</option>
                  <option value="damage">Property Damage</option>
                  <option value="incomplete">Incomplete Work</option>
                  <option value="wrong_service">Wrong Service Provided</option>
                  <option value="safety_concern">Safety Concern</option>
                  <option value="other">Other</option>
                </select>
              </div>
              <div className="form-group">
                <label>Description *</label>
                <textarea
                  value={form.description}
                  onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                  placeholder="Describe the issue in detail..."
                  className="form-input"
                  rows={4}
                  required
                />
              </div>
              <div className="form-actions">
                <button type="button" className="btn btn-outline" onClick={() => setShowForm(false)}>Cancel</button>
                <button type="submit" className="btn btn-primary" disabled={submitting}>
                  {submitting ? 'Submitting...' : 'Submit Dispute'}
                </button>
              </div>
            </form>
          </div>
        )}

        {/* Evidence Form */}
        {evidenceForm.id && (
          <div className="dispute-form-card">
            <h3>Add Evidence</h3>
            <form onSubmit={handleAddEvidence}>
              <div className="form-group">
                <label>Evidence URLs (comma-separated)</label>
                <input
                  type="text"
                  value={evidenceForm.urls}
                  onChange={e => setEvidenceForm(f => ({ ...f, urls: e.target.value }))}
                  placeholder="https://example.com/photo1.jpg, https://example.com/photo2.jpg"
                  className="form-input"
                />
              </div>
              <div className="form-actions">
                <button type="button" className="btn btn-outline" onClick={() => setEvidenceForm({ id: null, urls: '' })}>Cancel</button>
                <button type="submit" className="btn btn-primary">Add Evidence</button>
              </div>
            </form>
          </div>
        )}

        {/* Disputes List */}
        {disputes.length === 0 ? (
          <div className="empty-state">
            <FiCheck size={48} />
            <h3>No Disputes</h3>
            <p>You have no active disputes. We hope it stays that way!</p>
          </div>
        ) : (
          <div className="disputes-list">
            {disputes.map(d => (
              <div key={d.id} className="dispute-card">
                <div className="dispute-header">
                  <div>
                    <h3>{d.booking_title || 'Dispute'}</h3>
                    <p className="dispute-meta">
                      Raised by: <strong>{d.raised_by_name}</strong> against <strong>{d.against_name}</strong>
                    </p>
                  </div>
                  <StatusBadge status={d.status} />
                </div>
                <div className="dispute-body">
                  <div className="dispute-field">
                    <span className="field-label">Reason:</span>
                    <span>{d.reason}</span>
                  </div>
                  <p className="dispute-desc">{d.description}</p>
                  {d.resolution_notes && (
                    <div className="dispute-field">
                      <span className="field-label">Resolution:</span>
                      <span>{d.resolution_notes}</span>
                    </div>
                  )}
                  {d.evidence_urls && d.evidence_urls.length > 0 && (
                    <div className="dispute-evidence">
                      <span className="field-label">Evidence ({d.evidence_urls.length}):</span>
                      <div className="evidence-links">
                        {d.evidence_urls.map((url, i) => (
                          <a key={i} href={url} target="_blank" rel="noopener noreferrer" className="evidence-link">
                            Evidence {i + 1}
                          </a>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
                <div className="dispute-footer">
                  <span className="dispute-date"><FiClock size={12} /> {new Date(d.created_at).toLocaleDateString()}</span>
                  {['open', 'evidence_requested'].includes(d.status) && (
                    <button
                      className="btn btn-outline btn-sm"
                      onClick={() => setEvidenceForm({ id: d.id, urls: '' })}
                    >
                      <FiUpload size={12} /> Add Evidence
                    </button>
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
