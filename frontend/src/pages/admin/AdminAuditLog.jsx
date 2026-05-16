import { useState, useEffect } from 'react';
import api from '../../api/client';
import './Admin.css';

export default function AdminAuditLog() {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);

  useEffect(() => { fetchLogs(); }, [page]);

  async function fetchLogs() {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get(`/admin/audit-log?page=${page}&limit=50`);
      const data = res.data?.logs || res.logs || [];
      setLogs(data);
      setHasMore(data.length === 50);
    } catch (err) {
      console.error('Failed to load audit log:', err);
      setError('Failed to load audit log. Please try again.');
    }
    setLoading(false);
  }

  return (
    <div className="admin-page">
      <h1>📜 Audit Log</h1>
      <p className="admin-subtitle">System activity log showing admin and system actions.</p>

      {error && <div className="admin-error">{error}</div>}

      {loading ? (
        <p className="admin-loading">Loading audit log...</p>
      ) : logs.length === 0 ? (
        <p className="admin-empty">No audit log entries found.</p>
      ) : (
        <>
          <div className="admin-table-wrapper">
            <table className="admin-table">
              <thead>
                <tr>
                  <th>Timestamp</th>
                  <th>Action</th>
                  <th>Actor</th>
                  <th>Target</th>
                  <th>Details</th>
                  <th>IP</th>
                </tr>
              </thead>
              <tbody>
                {logs.map((log, idx) => (
                  <tr key={log.id || idx}>
                    <td>{log.created_at ? new Date(log.created_at).toLocaleString() : '—'}</td>
                    <td><span className="admin-badge">{log.action || log.event_type || '—'}</span></td>
                    <td>{log.actor_name || log.admin_id?.substring(0, 8) || '—'}</td>
                    <td>{log.target_type ? `${log.target_type}:${(log.target_id || '').substring(0, 8)}` : '—'}</td>
                    <td title={JSON.stringify(log.metadata || log.details)}>
                      {JSON.stringify(log.metadata || log.details || {}).substring(0, 60)}...
                    </td>
                    <td>{log.ip_address || '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="admin-pagination">
            <button disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
              ← Previous
            </button>
            <span>Page {page}</span>
            <button disabled={!hasMore} onClick={() => setPage((p) => p + 1)}>
              Next →
            </button>
          </div>
        </>
      )}
    </div>
  );
}
