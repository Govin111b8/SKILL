import { useState, useEffect } from 'react';
import { get, put } from '../../api/client';
import { FiCheck, FiX, FiTag } from 'react-icons/fi';
import './Admin.css';

function AdminCategoryRequests() {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [reviewNote, setReviewNote] = useState({});

  useEffect(() => {
    get('/admin/category-requests').then(res => {
      setRequests(res.data || []);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, []);

  async function handleDecision(id, status) {
    try {
      await put(`/admin/category-requests/${id}`, { status, admin_note: reviewNote[id] || '' });
      setRequests(prev => prev.map(r => r.id === id ? { ...r, status } : r));
    } catch (err) {
      alert(err.message || 'Failed to update');
    }
  }

  if (loading) return <div className="admin-loading">Loading category requests…</div>;

  return (
    <div className="admin-page">
      <div className="admin-page-header">
        <h1><FiTag /> Category Requests</h1>
        <span className="admin-badge">{requests.filter(r => r.status === 'pending').length} pending</span>
      </div>

      <div className="admin-table-wrap">
        <table className="admin-table">
          <thead>
            <tr>
              <th>Category Name</th>
              <th>Description</th>
              <th>Requester</th>
              <th>Date</th>
              <th>Status</th>
              <th>Note</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {requests.map(r => (
              <tr key={r.id}>
                <td><strong>{r.category_name}</strong></td>
                <td style={{ maxWidth: 200, fontSize: '0.85rem' }}>{r.description || '—'}</td>
                <td>{r.requester_name || r.user_id?.slice(0, 8)}</td>
                <td>{new Date(r.created_at).toLocaleDateString()}</td>
                <td>
                  <span className={`status-badge status-${r.status}`}>{r.status}</span>
                </td>
                <td>
                  {r.status === 'pending' && (
                    <input
                      type="text"
                      placeholder="Admin note…"
                      value={reviewNote[r.id] || ''}
                      onChange={e => setReviewNote(prev => ({ ...prev, [r.id]: e.target.value }))}
                      className="admin-input-sm"
                    />
                  )}
                  {r.admin_note && <span style={{ fontSize: '0.8rem', color: 'var(--gray-500)' }}>{r.admin_note}</span>}
                </td>
                <td>
                  {r.status === 'pending' && (
                    <div style={{ display: 'flex', gap: 6 }}>
                      <button className="btn-icon btn-success" onClick={() => handleDecision(r.id, 'approved')} title="Approve">
                        <FiCheck />
                      </button>
                      <button className="btn-icon btn-danger" onClick={() => handleDecision(r.id, 'rejected')} title="Reject">
                        <FiX />
                      </button>
                    </div>
                  )}
                </td>
              </tr>
            ))}
            {requests.length === 0 && (
              <tr><td colSpan={7} style={{ textAlign: 'center', color: 'var(--gray-400)', padding: '40px' }}>No category requests</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default AdminCategoryRequests;
