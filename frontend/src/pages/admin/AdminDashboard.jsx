import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../../api/client';
import './Admin.css';

export default function AdminDashboard() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    api.get('/admin/dashboard')
      .then(res => setStats(res.data))
      .catch(() => navigate('/login'))
      .finally(() => setLoading(false));
  }, [navigate]);

  if (loading) return <div className="admin-loading">Loading admin dashboard...</div>;
  if (!stats) return <div className="admin-error">Access denied or error loading dashboard.</div>;

  const cards = [
    { label: 'Total Users', value: stats.total_users, icon: '👥' },
    { label: 'New Users (7d)', value: stats.new_users_7d, icon: '📈' },
    { label: 'Professionals', value: stats.total_professionals, icon: '🔧' },
    { label: 'Total Bookings', value: stats.total_bookings, icon: '📋' },
    { label: 'Active Bookings', value: stats.active_bookings, icon: '⚡' },
    { label: 'New Bookings (7d)', value: stats.new_bookings_7d, icon: '🆕' },
    { label: 'Total Revenue', value: `₹${Number(stats.total_revenue).toLocaleString()}`, icon: '💰' },
    { label: 'Platform Earnings', value: `₹${Number(stats.platform_earnings).toLocaleString()}`, icon: '🏦' },
    { label: 'Open Disputes', value: stats.open_disputes, icon: '⚠️', alert: stats.open_disputes > 0 },
    { label: 'Pending KYC', value: stats.pending_kyc, icon: '🆔', alert: stats.pending_kyc > 0 },
    { label: 'Pending Complaints', value: stats.pending_complaints, icon: '🚨', alert: stats.pending_complaints > 0 },
  ];

  return (
    <div className="admin-page">
      <div className="admin-header">
        <h1>Admin Dashboard</h1>
        <p>Platform overview and management</p>
      </div>

      <div className="admin-stats-grid">
        {cards.map(card => (
          <div key={card.label} className={`admin-stat-card ${card.alert ? 'alert' : ''}`}>
            <span className="stat-icon">{card.icon}</span>
            <div className="stat-info">
              <span className="stat-value">{card.value}</span>
              <span className="stat-label">{card.label}</span>
            </div>
          </div>
        ))}
      </div>

      <div className="admin-nav-grid">
        <button onClick={() => navigate('/admin/users')} className="admin-nav-btn">👥 Manage Users</button>
        <button onClick={() => navigate('/admin/kyc')} className="admin-nav-btn">🆔 KYC Queue</button>
        <button onClick={() => navigate('/admin/disputes')} className="admin-nav-btn">⚠️ Disputes</button>
        <button onClick={() => navigate('/admin/complaints')} className="admin-nav-btn">🚨 Complaints</button>
        <button onClick={() => navigate('/admin/categories')} className="admin-nav-btn">📂 Categories</button>
        <button onClick={() => navigate('/admin/countries')} className="admin-nav-btn">🌍 Countries</button>
        <button onClick={() => navigate('/admin/audit-log')} className="admin-nav-btn">📜 Audit Log</button>
      </div>
    </div>
  );
}
