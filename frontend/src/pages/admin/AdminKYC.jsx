import { useState, useEffect } from 'react';
import api from '../../api/client';
import './Admin.css';

export default function AdminKYC() {
  const [verifications, setVerifications] = useState([]);
  const [status, setStatus] = useState('pending');
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);

  useEffect(() => { fetchKYC(); }, [status]);

  async function fetchKYC() {
    setLoading(true);
    try {
      const res = await api.get(`/admin/kyc?status=${status}`);
      setVerifications(res.data.verifications);
      setTotal(res.data.total);
    } catch (err) { console.error(err); }
    setLoading(false);
  }

  async function handleApprove(id) {
    await api.post(`/admin/kyc/${id}/approve`);
    fetchKYC();
  }

  async function handleReject(id) {
    const reason = prompt('Rejection reason:');
    if (!reason) return;
    await api.post(`/admin/kyc/${id}/reject`, { reason });
    fetchKYC();
  }

  return (
    <div className="admin-page">
      <h1>KYC Verification Queue</h1>

      <div className="admin-filters">
        <select value={status} onChange={e => setStatus(e.target.value)}>
          <option value="pending">Pending</option>
          <option value="verified">Verified</option>
          <option value="rejected">Rejected</option>
        </select>
        <span className="admin-count">{total} items</span>
      </div>

      {loading ? <p>Loading...</p> : (
        <div className="admin-cards">
          {verifications.length === 0 && <p className="empty-state">No {status} verifications</p>}
          {verifications.map(v => (
            <div key={v.id} className="admin-card kyc-card">
              <div className="kyc-header">
                <strong>{v.user_name}</strong>
                <span className="kyc-type">{v.doc_type}</span>
              </div>
              <div className="kyc-details">
                <p><strong>Email:</strong> {v.user_email}</p>
                <p><strong>Phone:</strong> {v.user_phone}</p>
                <p><strong>Doc Number:</strong> {v.doc_number}</p>
                {v.holder_name && <p><strong>Holder:</strong> {v.holder_name}</p>}
                {v.issuing_authority && <p><strong>Authority:</strong> {v.issuing_authority}</p>}
                <p><strong>Submitted:</strong> {new Date(v.created_at).toLocaleString()}</p>
              </div>
              {status === 'pending' && (
                <div className="kyc-actions">
                  <button className="btn btn-success" onClick={() => handleApprove(v.id)}>✓ Approve</button>
                  <button className="btn btn-danger" onClick={() => handleReject(v.id)}>✗ Reject</button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
