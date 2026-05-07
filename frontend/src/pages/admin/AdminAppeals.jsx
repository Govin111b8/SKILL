import { useState, useEffect } from 'react';
import { get, put } from '../../api/client';
import { FiCheck, FiX, FiAlertCircle } from 'react-icons/fi';
import './Admin.css';

function AdminAppeals() {
  const [appeals, setAppeals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [reviewNote, setReviewNote] = useState({});

  useEffect(() => {
    get('/admin/appeals').then(res => {
      setAppeals(res.data || []);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, []);

  async function handleDecision(id, status) {
    try {
      await put(`/admin/appeals/${id}`, { status, review_note: reviewNote[id] || '' });
      setAppeals(prev => prev.map(a => a.id === id ? { ...a, status } : a));
    } catch (err) {
      alert(err.message || 'Failed to update appeal');
    }
  }

  if (loading) return <div className="admin-loading">Loading appeals…</div>;

  return (
    <div className="admin-page">
      <div className="admin-page-header">
        <h1><FiAlertCircle /> Appeals</h1>
        <span className="admin-badge">{appeals.filter(a => a.status === 'pending').length} pending</span>
      </div>

      <div className="admin-table-wrap">
        <table className="admin-table">
          <thead>
            <tr>
              <th>Appellant</th>
              <th>Reason</th>
              <th>Submitted</th>
              <th>Status</th>
              <th>Note</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {appeals.map(a => (
              <tr key={a.id}>
                <td>
                  <div><strong>{a.appellant_name || 'Unknown'}</strong></div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--gray-500)' }}>{a.appellant_email}</div>
                </td>
                <td style={{ maxWidth: 240, fontSize: '0.85rem' }}>{a.reason}</td>
                <td>{new Date(a.created_at).toLocaleDateString()}</td>
                <td><span className={`status-badge status-${a.status}`}>{a.status}</span></td>
                <td>
                  {a.status === 'pending' && (
                    <input
                      type="text"
                      placeholder="Review note…"
                      value={reviewNote[a.id] || ''}
                      onChange={e => setReviewNote(prev => ({ ...prev, [a.id]: e.target.value }))}
                      className="admin-input-sm"
                    />
                  )}
                  {a.review_note && <span style={{ fontSize: '0.8rem', color: 'var(--gray-500)' }}>{a.review_note}</span>}
                </td>
                <td>
                  {a.status === 'pending' && (
                    <div style={{ display: 'flex', gap: 6 }}>
                      <button className="btn-icon btn-success" onClick={() => handleDecision(a.id, 'approved')} title="Approve">
                        <FiCheck />
                      </button>
                      <button className="btn-icon btn-danger" onClick={() => handleDecision(a.id, 'rejected')} title="Reject">
                        <FiX />
                      </button>
                    </div>
                  )}
                </td>
              </tr>
            ))}
            {appeals.length === 0 && (
              <tr><td colSpan={6} style={{ textAlign: 'center', color: 'var(--gray-400)', padding: '40px' }}>No appeals to review</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default AdminAppeals;
