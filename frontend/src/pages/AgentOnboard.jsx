import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { FiUserPlus, FiArrowLeft } from 'react-icons/fi';
import { post } from '../api/client';
import './AgentOnboard.css';

function AgentOnboard() {
  const { type } = useParams(); // 'provider' or 'customer'
  const navigate = useNavigate();
  const [form, setForm] = useState({ name: '', email: '', password: '', phone: '', location: '' });
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const isProvider = type === 'provider';
  const title = isProvider ? 'Onboard Service Provider' : 'Onboard Customer';

  function handleChange(e) {
    setForm({ ...form, [e.target.name]: e.target.value });
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setLoading(true);
    setError('');
    setMessage('');

    try {
      const endpoint = isProvider ? '/agents/onboard/provider' : '/agents/onboard/customer';
      const res = await post(endpoint, form);
      setMessage((res.data || res).message || 'User onboarded successfully!');
      setForm({ name: '', email: '', password: '', phone: '', location: '' });
    } catch (err) {
      setError(err.data?.error || err.message || 'Failed to onboard user');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="agent-onboard">
      <button className="back-btn" onClick={() => navigate('/agent/dashboard')}>
        <FiArrowLeft /> Back to Dashboard
      </button>

      <div className="onboard-card">
        <div className="onboard-header">
          <FiUserPlus className="onboard-icon" />
          <h1>{title}</h1>
          <p className="onboard-subtitle">
            {isProvider
              ? 'Register a new service provider on the platform. They will be linked to your agent account.'
              : 'Register a new customer on the platform. You earn rewards when they make their first booking.'}
          </p>
        </div>

        {message && <div className="success-msg">{message}</div>}
        {error && <div className="error-msg">{error}</div>}

        <form onSubmit={handleSubmit} className="onboard-form">
          <div className="form-group">
            <label htmlFor="name">Full Name *</label>
            <input
              id="name" name="name" type="text" required
              value={form.name} onChange={handleChange}
              placeholder="Enter full name"
            />
          </div>

          <div className="form-group">
            <label htmlFor="email">Email *</label>
            <input
              id="email" name="email" type="email" required
              value={form.email} onChange={handleChange}
              placeholder="Enter email address"
            />
          </div>

          <div className="form-group">
            <label htmlFor="phone">Phone *</label>
            <input
              id="phone" name="phone" type="tel" required
              value={form.phone} onChange={handleChange}
              placeholder="Enter phone number"
            />
          </div>

          <div className="form-group">
            <label htmlFor="password">Temporary Password *</label>
            <input
              id="password" name="password" type="text" required minLength={8}
              value={form.password} onChange={handleChange}
              placeholder="Set a temporary password (min 8 chars)"
            />
            <small>The user should change this on first login.</small>
          </div>

          <div className="form-group">
            <label htmlFor="location">Location</label>
            <input
              id="location" name="location" type="text"
              value={form.location} onChange={handleChange}
              placeholder="City or area (optional)"
            />
          </div>

          <button type="submit" className="submit-btn" disabled={loading}>
            {loading ? 'Registering...' : `Register ${isProvider ? 'Provider' : 'Customer'}`}
          </button>
        </form>
      </div>
    </div>
  );
}

export default AgentOnboard;
