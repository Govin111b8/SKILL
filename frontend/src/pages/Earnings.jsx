import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { FiDollarSign, FiTrendingUp, FiClock, FiCalendar, FiArrowUp, FiArrowDown, FiDownload, FiFilter, FiPieChart } from 'react-icons/fi';
import { get } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './Earnings.css';

const fmt = (amount) => `₹${Number(amount || 0).toLocaleString('en-IN')}`;

function Earnings() {
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState(null);
  const [payments, setPayments] = useState([]);
  const [error, setError] = useState(null);
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [showFilters, setShowFilters] = useState(false);

  useEffect(() => {
    fetchData();
  }, []);

  async function fetchData() {
    try {
      let earningsUrl = '/payments/earnings';
      const params = [];
      if (dateFrom) params.push(`from=${dateFrom}`);
      if (dateTo) params.push(`to=${dateTo}`);
      if (params.length) earningsUrl += '?' + params.join('&');

      const [earningsRes, paymentsRes] = await Promise.all([
        get(earningsUrl),
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

  function handleFilterApply() {
    setLoading(true);
    fetchData();
  }

  function handleExportCSV() {
    const rows = [['Date', 'Description', 'Amount', 'Status']];
    payments.forEach(p => {
      rows.push([new Date(p.created_at).toLocaleDateString(), p.booking_title || 'Payment', p.amount, p.status]);
    });
    const csv = rows.map(r => r.join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `earnings_${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  if (loading) return <LoadingSpinner />;
  if (error) return <div className="container" style={{ padding: '3rem', textAlign: 'center' }}><p className="text-error">Error: {error}</p></div>;

  const summary = data?.summary || {};
  const monthly = data?.monthly || [];

  // Service-wise breakdown (from monthly data or aggregate)
  const serviceBreakdown = data?.by_service || [];

  return (
    <div className="earnings-page">
      <div className="container">
        <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap' }}>
          <div>
            <h1><FiDollarSign /> Earnings & Payouts</h1>
            <p className="page-subtitle">Track your earnings, pending payouts, and payment history</p>
          </div>
          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <button className="btn btn-sm btn-outline" onClick={() => setShowFilters(!showFilters)}>
              <FiFilter /> Filter
            </button>
            <button className="btn btn-sm btn-outline" onClick={handleExportCSV}>
              <FiDownload /> Export CSV
            </button>
          </div>
        </div>

        {/* Date Range Filter */}
        {showFilters && (
          <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center', marginBottom: '1.5rem', padding: '1rem', background: '#f9fafb', borderRadius: '10px', flexWrap: 'wrap' }}>
            <label style={{ fontSize: '0.8rem', fontWeight: 500 }}>From:</label>
            <input type="date" value={dateFrom} onChange={e => setDateFrom(e.target.value)}
              style={{ padding: '6px 10px', borderRadius: '6px', border: '1px solid #d1d5db', fontSize: '0.85rem' }} />
            <label style={{ fontSize: '0.8rem', fontWeight: 500 }}>To:</label>
            <input type="date" value={dateTo} onChange={e => setDateTo(e.target.value)}
              style={{ padding: '6px 10px', borderRadius: '6px', border: '1px solid #d1d5db', fontSize: '0.85rem' }} />
            <button className="btn btn-sm btn-primary" onClick={handleFilterApply}>Apply</button>
            <button className="btn btn-sm btn-outline" onClick={() => { setDateFrom(''); setDateTo(''); handleFilterApply(); }}>Clear</button>
          </div>
        )}

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

        {/* Service-Wise Breakdown */}
        {serviceBreakdown.length > 0 && (
          <div className="earnings-section">
            <h2><FiPieChart /> Service-Wise Breakdown</h2>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '0.75rem', marginTop: '1rem' }}>
              {serviceBreakdown.map((s, i) => (
                <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.75rem', background: '#f9fafb', borderRadius: '8px', borderLeft: `4px solid ${['#6366f1', '#10b981', '#f59e0b', '#ec4899', '#8b5cf6'][i % 5]}` }}>
                  <div>
                    <div style={{ fontWeight: 500, fontSize: '0.85rem' }}>{s.service_name || s.category || 'Other'}</div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--gray-500)' }}>{s.count || 0} jobs</div>
                  </div>
                  <div style={{ fontWeight: 700, color: '#10b981' }}>{fmt(s.total)}</div>
                </div>
              ))}
            </div>
          </div>
        )}

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
