import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import {
  FiBarChart2, FiTrendingUp, FiStar, FiUsers, FiCalendar,
  FiDollarSign, FiActivity, FiAward
} from 'react-icons/fi';
import { get } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import StarRating from '../components/StarRating';
import './Analytics.css';

const fmt = (amount) => `₹${Number(amount || 0).toLocaleString('en-IN')}`;

function formatMonth(d) {
  if (!d) return '';
  return new Date(d).toLocaleDateString('en-IN', { month: 'short', year: '2-digit' });
}

function formatWeek(d) {
  if (!d) return '';
  return new Date(d).toLocaleDateString('en-IN', { month: 'short', day: 'numeric' });
}

export default function Analytics() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    async function fetchAnalytics() {
      try {
        const res = await get('/analytics');
        setData((res.data || res) || {});
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    }
    fetchAnalytics();
  }, []);

  if (loading) return <LoadingSpinner />;
  if (error) return (
    <div className="analytics-page">
      <div className="container" style={{ textAlign: 'center', padding: '3rem' }}>
        <p className="text-error">{error}</p>
        <p style={{ marginTop: '0.5rem', color: 'var(--gray-500)' }}>Analytics is only available for professionals.</p>
      </div>
    </div>
  );

  const { monthlyEarnings = [], weeklyBookings = [], ratingDistribution = [], topCustomers = [], recentActivity = {} } = data;

  const maxMonthlyEarning = Math.max(...monthlyEarnings.map(m => m.earnings || 0), 1);
  const maxWeeklyBooking = Math.max(...weeklyBookings.map(w => w.total || 0), 1);

  // Rating stats
  const totalRatings = ratingDistribution.reduce((sum, r) => sum + r.count, 0);
  const avgRating = totalRatings > 0
    ? ratingDistribution.reduce((sum, r) => sum + r.rating * r.count, 0) / totalRatings
    : 0;

  return (
    <div className="analytics-page">
      <div className="container">
        <div className="page-header">
          <h1><FiBarChart2 /> Performance Analytics</h1>
          <p className="page-subtitle">Track your business performance, earnings trends, and customer insights</p>
        </div>

        {/* Recent Activity Summary */}
        <div className="analytics-summary">
          <div className="summary-card">
            <div className="summary-icon" style={{ background: '#eef2ff' }}><FiCalendar color="#6366f1" /></div>
            <div className="summary-info">
              <span className="summary-value">{recentActivity.bookings_7d || 0}</span>
              <span className="summary-label">Bookings (7d)</span>
            </div>
          </div>
          <div className="summary-card">
            <div className="summary-icon" style={{ background: '#ecfdf5' }}><FiActivity color="#10b981" /></div>
            <div className="summary-info">
              <span className="summary-value">{recentActivity.bookings_30d || 0}</span>
              <span className="summary-label">Bookings (30d)</span>
            </div>
          </div>
          <div className="summary-card">
            <div className="summary-icon" style={{ background: '#fef3c7' }}><FiAward color="#f59e0b" /></div>
            <div className="summary-info">
              <span className="summary-value">{recentActivity.completed_30d || 0}</span>
              <span className="summary-label">Completed (30d)</span>
            </div>
          </div>
          <div className="summary-card">
            <div className="summary-icon" style={{ background: '#fce7f3' }}><FiStar color="#ec4899" /></div>
            <div className="summary-info">
              <span className="summary-value">{avgRating.toFixed(1)}</span>
              <span className="summary-label">Avg Rating</span>
            </div>
          </div>
        </div>

        <div className="analytics-grid">
          {/* Monthly Earnings Chart */}
          <div className="analytics-card">
            <h2><FiDollarSign /> Monthly Earnings (12 months)</h2>
            {monthlyEarnings.length > 0 ? (
              <div className="bar-chart">
                {monthlyEarnings.map((m, i) => {
                  const pct = maxMonthlyEarning > 0 ? (m.earnings / maxMonthlyEarning * 100) : 0;
                  return (
                    <div key={i} className="bar-group">
                      <div className="bar-value">{fmt(m.earnings)}</div>
                      <div className="bar-track">
                        <div className="bar-fill bar-fill--earnings" style={{ height: `${Math.max(pct, 3)}%` }} />
                      </div>
                      <div className="bar-label">{formatMonth(m.month)}</div>
                      <div className="bar-sublabel">{m.bookings_completed} jobs</div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="chart-empty">No earnings data yet. Complete bookings to see your earnings trend.</div>
            )}
          </div>

          {/* Weekly Bookings Chart */}
          <div className="analytics-card">
            <h2><FiCalendar /> Weekly Bookings (8 weeks)</h2>
            {weeklyBookings.length > 0 ? (
              <div className="bar-chart">
                {weeklyBookings.map((w, i) => {
                  const pct = maxWeeklyBooking > 0 ? (w.total / maxWeeklyBooking * 100) : 0;
                  return (
                    <div key={i} className="bar-group">
                      <div className="bar-value">{w.total}</div>
                      <div className="bar-track">
                        <div className="bar-fill bar-fill--bookings" style={{ height: `${Math.max(pct, 3)}%` }} />
                      </div>
                      <div className="bar-label">{formatWeek(w.week)}</div>
                      <div className="bar-sublabel">{w.completed}✓ {w.cancelled}✗</div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="chart-empty">No booking data yet.</div>
            )}
          </div>

          {/* Rating Distribution */}
          <div className="analytics-card">
            <h2><FiStar /> Rating Distribution</h2>
            {totalRatings > 0 ? (
              <div className="rating-distribution">
                <div className="rating-overview">
                  <span className="rating-big">{avgRating.toFixed(1)}</span>
                  <StarRating rating={avgRating} readonly size={18} />
                  <span className="rating-total">{totalRatings} review{totalRatings !== 1 ? 's' : ''}</span>
                </div>
                <div className="rating-bars">
                  {[5, 4, 3, 2, 1].map(star => {
                    const count = ratingDistribution.find(r => r.rating === star)?.count || 0;
                    const pct = totalRatings > 0 ? (count / totalRatings * 100) : 0;
                    return (
                      <div key={star} className="rating-bar-row">
                        <span className="rating-bar-label">{star}★</span>
                        <div className="rating-bar-track">
                          <div className="rating-bar-fill" style={{ width: `${pct}%` }} />
                        </div>
                        <span className="rating-bar-count">{count}</span>
                      </div>
                    );
                  })}
                </div>
              </div>
            ) : (
              <div className="chart-empty">No reviews yet.</div>
            )}
          </div>

          {/* Top Customers */}
          <div className="analytics-card">
            <h2><FiUsers /> Top Customers</h2>
            {topCustomers.length > 0 ? (
              <div className="top-customers">
                {topCustomers.map((c, i) => (
                  <div key={i} className="customer-row">
                    <div className="customer-rank">#{i + 1}</div>
                    <div className="customer-avatar">
                      {c.avatar_url ? (
                        <img src={c.avatar_url} alt={c.name} />
                      ) : (
                        <span>{c.name?.charAt(0) || '?'}</span>
                      )}
                    </div>
                    <div className="customer-info">
                      <strong>{c.name}</strong>
                      <span>{c.bookings} booking{c.bookings !== 1 ? 's' : ''}</span>
                    </div>
                    <div className="customer-spent">{fmt(c.total_spent)}</div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="chart-empty">No customer data yet.</div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
