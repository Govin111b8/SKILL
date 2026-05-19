import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import {
  FiCalendar, FiClock, FiPause, FiPlay, FiX, FiPlus,
  FiRepeat, FiHome, FiDroplet, FiStar, FiTruck, FiCheck,
} from 'react-icons/fi';
import { get, post } from '../api/client';
import { useAuth } from '../context/AuthContext';
import SEOMeta from '../components/SEOMeta';
import './Subscriptions.css';

const frequencyLabels = {
  daily: 'Daily',
  weekly: 'Weekly',
  biweekly: 'Bi-weekly',
  monthly: 'Monthly',
  quarterly: 'Quarterly',
};

const statusColors = {
  active: '#10b981',
  paused: '#f59e0b',
  cancelled: '#ef4444',
  expired: '#6b7280',
};

const subscriptionCategories = [
  { name: 'Maid Service', icon: FiHome, frequency: 'daily', price: '₹3,000/mo', color: '#8b5cf6' },
  { name: 'Milk Delivery', icon: FiDroplet, frequency: 'daily', price: '₹800/mo', color: '#3b82f6' },
  { name: 'Water Delivery', icon: FiDroplet, frequency: 'daily', price: '₹500/mo', color: '#06b6d4' },
  { name: 'Tiffin Service', icon: FiTruck, frequency: 'daily', price: '₹4,500/mo', color: '#f97316' },
  { name: 'Laundry', icon: FiRepeat, frequency: 'weekly', price: '₹1,200/mo', color: '#ec4899' },
  { name: 'House Cleaning', icon: FiHome, frequency: 'weekly', price: '₹2,000/mo', color: '#10b981' },
  { name: 'Gardening', icon: FiStar, frequency: 'weekly', price: '₹1,500/mo', color: '#84cc16' },
  { name: 'Pest Control', icon: FiX, frequency: 'monthly', price: '₹800/mo', color: '#ef4444' },
  { name: 'AC Maintenance', icon: FiRepeat, frequency: 'monthly', price: '₹600/mo', color: '#6366f1' },
  { name: 'RO Service', icon: FiDroplet, frequency: 'monthly', price: '₹400/mo', color: '#0ea5e9' },
];

