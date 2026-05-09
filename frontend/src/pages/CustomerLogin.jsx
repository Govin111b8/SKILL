import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { FiEye, FiEyeOff, FiUser, FiArrowRight, FiHome, FiStar, FiCheckCircle } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import './RoleLogin.css';

function CustomerLogin() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [demoLoading, setDemoLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');

    if (!email || !password) {
      setError('Please fill in all fields');
      return;
    }

    setLoading(true);
    try {
      const result = await login(email, password);
      if (result && result.user && result.user.role && result.user.role !== 'customer') {
        const roleName = result.user.role.charAt(0).toUpperCase() + result.user.role.slice(1);
        setError(`This account is registered as a ${roleName}. Please use the ${roleName} login.`);
        return;
      }
      navigate('/dashboard');
    } catch (err) {
      setError(err.message || 'Login failed. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  async function handleDemoLogin() {
    setError('');
    setDemoLoading(true);
    try {
      await login('customer@demo.com', 'demo123');
      navigate('/dashboard');
    } catch (err) {
      setError(err.message || 'Demo login failed. Please try manually.');
    } finally {
      setDemoLoading(false);
    }
  }

  return (
    <div className="role-login-page">
      <div className="role-login-visual role-customer">
        <div className="role-login-blobs">
          <div className="rl-blob rl-blob-1" />
          <div className="rl-blob rl-blob-2" />
        </div>
        <div className="role-login-visual-content">
          <span className="rl-icon"><FiUser size={48} /></span>
          <h2>Find &amp; Hire Skilled Professionals</h2>
          <p>Access verified professionals for any service you need, with secure booking and guaranteed quality.</p>
          <div className="rl-features">
            <div className="rl-feature">
              <div className="rl-feature-icon"><FiCheckCircle size={18} /></div>
              <span>Browse verified &amp; trusted professionals</span>
            </div>
            <div className="rl-feature">
              <div className="rl-feature-icon"><FiStar size={18} /></div>
              <span>Read real reviews from real customers</span>
            </div>
            <div className="rl-feature">
              <div className="rl-feature-icon"><FiHome size={18} /></div>
              <span>Book services at your doorstep</span>
            </div>
          </div>
        </div>
      </div>

      <div className="role-login-form-side">
        <div className="role-login-card">
          <div className="role-login-card-logo">
            <span>⚡</span> Skill<em>Connect</em>
          </div>
          <div className="role-login-badge customer">
            <FiUser size={14} /> Customer Login
          </div>
          <h1>Welcome Back, Customer!</h1>
          <p className="role-login-subtitle">Sign in to find &amp; hire skilled professionals</p>

          {/* Prominent Demo Login Button */}
          <button
            className="demo-quick-btn customer"
            onClick={handleDemoLogin}
            disabled={demoLoading || loading}
            aria-label="Quick demo login as customer"
          >
            <span className="demo-quick-emoji">🚀</span>
            <span className="demo-quick-text">
              <strong>{demoLoading ? 'Logging in...' : 'Try Demo — Instant Customer Login'}</strong>
              <small>customer@demo.com · No signup needed</small>
            </span>
          </button>

          <div className="login-divider">
            <span>or sign in with your account</span>
          </div>

          {error && <div className="alert alert-error">{error}</div>}

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label htmlFor="email">Email Address</label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@example.com"
                autoComplete="email"
              />
            </div>

            <div className="form-group">
              <label htmlFor="password">Password</label>
              <div className="password-input-group">
                <input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Enter your password"
                  autoComplete="current-password"
                />
                <button
                  type="button"
                  className="password-toggle"
                  onClick={() => setShowPassword(!showPassword)}
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                >
                  {showPassword ? <FiEyeOff size={18} /> : <FiEye size={18} />}
                </button>
              </div>
            </div>

            <button type="submit" className="role-login-btn customer" disabled={loading || demoLoading}>
              {loading ? 'Signing in...' : <>Sign In as Customer <FiArrowRight size={16} /></>}
            </button>
          </form>

          <p className="role-login-footer">
            Don&apos;t have an account? <Link to="/register/customer">Create Customer Account</Link>
          </p>
          <p className="role-login-footer" style={{ marginTop: '0.5rem' }}>
            <Link to="/login">← Choose a different role</Link>
          </p>
        </div>
      </div>
    </div>
  );
}

export default CustomerLogin;
