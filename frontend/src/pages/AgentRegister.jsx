import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { FiUsers, FiArrowRight } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import './RoleLogin.css';

function AgentRegister() {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    confirmPassword: '',
    phone: '',
    location: '',
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { register } = useAuth();
  const navigate = useNavigate();

  function handleChange(e) {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');

    if (!formData.name || !formData.email || !formData.password) {
      setError('Please fill in all required fields');
      return;
    }
    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match');
      return;
    }
    if (formData.password.length < 6) {
      setError('Password must be at least 6 characters');
      return;
    }

    setLoading(true);
    try {
      await register({
        name: formData.name,
        email: formData.email,
        password: formData.password,
        phone: formData.phone,
        location: formData.location,
        role: 'agent',
      });
      navigate('/agent/dashboard');
    } catch (err) {
      setError(err.message || 'Registration failed. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="role-register-page">
      <div className="role-register-visual role-agent">
        <div className="role-register-blobs">
          <div className="rr-blob rr-blob-1" />
          <div className="rr-blob rr-blob-2" />
        </div>
        <div className="role-register-visual-content">
          <span className="rr-icon"><FiUsers size={48} /></span>
          <h2>Become a SkillConnect Agent</h2>
          <p>Earn commissions by referring professionals and customers to the platform.</p>
          <div className="rr-stats">
            <div className="rr-stat">
              <span className="rr-stat-value">15%</span>
              <span className="rr-stat-label">Commission</span>
            </div>
            <div className="rr-stat">
              <span className="rr-stat-value">Weekly</span>
              <span className="rr-stat-label">Payouts</span>
            </div>
            <div className="rr-stat">
              <span className="rr-stat-value">Free</span>
              <span className="rr-stat-label">To Join</span>
            </div>
          </div>
        </div>
      </div>

      <div className="role-register-form-side">
        <div className="role-register-card">
          <div className="role-login-badge agent">
            <FiUsers size={14} /> Agent Registration
          </div>
          <h1>Join as an Agent</h1>
          <p className="role-register-subtitle">Start earning commissions by growing the network</p>

          {error && <div className="alert alert-error">{error}</div>}

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label htmlFor="name">Full Name *</label>
              <input id="name" name="name" type="text" value={formData.name} onChange={handleChange} placeholder="John Doe" />
            </div>

            <div className="form-group">
              <label htmlFor="email">Email *</label>
              <input id="email" name="email" type="email" value={formData.email} onChange={handleChange} placeholder="you@example.com" />
            </div>

            <div className="role-form-row">
              <div className="form-group">
                <label htmlFor="password">Password *</label>
                <input id="password" name="password" type="password" value={formData.password} onChange={handleChange} placeholder="Min 6 characters" />
              </div>
              <div className="form-group">
                <label htmlFor="confirmPassword">Confirm Password *</label>
                <input id="confirmPassword" name="confirmPassword" type="password" value={formData.confirmPassword} onChange={handleChange} placeholder="Confirm password" />
              </div>
            </div>

            <div className="role-form-row">
              <div className="form-group">
                <label htmlFor="phone">Phone</label>
                <input id="phone" name="phone" type="tel" value={formData.phone} onChange={handleChange} placeholder="+91 98765 43210" />
              </div>
              <div className="form-group">
                <label htmlFor="location">Location</label>
                <input id="location" name="location" type="text" value={formData.location} onChange={handleChange} placeholder="City, State" />
              </div>
            </div>

            <button type="submit" className="role-register-btn agent" disabled={loading}>
              {loading ? 'Creating Account...' : <>Become an Agent <FiArrowRight size={16} /></>}
            </button>
          </form>

          <p className="role-register-footer">
            Already have an account? <Link to="/login/agent">Sign in</Link>
          </p>
          <p className="role-register-footer" style={{ marginTop: '0.5rem' }}>
            <Link to="/login">← Back to role selection</Link>
          </p>
        </div>
      </div>
    </div>
  );
}

export default AgentRegister;