function Subscriptions() {
  const { isAuthenticated } = useAuth();
  const [subscriptions, setSubscriptions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');
  const [showCreate, setShowCreate] = useState(false);

  useEffect(() => {
    if (isAuthenticated) {
      fetchSubscriptions();
    } else {
      setLoading(false);
    }
  }, [isAuthenticated, filter]);

  async function fetchSubscriptions() {
    try {
      const params = filter !== 'all' ? `?status=${filter}` : '';
      const res = await get(`/subscriptions${params}`);
      setSubscriptions(res.data || []);
    } catch (err) {
      console.error('Failed to fetch subscriptions:', err);
    } finally {
      setLoading(false);
    }
  }

  async function handlePause(id) {
    try {
      await post(`/subscriptions/${id}/pause`, { reason: 'Paused by user' });
      fetchSubscriptions();
    } catch (err) {
      console.error('Failed to pause subscription:', err);
    }
  }

  async function handleResume(id) {
    try {
      await post(`/subscriptions/${id}/resume`, {});
      fetchSubscriptions();
    } catch (err) {
      console.error('Failed to resume subscription:', err);
    }
  }

  async function handleCancel(id) {
    if (!window.confirm('Are you sure you want to cancel this subscription?')) return;
    try {
      await post(`/subscriptions/${id}/cancel`, { reason: 'User cancelled' });
      fetchSubscriptions();
    } catch (err) {
      console.error('Failed to cancel subscription:', err);
    }
  }

  return (
    <div className="subscriptions-page">
      <SEOMeta title="Subscriptions — SkillConnect" description="Manage your recurring household services" />

      {/* Hero Section */}
      <section className="subscriptions-hero">
        <div className="subscriptions-hero-content">
          <h1>🏠 Household Subscriptions</h1>
          <p>Set up recurring services for your home — maid, milk, laundry, cleaning & more. Never worry about scheduling again.</p>
          <div className="subscriptions-hero-badges">
            <span className="badge"><FiRepeat /> Auto-recurring</span>
            <span className="badge"><FiPause /> Pause anytime</span>
            <span className="badge"><FiCalendar /> Flexible schedules</span>
            <span className="badge"><FiStar /> Trusted providers</span>
          </div>
        </div>
      </section>

      {/* Available Subscription Categories */}
      <section className="subscriptions-categories">
        <h2>📋 Available Services</h2>
        <p className="section-subtitle">Choose from daily, weekly, or monthly recurring services</p>
        <div className="sub-categories-grid">
          {subscriptionCategories.map((cat) => (
            <div key={cat.name} className="sub-category-card" style={{ borderTopColor: cat.color }}>
              <div className="sub-cat-icon" style={{ background: `${cat.color}15`, color: cat.color }}>
                <cat.icon size={24} />
              </div>
              <h3>{cat.name}</h3>
              <span className="sub-cat-frequency">{frequencyLabels[cat.frequency]}</span>
              <span className="sub-cat-price">{cat.price}</span>
              <Link to={isAuthenticated ? '/search?engine=subscription' : '/login'} className="sub-cat-btn">
                Subscribe
              </Link>
            </div>
          ))}
        </div>
      </section>

      {/* My Subscriptions */}
      {isAuthenticated && (
        <section className="my-subscriptions">
          <div className="my-sub-header">
            <h2>📅 My Subscriptions</h2>
            <div className="sub-filters">
              {['all', 'active', 'paused', 'cancelled'].map((f) => (
                <button
                  key={f}
                  className={`sub-filter-btn ${filter === f ? 'active' : ''}`}
                  onClick={() => setFilter(f)}
                >
                  {f.charAt(0).toUpperCase() + f.slice(1)}
                </button>
              ))}
            </div>
          </div>

          {loading ? (
            <div className="sub-loading">Loading subscriptions...</div>
          ) : subscriptions.length === 0 ? (
            <div className="sub-empty">
              <FiCalendar size={48} />
              <h3>No subscriptions yet</h3>
              <p>Subscribe to recurring services for your household and never worry about scheduling again.</p>
            </div>
          ) : (
            <div className="sub-list">
              {subscriptions.map((sub) => (
                <div key={sub.id} className="sub-card">
                  <div className="sub-card-header">
                    <div className="sub-card-title">
                      <h3>{sub.title}</h3>
                      <span className="sub-status" style={{ background: `${statusColors[sub.status]}20`, color: statusColors[sub.status] }}>
                        {sub.status}
                      </span>
                    </div>
                    <span className="sub-price">₹{sub.price_per_occurrence}/{sub.frequency}</span>
                  </div>

                  <div className="sub-card-details">
                    {sub.category_name && <span><FiRepeat size={14} /> {sub.category_name}</span>}
                    {sub.professional_name && <span><FiStar size={14} /> {sub.professional_name}</span>}
                    {sub.preferred_days?.length > 0 && (
                      <span><FiCalendar size={14} /> {sub.preferred_days.join(', ')}</span>
                    )}
                    {sub.next_occurrence && (
                      <span><FiClock size={14} /> Next: {new Date(sub.next_occurrence).toLocaleDateString('en-IN')}</span>
                    )}
                    <span><FiCheck size={14} /> {sub.occurrences_completed} completed</span>
                  </div>

                  <div className="sub-card-actions">
                    {sub.status === 'active' && (
                      <button onClick={() => handlePause(sub.id)} className="sub-action-btn pause">
                        <FiPause /> Pause
                      </button>
                    )}
                    {sub.status === 'paused' && (
                      <button onClick={() => handleResume(sub.id)} className="sub-action-btn resume">
                        <FiPlay /> Resume
                      </button>
                    )}
                    {sub.status !== 'cancelled' && (
                      <button onClick={() => handleCancel(sub.id)} className="sub-action-btn cancel">
                        <FiX /> Cancel
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </section>
      )}

      {/* How Subscriptions Work */}
      <section className="sub-how-it-works">
        <h2>How Subscriptions Work</h2>
        <div className="sub-steps">
          <div className="sub-step">
            <div className="sub-step-num">1</div>
            <h3>Choose Service</h3>
            <p>Pick from daily (maid, milk), weekly (laundry, cleaning), or monthly (pest, AC) services.</p>
          </div>
          <div className="sub-step">
            <div className="sub-step-num">2</div>
            <h3>Set Schedule</h3>
            <p>Choose days, time slots, and preferred provider. We match you with trusted professionals.</p>
          </div>
          <div className="sub-step">
            <div className="sub-step-num">3</div>
            <h3>Auto-Recurring</h3>
            <p>Service happens automatically. Rate each visit. Pause or switch providers anytime.</p>
          </div>
          <div className="sub-step">
            <div className="sub-step-num">4</div>
            <h3>Family Sharing</h3>
            <p>Link subscriptions to your household. Any family member can manage or track services.</p>
          </div>
        </div>
      </section>
    </div>
  );
}

export default Subscriptions;
