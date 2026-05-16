import { useState, useEffect } from 'react';
import api from '../../api/client';
import './Admin.css';

export default function AdminComplaints() {
  const [complaints, setComplaints] = useState([]);
  const [status, setStatus] = useState('pending');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => { fetchComplaints(); }, [status]);

  async function fetchComplaints() {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get(`/complaints?status=${status}`);
      setComplaints(res.data?.complaints || res.complaints || []);
    } catch (err) {
      console.error('Failed to load complaints:', err);
      setError('Failed to load complaints. Please try again.');
    }
    setLoading(false);
  }

  async function handleUpdateStatus(id, newStatus) {
    try {
      await api.put(`/complaints/${id}`, { status: newStatus });
      fetchComplaints();
    } catch (err) {
      console.error('Failed to update complaint:', err);
      setError('Failed to update complaint status.');
    }
  }

  return (
    <div className="admin-page">
      <h1>🚨 Complaints Management</h1>

      <div className="admin-filters">
        {['pending', 'investigating', 'resolved', 'dismissed'].map((s) => (
          <button
            key={s}
            className={`admin-filter-btn ${status === s ? 'active' : ''}`}
            onClick={() => setStatus(s)}
          >
            {s.charAt(0).toUpperCase() + s.slice(1)}
          </button>
        ))}
      </div>

      {error && <div className="admin-error">{error}</div>}

      {loading ? (
        <p className="admin-loading">Loading complaints...</p>
      ) : complaints.length === 0 ? (
        <p className="admin-empty">No {status} complaints found.</p>
      ) : (
        <div className="admin-table-wrapper">
          <table className="admin-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Type</th>
                <th>Reporter</th>
                <th>Target</th>
                <th>Description</th>
                <th>Status</th>
                <th>Created</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {complaints.map((c) => (
                <tr key={c.id}>
                  <td>{c.id?.substring(0, 8)}...</td>
                  <td>{c.complaint_type || c.type || '—'}</td>
                  <td>{c.reporter_name || c.reporter_id?.substring(0, 8) || '—'}</td>
                  <td>{c.target_name || c.target_id?.substring(0, 8) || '—'}</td>
                  <td title={c.description}>{(c.description || '').substring(0, 80)}{c.description?.length > 80 ? '...' : ''}</td>
                  <td><span className={`admin-badge admin-badge-${c.status}`}>{c.status}</span></td>
                  <td>{c.created_at ? new Date(c.created_at).toLocaleDateString() : '—'}</td>
                  <td>
                    {status === 'pending' && (
                      <>
                        <button className="admin-action-btn" onClick={() => handleUpdateStatus(c.id, 'investigating')}>
                          Investigate
                        </button>
                        <button className="admin-action-btn danger" onClick={() => handleUpdateStatus(c.id, 'dismissed')}>
                          Dismiss
                        </button>
                      </>
                    )}
                    {status === 'investigating' && (
                      <button className="admin-action-btn success" onClick={() => handleUpdateStatus(c.id, 'resolved')}>
                        Resolve
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
