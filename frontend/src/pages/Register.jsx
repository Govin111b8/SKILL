import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { FiUser, FiBriefcase, FiUsers, FiArrowRight } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import './Register.css';

const CATEGORIES = [
  'Plumbing', 'Electrical', 'Cleaning', 'Tutoring', 'Beauty',
  'Home Repair', 'Moving', 'Photography', 'Cooking', 'Fitness',
];

function Register() {
  const [role, setRole] = useState('customer');
  const [providerType, setProviderType] = useState('individual');
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    confirmPassword: '',
    phone: '',
    location: '',
    headline: '',
    bio: '',
    years_of_experience: '',
    category: '',
    company_name: '',
    team_size: '',
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

    const payload = {
      name: formData.name,
      email: formData.email,
      password: formData.password,
      phone: formData.phone,
      location: formData.location,
      role,
    };

    if (role === 'professional') {
      payload.headline = formData.headline;
      payload.bio = formData.bio;
      payload.years_of_experience = Number(formData.years_of_experience) || 0;
      payload.category = formData.category;
      payload.provider_type = providerType;
      if (providerType === 'organization') {
        payload.company_name = formData.company_name;
        payload.team_size = Number(formData.team_size) || undefined;
      }
    }

    setLoading(true);
    try {
      await register(payload);
      navigate('/dashboard');
    } catch (err) {
      setError(err.message || 'Registration failed. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="register-page">
      {/* Left visual panel */}
      <div className="register-visual">
        <div className="register-visual-blobs">
          <div className="rv-blob rv-blob-1" />
          <div className="rv-blob rv-blob-2" />
        </div>
        <div className="register-visual-content">
          <span className="rv-icon">🚀</span>
          <h2>Start Your Journey</h2>
          <p>Join thousands of professionals and customers on India&apos;s fastest-growing service marketplace.</p>
          <div className="register-visual-stats">
            <div className="rv-stat">
              <span className="rv-stat-value">5K+</span>
              <span className="rv-stat-label">Professionals</span>
            </div>
            <div className="rv-stat">
              <span className="rv-stat-value">25K+</span>
              <span className="rv-stat-label">Happy Clients</span>
            </div>
            <div className="rv-stat">
              <span className="rv-stat-value">100+</span>
              <span className="rv-stat-label">Cities</span>
            </div>
            <div className="rv-stat">
              <span className="rv-stat-value">4.8★</span>
              <span className="rv-stat-label">Avg Rating</span>
            </div>
          </div>
        </div>
      </div>

      {/* Right form panel */}
      <div className="register-form-side">
        <div className="register-card">
          <h1>Create Account</h1>
          <p className="register-subtitle">Join SkillConnect today</p>

          <div className="role-toggle">
            <button
              type="button"
              className={`role-btn ${role === 'customer' ? 'active' : ''}`}
              onClick={() => setRole('customer')}
            >
              <FiUser size={15} /> Customer
            </button>
            <button
              type="button"
              className={`role-btn ${role === 'professional' ? 'active' : ''}`}
              onClick={() => setRole('professional')}
            >
              <FiBriefcase size={15} /> Professional
            </button>
            <button
              type="button"
              className={`role-btn ${role === 'agent' ? 'active' : ''}`}
              onClick={() => setRole('agent')}
            >
              <FiUsers size={15} /> Agent
            </button>
          </div>

        {error && <div className="alert alert-error">{error}</div>}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="name">Full Name *</label>
            <input
              id="name"
              name="name"
              type="text"
              value={formData.name}
              onChange={handleChange}
              placeholder="John Doe"
            />
          </div>

          <div className="form-group">
            <label htmlFor="email">Email *</label>
            <input
              id="email"
              name="email"
              type="email"
              value={formData.email}
              onChange={handleChange}
              placeholder="you@example.com"
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label htmlFor="password">Password *</label>
              <input
                id="password"
                name="password"
                type="password"
                value={formData.password}
                onChange={handleChange}
                placeholder="Min 6 characters"
              />
            </div>
            <div className="form-group">
              <label htmlFor="confirmPassword">Confirm Password *</label>
              <input
                id="confirmPassword"
                name="confirmPassword"
                type="password"
                value={formData.confirmPassword}
                onChange={handleChange}
                placeholder="Confirm password"
              />
            </div>
          </div>

          <div className="form-row">
            <div className="form-group">
              <label htmlFor="phone">Phone</label>
              <input
                id="phone"
                name="phone"
                type="tel"
                value={formData.phone}
                onChange={handleChange}
                placeholder="+1 (555) 000-0000"
              />
            </div>
            <div className="form-group">
              <label htmlFor="location">Location</label>
              <input
                id="location"
                name="location"
                type="text"
                value={formData.location}
                onChange={handleChange}
                placeholder="City, State"
              />
            </div>
          </div>

          {role === 'professional' && (
            <>
              <div className="provider-type-toggle">
                <label className="provider-type-label">Provider Type</label>
                <div className="provider-type-options">
                  <button
                    type="button"
                    className={`provider-type-btn ${providerType === 'individual' ? 'active' : ''}`}
                    onClick={() => setProviderType('individual')}
                  >
                    Individual / Freelancer
                  </button>
                  <button
                    type="button"
                    className={`provider-type-btn ${providerType === 'organization' ? 'active' : ''}`}
                    onClick={() => setProviderType('organization')}
                  >
                    Company / Consultancy
                  </button>
                </div>
              </div>

              {providerType === 'organization' && (
                <div className="form-row">
                  <div className="form-group">
                    <label htmlFor="company_name">Company Name *</label>
                    <input
                      id="company_name"
                      name="company_name"
                      type="text"
                      value={formData.company_name}
                      onChange={handleChange}
                      placeholder="e.g., ABC Electrical Services Pvt Ltd"
                    />
                  </div>
                  <div className="form-group">
                    <label htmlFor="team_size">Team Size</label>
                    <input
                      id="team_size"
                      name="team_size"
                      type="number"
                      min="1"
                      value={formData.team_size}
                      onChange={handleChange}
                      placeholder="e.g., 10"
                    />
                  </div>
                </div>
              )}

              <div className="form-group">
                <label htmlFor="headline">Professional Headline</label>
                <input
                  id="headline"
                  name="headline"
                  type="text"
                  value={formData.headline}
                  onChange={handleChange}
                  placeholder="e.g., Licensed Plumber with 10+ years experience"
                />
              </div>

              <div className="form-group">
                <label htmlFor="bio">Bio</label>
                <textarea
                  id="bio"
                  name="bio"
                  value={formData.bio}
                  onChange={handleChange}
                  placeholder="Tell customers about yourself and your services..."
                  rows={4}
                />
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label htmlFor="years_of_experience">Years of Experience</label>
                  <input
                    id="years_of_experience"
                    name="years_of_experience"
                    type="number"
                    min="0"
                    value={formData.years_of_experience}
                    onChange={handleChange}
                    placeholder="5"
                  />
                </div>
                <div className="form-group">
                  <label htmlFor="category">Category</label>
                  <select
                    id="category"
                    name="category"
                    value={formData.category}
                    onChange={handleChange}
                  >
                    <option value="">Select a category</option>
                    {CATEGORIES.map((cat) => (
                      <option key={cat} value={cat.toLowerCase()}>{cat}</option>
                    ))}
                  </select>
                </div>
              </div>
            </>
          )}

          <button type="submit" className="btn btn-primary register-btn" disabled={loading}>
            {loading ? 'Creating Account...' : <>Create Account <FiArrowRight size={16} /></>}
          </button>
        </form>

        <p className="register-footer">
          Already have an account? <Link to="/login">Sign in</Link>
        </p>
        </div>
      </div>
    </div>
  );
}

export default Register;
