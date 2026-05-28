import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  FiEdit, FiTrash2, FiPlus, FiBarChart2, FiStar, FiUsers,
  FiMessageSquare, FiBriefcase, FiSettings, FiToggleLeft,
  FiToggleRight, FiEye, FiPhone, FiCheckCircle, FiClock, FiTrendingUp,
  FiDollarSign, FiCalendar, FiPieChart, FiActivity, FiAward,
  FiHeart, FiShoppingBag, FiBookOpen, FiZap, FiArrowUp, FiArrowDown,
  FiTarget, FiBell, FiRepeat, FiArrowRight,
} from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { get, put, post, del } from '../api/client';
import StarRating from '../components/StarRating';
import LoadingSpinner from '../components/LoadingSpinner';
import './Dashboard.css';

const fmt = (amount) => `₹${Number(amount || 0).toLocaleString('en-IN')}`;

function Dashboard() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [dashData, setDashData] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchDashboard();
  }, []);

  async function fetchDashboard() {
    try {
      const res = await get('/dashboard');
      setDashData(res.data || res);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  if (loading) return <LoadingSpinner />;
  if (error) return (
    <div className="container" style={{ padding: '3rem 0', textAlign: 'center' }}>
      <p style={{ color: 'var(--danger, #ef4444)', marginBottom: '1rem' }}>Error: {error}</p>
      <button className="btn btn-primary btn-sm" onClick={() => { setLoading(true); setError(null); fetchDashboard(); }}>
        Try Again
      </button>
    </div>
  );

  const isProfessional = user?.role === 'professional';

  return (
    <div className="dashboard-page">
      <div className="container">
        <div className="dashboard-header">
          <div>
            <h1>Welcome, {user?.name?.split(' ')[0] || 'User'}!</h1>
            <p className="dashboard-subtitle">
              {isProfessional ? 'Manage your professional profile and track performance' : 'View your activity and manage contacts'}
            </p>
          </div>
          <Link to="/settings" className="btn btn-outline btn-sm">
            <FiSettings /> Settings
          </Link>
        </div>

        {isProfessional ? (
          <ProfessionalDashboard data={dashData} refresh={fetchDashboard} navigate={navigate} />
        ) : (
          <CustomerDashboard data={dashData} />
        )}
      </div>
    </div>
  );
}

/* ─────────────────────────────────────────────
   Customer Dashboard
   ───────────────────────────────────────────── */
function CustomerDashboard({ data }) {
  const contacts = data?.recentContacts || [];
  const reviews = data?.reviewsGiven || [];
  const bookings = data?.recentBookings || [];
  const stats = data?.stats || {};

  return (
    <>
      {/* Quick Actions */}
      <div className="quick-actions">
        <Link to="/search" className="quick-action-btn quick-action-btn--primary">
          <FiZap /> Find a Professional
        </Link>
        <Link to="/bookings" className="quick-action-btn">
          <FiCalendar /> My Bookings
        </Link>
        <Link to="/favorites" className="quick-action-btn">
          <FiHeart /> Favorites
        </Link>
        <Link to="/messages" className="quick-action-btn">
          <FiMessageSquare /> Messages
        </Link>
        <Link to="/warranties" className="quick-action-btn">
          <FiShoppingBag /> Warranties
        </Link>
        <Link to="/disputes" className="quick-action-btn">
          <FiBookOpen /> Disputes
        </Link>
        <Link to="/emergency" className="quick-action-btn quick-action-btn--danger">
          <FiZap /> Emergency
        </Link>
        <Link to="/referrals" className="quick-action-btn">
          <FiAward /> Referrals
        </Link>
        <Link to="/subscriptions" className="quick-action-btn">
          <FiRepeat /> Subscriptions
        </Link>
        <Link to="/family" className="quick-action-btn">
          <FiUsers /> Family
        </Link>
      </div>

      {/* Stats Overview */}
      <div className="stats-row">
        <div className="stat-box">
          <div className="stat-icon" style={{ background: '#ecfdf5' }}><FiDollarSign color="#10b981" /></div>
          <div><span className="stat-value">{fmt(stats.totalSpent)}</span><span className="stat-label">Total Spent</span></div>
        </div>
        <div className="stat-box">
          <div className="stat-icon" style={{ background: '#eef2ff' }}><FiActivity color="#6366f1" /></div>
          <div><span className="stat-value">{stats.activeBookings || 0}</span><span className="stat-label">Active Bookings</span></div>
        </div>
        <div className="stat-box">
          <div className="stat-icon" style={{ background: '#d1fae5' }}><FiCheckCircle color="#059669" /></div>
          <div><span className="stat-value">{stats.completedBookings || 0}</span><span className="stat-label">Completed</span></div>
        </div>
        <div className="stat-box">
          <div className="stat-icon" style={{ background: '#fce7f3' }}><FiHeart color="#ec4899" /></div>
          <div><span className="stat-value">{stats.favorites || 0}</span><span className="stat-label">Favorites</span></div>
        </div>
        <div className="stat-box">
          <div className="stat-icon" style={{ background: '#fef3c7' }}><FiStar color="#f59e0b" /></div>
          <div><span className="stat-value">{stats.totalReviews || 0}</span><span className="stat-label">Reviews Given</span></div>
        </div>
        <div className="stat-box">
          <div className="stat-icon" style={{ background: '#fee2e2' }}><FiBell color="#ef4444" /></div>
          <div>
            <span className="stat-value">{stats.unreadNotifications || 0}</span>
            <span className="stat-label">Notifications</span>
          </div>
        </div>
      </div>

      {/* Recent Bookings */}
      <div className="dashboard-card full-width" style={{ marginBottom: '1.5rem' }}>
        <div className="card-header">
          <h2><FiCalendar /> Recent Bookings</h2>
          <Link to="/bookings" className="btn btn-outline btn-sm">View All</Link>
        </div>
        {bookings.length > 0 ? (
          <ul className="dashboard-list">
            {bookings.map((b) => (
              <li key={b.id} className="dashboard-list-item">
                <div className="list-item-main">
                  <strong>{b.title || `Booking #${b.id}`}</strong>
                  <span className="list-meta">
                    with {b.professional_name} • {new Date(b.created_at).toLocaleDateString()}
                  </span>
                </div>
                <div className="list-item-right">
                  <span className={`status-badge status-badge--${b.status}`}>{b.status}</span>
                  <span className="booking-amount">
                    {b.final_amount ? fmt(b.final_amount) : b.quoted_amount ? fmt(b.quoted_amount) : '—'}
                  </span>
                </div>
              </li>
            ))}
          </ul>
        ) : (
          <div className="empty-state"><FiCalendar size={32} /><p>No bookings yet. <Link to="/search">Find a professional</Link> to get started.</p></div>
        )}
      </div>

      <div className="dashboard-grid">
        {/* Recent Contacts */}
        <div className="dashboard-card">
          <div className="card-header"><h2><FiPhone /> Recent Contacts</h2></div>
          {contacts.length > 0 ? (
            <ul className="dashboard-list">
              {contacts.map((c) => (
                <li key={c.id} className="dashboard-list-item">
                  <div className="list-item-main">
                    <strong>{c.professional_name}</strong>
                    <span className="list-meta">{c.headline || c.contact_type}</span>
                  </div>
                  <div className="list-item-right">
                    <span className={`status-badge status-badge--${c.status}`}>{c.status}</span>
                    <span className="list-date">{new Date(c.created_at).toLocaleDateString()}</span>
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <div className="empty-state"><FiUsers size={32} /><p>No contacts yet. <Link to="/search">Find a professional</Link></p></div>
          )}
        </div>

        {/* Reviews Given */}
        <div className="dashboard-card">
          <div className="card-header"><h2><FiStar /> Reviews Given</h2></div>
          {reviews.length > 0 ? (
            <ul className="dashboard-list">
              {reviews.map((r) => (
                <li key={r.id} className="dashboard-list-item">
                  <div className="list-item-main">
                    <strong>{r.professional_name}</strong>
                    <StarRating rating={r.rating} readonly size={12} />
                  </div>
                  <p className="review-snippet">{r.comment}</p>
                </li>
              ))}
            </ul>
          ) : (
            <div className="empty-state"><FiStar size={32} /><p>No reviews yet</p></div>
          )}
        </div>
      </div>
    </>
  );
}

/* ─────────────────────────────────────────────
   Professional / Business Owner Dashboard
   ───────────────────────────────────────────── */
function ProfessionalDashboard({ data, refresh, navigate }) {
  const profile = data?.profile;
  const stats = data?.stats || {};
  const earnings = data?.earnings || {};
  const funnel = data?.funnel || {};
  const contacts = data?.recentRequests || [];
  const portfolio = data?.portfolio || [];
  const completeness = data?.completeness || 0;
  const needsProfile = data?.needsProfile;

  const [editMode, setEditMode] = useState(false);
  const [availability, setAvailability] = useState(profile?.availability_status || 'offline');
  const [profileForm, setProfileForm] = useState({
    headline: profile?.headline || '',
    bio: profile?.bio || '',
    pricing_estimate: profile?.pricing_estimate || '',
    years_of_experience: profile?.years_of_experience || '',
  });
  const [saving, setSaving] = useState(false);
  const [showPortfolioForm, setShowPortfolioForm] = useState(false);
  const [portfolioForm, setPortfolioForm] = useState({ title: '', description: '', media_type: 'image', media_url: '' });

  async function handleAvailabilityToggle() {
    const next = availability === 'available' ? 'offline' : 'available';
    try {
      await put('/professionals/me/availability', { availability_status: next });
      setAvailability(next);
    } catch (err) { console.error('Availability toggle failed:', err.message); }
  }

  async function handleProfileSave(e) {
    e.preventDefault();
    setSaving(true);
    try {
      await put(`/professionals/${profile.id}`, profileForm);
      setEditMode(false);
      refresh();
    } catch (err) { console.error('Profile save failed:', err.message); }
    setSaving(false);
  }

  async function handleContactAction(contactId, status) {
    try { await put(`/contacts/${contactId}/status`, { status }); refresh(); } catch (err) { console.error('Contact action failed:', err.message); }
  }

  const [savingPortfolio, setSavingPortfolio] = useState(false);

  async function handleAddPortfolio(e) {
    e.preventDefault();
    setSavingPortfolio(true);
    try {
      await post('/portfolio', portfolioForm);
      setPortfolioForm({ title: '', description: '', media_type: 'image', media_url: '' });
      setShowPortfolioForm(false);
      refresh();
    } catch (err) { console.error('Add portfolio failed:', err.message); }
    finally { setSavingPortfolio(false); }
  }

  async function handleDeletePortfolio(id) {
    try { await del(`/portfolio/${id}`); refresh(); } catch (err) { console.error('Delete portfolio failed:', err.message); }
  }

  if (needsProfile) {
    return (
      <div className="needs-profile-card" style={{ textAlign: 'center', padding: '3rem 2rem', background: 'linear-gradient(135deg, #eef2ff, #e0e7ff)', borderRadius: '16px', border: '1px solid #c7d2fe' }}>
        <FiBriefcase size={48} style={{ color: '#6366f1', marginBottom: '1rem' }} />
        <h2 style={{ marginBottom: '0.5rem' }}>Complete Your Professional Profile</h2>
        <p style={{ color: '#4b5563', marginBottom: '1.5rem', maxWidth: '400px', margin: '0 auto 1.5rem' }}>
          Set up your profile to appear in search results and start receiving customer inquiries.
        </p>
        <Link to="/onboarding/professional" className="btn btn-primary" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.5rem' }}>
          <FiArrowRight size={16} /> Start Onboarding
        </Link>
      </div>
    );
  }

  const funnelStages = [
    { key: 'requested', label: 'Requested', value: funnel.requested },
    { key: 'quoted', label: 'Quoted', value: funnel.quoted },
    { key: 'accepted', label: 'Accepted', value: funnel.accepted },
    { key: 'scheduled', label: 'Scheduled', value: funnel.scheduled },
    { key: 'inProgress', label: 'In Progress', value: funnel.inProgress },
    { key: 'completed', label: 'Completed', value: funnel.completed },
  ];
  const funnelMax = Math.max(...funnelStages.map((s) => s.value || 0), 1);

  return (
    <>
      {/* Profile Completeness */}
      {completeness < 100 && (
        <div className="completeness-bar">
          <div className="completeness-info"><span>Profile Completeness</span><strong>{completeness}%</strong></div>
          <div className="completeness-track"><div className="completeness-fill" style={{ width: `${completeness}%` }} /></div>
          <p className="completeness-hint">Complete your profile to rank higher in search</p>
        </div>
      )}

      {/* Quick Actions */}
      <div className="quick-actions">
        <Link to="/messages" className="quick-action-btn">
          <FiMessageSquare /> Messages
        </Link>
        <Link to="/bookings" className="quick-action-btn">
          <FiCalendar /> Bookings
        </Link>
        <Link to="/earnings" className="quick-action-btn quick-action-btn--primary">
          <FiDollarSign /> Earnings
        </Link>
        <Link to="/schedule" className="quick-action-btn">
          <FiClock /> Schedule
        </Link>
        <Link to="/analytics" className="quick-action-btn">
          <FiBarChart2 /> Analytics
        </Link>
        <Link to="/disputes" className="quick-action-btn">
          <FiTarget /> Disputes
        </Link>
        <Link to="/notifications" className="quick-action-btn">
          <FiBell />
          Notifications
          {stats.unreadNotifications > 0 && (
            <span className="quick-action-badge">{stats.unreadNotifications}</span>
          )}
        </Link>
        <Link to="/referrals" className="quick-action-btn">
          <FiAward /> Referrals
        </Link>
        <Link to="/settings" className="quick-action-btn">
          <FiSettings /> Settings
        </Link>
      </div>

      {/* ── Quick Action Toggles ── */}
      <div className="dashboard-card full-width" style={{ marginBottom: '1.5rem' }}>
        <div className="card-header"><h2><FiZap /> Quick Actions</h2></div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1rem', padding: '1rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0.75rem 1rem', background: availability === 'available' ? '#ecfdf5' : 'var(--gray-50, #f9fafb)', borderRadius: '10px', border: '1px solid var(--gray-200, #e5e7eb)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              {availability === 'available' ? <FiToggleRight size={20} color="#10b981" /> : <FiToggleLeft size={20} color="#9ca3af" />}
              <span style={{ fontWeight: 500, fontSize: '0.9rem' }}>Available Today</span>
            </div>
            <button
              onClick={handleAvailabilityToggle}
              style={{ padding: '4px 12px', borderRadius: '6px', border: 'none', cursor: 'pointer', fontSize: '0.8rem', fontWeight: 600, background: availability === 'available' ? '#dcfce7' : '#e5e7eb', color: availability === 'available' ? '#166534' : '#4b5563' }}
            >
              {availability === 'available' ? 'ON' : 'OFF'}
            </button>
          </div>
          <Link to={`/professionals/${profile?.id}/storefront`} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.75rem 1rem', background: 'var(--gray-50, #f9fafb)', borderRadius: '10px', border: '1px solid var(--gray-200, #e5e7eb)', textDecoration: 'none', color: 'inherit' }}>
            <FiEye size={18} color="#6366f1" />
            <span style={{ fontWeight: 500, fontSize: '0.9rem' }}>View Storefront</span>
          </Link>
          <Link to="/storefront/setup" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.75rem 1rem', background: 'var(--gray-50, #f9fafb)', borderRadius: '10px', border: '1px solid var(--gray-200, #e5e7eb)', textDecoration: 'none', color: 'inherit' }}>
            <FiEdit size={18} color="#f97316" />
            <span style={{ fontWeight: 500, fontSize: '0.9rem' }}>Edit Storefront</span>
          </Link>
          <Link to="/onboarding/professional" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.75rem 1rem', background: 'var(--gray-50, #f9fafb)', borderRadius: '10px', border: '1px solid var(--gray-200, #e5e7eb)', textDecoration: 'none', color: 'inherit' }}>
            <FiPlus size={18} color="#10b981" />
            <span style={{ fontWeight: 500, fontSize: '0.9rem' }}>Onboarding Wizard</span>
          </Link>
        </div>
      </div>

      {/* Earnings Cards */}
      <div className="earnings-row">
        <div className="earnings-card earnings-card--lifetime">
          <div className="earnings-card-icon"><FiAward /></div>
          <span className="earnings-card-label">Lifetime Earnings</span>
          <span className="earnings-card-value">{fmt(earnings.lifetime)}</span>
        </div>
        <div className="earnings-card earnings-card--month">
          <div className="earnings-card-icon"><FiCalendar /></div>
          <span className="earnings-card-label">This Month</span>
          <span className="earnings-card-value">{fmt(earnings.thisMonth)}</span>
        </div>
        <div className="earnings-card earnings-card--week">
          <div className="earnings-card-icon"><FiTrendingUp /></div>
          <span className="earnings-card-label">Last 7 Days</span>
          <span className="earnings-card-value">{fmt(earnings.last7d)}</span>
        </div>
        <div className="earnings-card earnings-card--pipeline">
          <div className="earnings-card-icon"><FiTarget /></div>
          <span className="earnings-card-label">Pipeline</span>
          <span className="earnings-card-value">{fmt(earnings.pipeline)}</span>
        </div>
      </div>

      {/* Performance Stats */}
      <div className="stats-row">
        <div className="stat-box">
          <div className="stat-icon" style={{ background: '#eef2ff' }}><FiEye color="#6366f1" /></div>
          <div><span className="stat-value">{stats.views || 0}</span><span className="stat-label">Views</span></div>
        </div>
        <div className="stat-box">
          <div className="stat-icon" style={{ background: '#ecfdf5' }}><FiPhone color="#10b981" /></div>
          <div><span className="stat-value">{stats.contacts || 0}</span><span className="stat-label">Contacts</span></div>
        </div>
        <div className="stat-box">
          <div className="stat-icon" style={{ background: '#fef3c7' }}><FiStar color="#f59e0b" /></div>
          <div><span className="stat-value">{stats.rating || '0.0'}</span><span className="stat-label">Rating</span></div>
        </div>
        <div className="stat-box">
          <div className="stat-icon" style={{ background: '#fce7f3' }}><FiMessageSquare color="#ec4899" /></div>
          <div><span className="stat-value">{stats.reviews || 0}</span><span className="stat-label">Reviews</span></div>
        </div>
        <div className="stat-box">
          <div className="stat-icon" style={{ background: '#e0e7ff' }}><FiCheckCircle color="#4f46e5" /></div>
          <div><span className="stat-value">{stats.completedJobs || 0}</span><span className="stat-label">Jobs Done</span></div>
        </div>
        <div className="stat-box">
          <div className="stat-icon" style={{ background: '#f0fdf4' }}><FiClock color="#16a34a" /></div>
          <div><span className="stat-value">{stats.responseTime || '—'}</span><span className="stat-label">Resp. Time</span></div>
        </div>
      </div>

      {/* Booking Funnel */}
      <div className="dashboard-card full-width funnel-card">
        <div className="card-header">
          <h2><FiPieChart /> Booking Funnel</h2>
          <div className="funnel-meta">
            <span className="funnel-total">{funnel.totalBookings || 0} total bookings</span>
            {funnel.conversionPct != null && (
              <span className="funnel-conversion-badge">
                <FiTarget size={12} /> {funnel.conversionPct}% conversion
              </span>
            )}
            {(funnel.cancelled > 0 || funnel.disputed > 0) && (
              <span className="funnel-cancelled">
                {funnel.cancelled > 0 && `${funnel.cancelled} cancelled`}
                {funnel.cancelled > 0 && funnel.disputed > 0 && ' · '}
                {funnel.disputed > 0 && `${funnel.disputed} disputed`}
              </span>
            )}
          </div>
        </div>
        <div className="funnel-stages">
          {funnelStages.map((stage, i) => (
            <div key={stage.key} className="funnel-stage">
              <div className="funnel-stage-bar-wrap">
                <div
                  className="funnel-stage-bar"
                  style={{ width: `${Math.max(((stage.value || 0) / funnelMax) * 100, 6)}%` }}
                />
              </div>
              <span className="funnel-stage-count">{stage.value || 0}</span>
              <span className="funnel-stage-label">{stage.label}</span>
              {i < funnelStages.length - 1 && <span className="funnel-arrow">›</span>}
            </div>
          ))}
        </div>
      </div>

      {/* Availability Toggle */}
      <div className="availability-row">
        <span className="availability-label">
          {availability === 'available' ? <FiToggleRight size={20} color="#10b981" /> : <FiToggleLeft size={20} color="#94a3b8" />}
          Status: <strong className={`avail-status avail-status--${availability}`}>{availability}</strong>
        </span>
        <button className={`btn btn-sm ${availability === 'available' ? 'btn-outline' : 'btn-primary'}`} onClick={handleAvailabilityToggle}>
          {availability === 'available' ? 'Go Offline' : 'Go Available'}
        </button>
      </div>

      {/* Main Grid — Profile, Contacts, Portfolio */}
      <div className="dashboard-grid">
        {/* Profile Card */}
        <div className="dashboard-card">
          <div className="card-header">
            <h2><FiBriefcase /> Profile</h2>
            <button className="btn btn-outline btn-sm" onClick={() => setEditMode(!editMode)}>
              <FiEdit /> {editMode ? 'Cancel' : 'Edit'}
            </button>
          </div>
          {editMode ? (
            <form onSubmit={handleProfileSave} className="profile-edit-form">
              <div className="form-group">
                <label>Headline</label>
                <input value={profileForm.headline} onChange={(e) => setProfileForm({ ...profileForm, headline: e.target.value })} />
              </div>
              <div className="form-group">
                <label>Bio</label>
                <textarea value={profileForm.bio} onChange={(e) => setProfileForm({ ...profileForm, bio: e.target.value })} rows={4} />
              </div>
              <div className="form-row">
                <div className="form-group">
                  <label>Pricing</label>
                  <input value={profileForm.pricing_estimate} onChange={(e) => setProfileForm({ ...profileForm, pricing_estimate: e.target.value })} />
                </div>
                <div className="form-group">
                  <label>Experience (yrs)</label>
                  <input type="number" value={profileForm.years_of_experience} onChange={(e) => setProfileForm({ ...profileForm, years_of_experience: e.target.value })} min="0" />
                </div>
              </div>
              <button type="submit" className="btn btn-primary" disabled={saving}>{saving ? 'Saving...' : 'Save Changes'}</button>
            </form>
          ) : (
            <div className="profile-display">
              <div className="profile-display-row"><strong>Headline</strong><span>{profile?.headline || 'Not set'}</span></div>
              <div className="profile-display-row"><strong>Bio</strong><span>{profile?.bio || 'Not set'}</span></div>
              <div className="profile-display-row"><strong>Pricing</strong><span>{profile?.pricing_estimate ? `₹${profile.pricing_estimate}/hr` : 'Not set'}</span></div>
              <div className="profile-display-row"><strong>Experience</strong><span>{profile?.years_of_experience ? `${profile.years_of_experience} yrs` : 'Not set'}</span></div>
              <div className="profile-display-row"><strong>Categories</strong><span>{profile?.categories?.map((c) => c.name).join(', ') || 'Not set'}</span></div>
              <div className="profile-display-row"><strong>Plan</strong><span className={`plan-badge plan-badge--${profile?.subscription_plan}`}>{profile?.subscription_plan}</span></div>
            </div>
          )}
        </div>

        {/* Contact Requests */}
        <div className="dashboard-card">
          <div className="card-header"><h2><FiUsers /> Contact Requests</h2></div>
          {contacts.length > 0 ? (
            <ul className="dashboard-list">
              {contacts.map((req) => (
                <li key={req.id} className="dashboard-list-item">
                  <div className="list-item-main">
                    <strong>{req.customer_name}</strong>
                    <span className="list-meta">{req.contact_type} • {req.message || 'No message'}</span>
                  </div>
                  <div className="list-item-right">
                    {req.status === 'pending' ? (
                      <div className="action-btns">
                        <button className="btn btn-sm btn-primary" onClick={() => handleContactAction(req.id, 'accepted')}>Accept</button>
                        <button className="btn btn-sm btn-outline" onClick={() => handleContactAction(req.id, 'declined')}>Decline</button>
                      </div>
                    ) : (
                      <span className={`status-badge status-badge--${req.status}`}>{req.status}</span>
                    )}
                    <span className="list-date">{new Date(req.created_at).toLocaleDateString()}</span>
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <div className="empty-state"><FiUsers size={32} /><p>No requests yet</p></div>
          )}
        </div>

        {/* Portfolio */}
        <div className="dashboard-card full-width">
          <div className="card-header">
            <h2><FiTrendingUp /> Portfolio ({portfolio.length})</h2>
            <button className="btn btn-outline btn-sm" onClick={() => setShowPortfolioForm(!showPortfolioForm)}>
              <FiPlus /> Add
            </button>
          </div>
          {showPortfolioForm && (
            <form onSubmit={handleAddPortfolio} className="portfolio-add-form">
              <div className="form-row">
                <div className="form-group">
                  <label>Title</label>
                  <input value={portfolioForm.title} onChange={(e) => setPortfolioForm({ ...portfolioForm, title: e.target.value })} required />
                </div>
                <div className="form-group">
                  <label>Type</label>
                  <select value={portfolioForm.media_type} onChange={(e) => setPortfolioForm({ ...portfolioForm, media_type: e.target.value })}>
                    <option value="image">Image</option>
                    <option value="video">Video</option>
                    <option value="certificate">Certificate</option>
                  </select>
                </div>
              </div>
              <div className="form-group">
                <label>Media URL</label>
                <input value={portfolioForm.media_url} onChange={(e) => setPortfolioForm({ ...portfolioForm, media_url: e.target.value })} required />
              </div>
              <div className="form-group">
                <label>Description</label>
                <textarea value={portfolioForm.description} onChange={(e) => setPortfolioForm({ ...portfolioForm, description: e.target.value })} rows={2} />
              </div>
              <div className="form-actions">
                <button type="submit" className="btn btn-primary btn-sm" disabled={savingPortfolio}>{savingPortfolio ? 'Saving...' : 'Save'}</button>
                <button type="button" className="btn btn-outline btn-sm" onClick={() => setShowPortfolioForm(false)}>Cancel</button>
              </div>
            </form>
          )}
          {portfolio.length > 0 ? (
            <div className="portfolio-manage-grid">
              {portfolio.map((item) => (
                <div key={item.id} className="portfolio-manage-item">
                  {item.media_type === 'image' ? (
                    <img
                      src={item.media_url}
                      alt={item.title || 'Portfolio image'}
                      onError={(e) => { e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(item.title || 'P')}&background=eef2ff&color=6366f1&size=200`; }}
                    />
                  ) : (
                    <div className="portfolio-placeholder"><FiBriefcase size={24} /><span>{item.media_type}</span></div>
                  )}
                  <div className="portfolio-item-info">
                    <strong>{item.title || 'Untitled'}</strong>
                    {item.description && <p>{item.description}</p>}
                  </div>
                  <button className="portfolio-delete" onClick={() => handleDeletePortfolio(item.id)}><FiTrash2 /></button>
                </div>
              ))}
            </div>
          ) : (
            <div className="empty-state"><FiTrendingUp size={32} /><p>Add portfolio items to showcase your work</p></div>
          )}
        </div>
      </div>

      {/* ── Customer Insights ── */}
      <div className="dashboard-card full-width" style={{ marginBottom: '1.5rem' }}>
        <div className="card-header"><h2><FiUsers /> Customer Insights</h2></div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: '1rem', padding: '1rem' }}>
          <div style={{ textAlign: 'center', padding: '1rem', background: 'var(--gray-50, #f9fafb)', borderRadius: '10px' }}>
            <div style={{ fontSize: '1.5rem', fontWeight: 700, color: 'var(--primary, #6366f1)' }}>{stats.totalCustomers || stats.contacts || 0}</div>
            <div style={{ fontSize: '0.8rem', color: 'var(--gray-500)' }}>Total Customers</div>
          </div>
          <div style={{ textAlign: 'center', padding: '1rem', background: 'var(--gray-50, #f9fafb)', borderRadius: '10px' }}>
            <div style={{ fontSize: '1.5rem', fontWeight: 700, color: '#10b981' }}>{stats.repeatCustomers || 0}</div>
            <div style={{ fontSize: '0.8rem', color: 'var(--gray-500)' }}>Repeat Customers</div>
          </div>
          <div style={{ textAlign: 'center', padding: '1rem', background: 'var(--gray-50, #f9fafb)', borderRadius: '10px' }}>
            <div style={{ fontSize: '1.5rem', fontWeight: 700, color: '#f59e0b' }}>{stats.completedJobs || 0}</div>
            <div style={{ fontSize: '0.8rem', color: 'var(--gray-500)' }}>Jobs Completed</div>
          </div>
          <div style={{ textAlign: 'center', padding: '1rem', background: 'var(--gray-50, #f9fafb)', borderRadius: '10px' }}>
            <div style={{ fontSize: '1.5rem', fontWeight: 700, color: '#ec4899' }}>{stats.rating ? `${Number(stats.rating).toFixed(1)}★` : '—'}</div>
            <div style={{ fontSize: '0.8rem', color: 'var(--gray-500)' }}>Avg Rating</div>
          </div>
        </div>
      </div>

      {/* ── Goal Setting & Progress ── */}
      <GoalWidget />

      {/* ── Upcoming Calendar ── */}
      <UpcomingCalendarWidget />
    </>
  );
}

/* ─────────────────────────────────────────────
   Goal Setting Widget
   ───────────────────────────────────────────── */
function GoalWidget() {
  const [goals, setGoals] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ type: 'bookings', target_value: '', period: 'monthly' });

  useEffect(() => { fetchGoals(); }, []);

  async function fetchGoals() {
    try {
      const res = await get('/goals');
      setGoals(res.data || []);
    } catch (e) { /* silent */ }
  }

  async function handleCreateGoal(e) {
    e.preventDefault();
    try {
      await post('/goals', { ...form, target_value: parseInt(form.target_value) });
      setShowForm(false);
      setForm({ type: 'bookings', target_value: '', period: 'monthly' });
      fetchGoals();
    } catch (e) { /* silent */ }
  }

  return (
    <div className="dashboard-card full-width" style={{ marginBottom: '1.5rem' }}>
      <div className="card-header">
        <h2><FiTarget /> Goals & Progress</h2>
        <button className="btn btn-sm btn-outline" onClick={() => setShowForm(!showForm)}>
          {showForm ? 'Cancel' : <><FiPlus /> Set Goal</>}
        </button>
      </div>
      {showForm && (
        <form onSubmit={handleCreateGoal} style={{ padding: '1rem', display: 'flex', gap: '0.75rem', flexWrap: 'wrap', background: '#f9fafb', borderRadius: '8px', margin: '0 1rem 1rem' }}>
          <select value={form.type} onChange={e => setForm({ ...form, type: e.target.value })}
            style={{ padding: '6px 10px', borderRadius: '6px', border: '1px solid #d1d5db' }}>
            <option value="bookings">Bookings</option>
            <option value="revenue">Revenue (₹)</option>
            <option value="rating">Rating</option>
          </select>
          <input type="number" placeholder="Target" value={form.target_value}
            onChange={e => setForm({ ...form, target_value: e.target.value })} required
            style={{ padding: '6px 10px', borderRadius: '6px', border: '1px solid #d1d5db', width: '100px' }} />
          <select value={form.period} onChange={e => setForm({ ...form, period: e.target.value })}
            style={{ padding: '6px 10px', borderRadius: '6px', border: '1px solid #d1d5db' }}>
            <option value="weekly">Weekly</option>
            <option value="monthly">Monthly</option>
          </select>
          <button type="submit" className="btn btn-sm btn-primary">Save</button>
        </form>
      )}
      <div style={{ padding: '1rem' }}>
        {goals.length > 0 ? goals.map(g => {
          const pct = Math.min(100, Math.round((g.current_value / g.target_value) * 100));
          return (
            <div key={g.id} style={{ marginBottom: '1rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.85rem', marginBottom: '4px' }}>
                <span style={{ fontWeight: 500, textTransform: 'capitalize' }}>{g.type} ({g.period})</span>
                <span>{g.current_value || 0} / {g.target_value}</span>
              </div>
              <div style={{ background: '#e5e7eb', borderRadius: '999px', height: '8px', overflow: 'hidden' }}>
                <div style={{ background: pct >= 100 ? '#10b981' : '#6366f1', width: `${pct}%`, height: '100%', borderRadius: '999px', transition: 'width 0.3s' }} />
              </div>
            </div>
          );
        }) : (
          <p style={{ textAlign: 'center', color: 'var(--gray-500)', fontSize: '0.85rem' }}>No goals set yet. Set a target to track your progress!</p>
        )}
      </div>
    </div>
  );
}

/* ─────────────────────────────────────────────
   Upcoming Calendar Widget
   ───────────────────────────────────────────── */
function UpcomingCalendarWidget() {
  const [bookings, setBookings] = useState([]);

  useEffect(() => {
    async function fetch7Days() {
      try {
        const res = await get('/bookings?status=scheduled&limit=7');
        setBookings((res.data || []).slice(0, 7));
      } catch (e) { /* silent */ }
    }
    fetch7Days();
  }, []);

  return (
    <div className="dashboard-card full-width" style={{ marginBottom: '1.5rem' }}>
      <div className="card-header"><h2><FiCalendar /> Upcoming Bookings (Next 7)</h2></div>
      <div style={{ padding: '1rem' }}>
        {bookings.length > 0 ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
            {bookings.map(b => (
              <Link to={`/bookings/${b.id}`} key={b.id}
                style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.75rem', background: '#f9fafb', borderRadius: '8px', textDecoration: 'none', color: 'inherit' }}>
                <div>
                  <div style={{ fontWeight: 500, fontSize: '0.85rem' }}>{b.title || b.service_title || 'Booking'}</div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--gray-500)' }}>{b.customer_name || b.professional_name || ''}</div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontSize: '0.8rem', fontWeight: 500 }}>{b.preferred_date ? new Date(b.preferred_date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' }) : '—'}</div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--gray-500)' }}>{b.preferred_time || ''}</div>
                </div>
              </Link>
            ))}
          </div>
        ) : (
          <p style={{ textAlign: 'center', color: 'var(--gray-500)', fontSize: '0.85rem' }}>No upcoming bookings</p>
        )}
      </div>
    </div>
  );
}

export default Dashboard;
