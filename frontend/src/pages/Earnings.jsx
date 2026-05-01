import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { FiDollarSign, FiTrendingUp, FiClock, FiCalendar, FiArrowUp, FiArrowDown } from 'react-icons/fi';
import { get } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './Earnings.css';

const fmt = (amount) => `₹${Number(amount || 0).toLocaleString('en-IN')}`;

function Earnings() {
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState(null);
  const [payments, setPayments] = useState([]);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchData();
  }, []);

  async function fetchData() {
    try {
      const [earningsRes, paymentsRes] = await Promise.all([
        get('/payments/earnings'),
        get('/payments?limit=10')
      ]);
      setData(earningsRes.data || earningsRes);
      setPayments((paymentsRes.data || paymentsRes).payments || []);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  if (loading) return <LoadingSpinner />;
  if (error) return <div className="container" style={{ padding: '3rem', textAlign: 'center' }}><p className="text-error">Error: {error}</p></div>;

  const summary = data?.summary || {};
  const monthly = data?.monthly || [];

  return (
    <div className="earnings-page">
      <div className="container">
        <div className="page-header">
          <h1><FiDollarSign /> Earnings & Payouts</h1>
          <p className="page-subtitle">Track your earnings, pending payouts, and payment history</p>
        </div>

        {/* Summary Cards */}
        <div className="earnings-summary">
          <div className="earn-card earn-card--total">
            <div className="earn-card-icon"><FiTrendingUp size={24} /></div>
            <div className="earn-card-info">
              <span className="earn-card-label">Total Earned</span>
              <span className="earn-card-value">{fmt(summary.total_earned)}</span>
            </div>
          </div>
          <div className="earn-card earn-card--pending">
            <div className="earn-card-icon"><FiClock size={24} /></div>
            <div className="earn-card-info">
              <span className="earn-card-label">In Escrow (Pending)</span>
              <span className="earn-card-value">{fmt(summary.pending)}</span>
            </div>
          </div>
          <div className="earn-card earn-card--month">
            <div className="earn-card-icon"><FiCalendar size={24} /></div>
            <div className="earn-card-info">
              <span className="earn-card-label">This Month</span>
              <span className="earn-card-value">{fmt(summary.this_month)}</span>
            </div>
          </div>
          <div className="earn-card earn-card--week">
            <div className="earn-card-icon"><FiArrowUp size={24} /></div>
            <div className="earn-card-info">
              <span className="earn-card-label">Last 7 Days</span>
              <span className="earn-card-value">{fmt(summary.last_7_days)}</span>
            </div>
          </div>
        </div>

        {/* Monthly Breakdown */}
        {monthly.length > 0 && (
          <div className="earnings-section">
            <h2><FiCalendar /> Monthly Breakdown</h2>
            <div className="monthly-chart">
              {monthly.map((m, i) => {
                const maxEarned = Math.max(...monthly.map(x => Number(x.earned)));
                const heightPct = maxEarned > 0 ? (Number(m.earned) / maxEarned * 100) : 0;
                return (
                  <div key={i} className="chart-bar-wrap">
                    <div className="chart-bar" style={{ height: `${Math.max(heightPct, 5)}%` }}>
                      <span className="chart-bar-value">{fmt(m.earned)}</span>
                    </div>
                    <span className="chart-bar-label">
                      {new Date(m.month).toLocaleDateString('en-IN', { month: 'short' })}
                    </span>
                    <span className="chart-bar-jobs">{m.jobs} jobs</span>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* Recent Payments */}
        <div className="earnings-section">
          <div className="section-header">
            <h2><FiDollarSign /> Recent Transactions</h2>
          </div>
          {payments.length > 0 ? (
            <div className="payment-list">
              {payments.map((p) => (
                <div key={p.id} className="payment-item">
                  <div className="payment-info">
                    <strong>{p.booking_title || 'Payment'}</strong>
                    <span className="payment-date">{new Date(p.created_at).toLocaleDateString()}</span>
                  </div>
                  <div className="payment-right">
                    <span className={`payment-amount ${p.payee_id === p.payer_id ? '' : 'payment-amount--positive'}`}>
                      {fmt(p.amount)}
                    </span>
                    <span className={`status-badge status-badge--${p.status}`}>{p.status.replace('_', ' ')}</span>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="empty-state">
              <FiDollarSign size={40} />
              <p>No transactions yet. Complete bookings to start earning!</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default Earnings;
