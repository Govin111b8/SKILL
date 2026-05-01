import { useState, useEffect } from 'react';
import api from '../../api/client';
import './Admin.css';

export default function AdminDisputes() {
  const [disputes, setDisputes] = useState([]);
  const [status, setStatus] = useState('open');
  const [loading, setLoading] = useState(true);

  useEffect(() => { fetchDisputes(); }, [status]);

  async function fetchDisputes() {
    setLoading(true);
    try {
      const res = await api.get(`/admin/disputes?status=${status}`);
      setDisputes(res.data.disputes);
    } catch (err) { console.error(err); }
    setLoading(false);
  }

  async function handleResolve(id) {
    const resolution = prompt('Resolution note:');
    if (!resolution) return;
    const refund = confirm('Issue refund to customer?');
    await api.post(`/admin/disputes/${id}/resolve`, {
      resolution,
      status: 'closed',
      refund,
    });
    fetchDisputes();
  }

  return (
    <div className="admin-page">
      <h1>Dispute Management</h1>

      <div className="admin-filters">
        <select value={status} onChange={e => setStatus(e.target.value)}>
          <option value="open">Open</option>
          <option value="under_review">Under Review</option>
          <option value="evidence_requested">Evidence Requested</option>
          <option value="closed">Closed</option>
        </select>
      </div>

      {loading ? <p>Loading...</p> : (
        <div className="admin-cards">
          {disputes.length === 0 && <p className="empty-state">No {status} disputes</p>}
          {disputes.map(d => (
            <div key={d.id} className="admin-card dispute-card">
              <div className="dispute-header">
                <strong>{d.booking_title}</strong>
                <span className={`badge badge-${d.status}`}>{d.status}</span>
              </div>
              <div className="dispute-details">
                <p><strong>Raised by:</strong> {d.raised_by_name} ({d.raised_by_email})</p>
                <p><strong>Against:</strong> {d.against_name} ({d.against_email})</p>
                <p><strong>Reason:</strong> {d.reason}</p>
                {d.description && <p><strong>Description:</strong> {d.description}</p>}
                <p><strong>Filed:</strong> {new Date(d.created_at).toLocaleString()}</p>
              </div>
              {status !== 'closed' && (
                <div className="dispute-actions">
                  <button className="btn btn-primary" onClick={() => handleResolve(d.id)}>Resolve</button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
