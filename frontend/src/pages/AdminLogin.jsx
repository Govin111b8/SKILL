import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { FiEye, FiEyeOff, FiShield, FiArrowRight, FiLock, FiCheckCircle, FiZap } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import './RoleLogin.css';

function AdminLogin() {
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
      if (result && result.user && result.user.role && result.user.role !== 'admin') {
        const roleName = result.user.role.charAt(0).toUpperCase() + result.user.role.slice(1);
        setError(`This account is registered as a ${roleName}. This is not an admin account.`);
        return;
      }
      navigate('/admin');
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
      await login('admin@demo.com', 'demo123');
      navigate('/admin');
    } catch (err) {
      setError(err.message || 'Demo login failed. Please try manually.');
    } finally {
      setDemoLoading(false);
    }
  }

  return (
    <div className="role-login-page">
      <div className="role-login-visual role-admin">
        <div className="role-login-blobs">
          <div className="rl-blob rl-blob-1" />
          <div className="rl-blob rl-blob-2" />
        </div>
        <div className="role-login-visual-content">
          <span className="rl-icon"><FiShield size={48} /></span>
          <h2>Platform Administration</h2>
          <p>Manage users, monitor platform health, and ensure quality across SkillConnect.</p>
          <div className="rl-features">
            <div className="rl-feature">
              <div className="rl-feature-icon"><FiLock size={18} /></div>
              <span>Secure admin-only access</span>
            </div>
            <div className="rl-feature">
              <div className="rl-feature-icon"><FiCheckCircle size={18} /></div>
              <span>Manage users, KYC &amp; disputes</span>
            </div>
            <div className="rl-feature">
              <div className="rl-feature-icon"><FiZap size={18} /></div>
              <span>Real-time platform monitoring</span>
            </div>
          </div>
        </div>
      </div>

      <div className="role-login-form-side">
        <div className="role-login-card">
          <div className="role-login-card-logo">
            <span>⚡</span> Skill<em>Connect</em>
          </div>
          <div className="role-login-badge admin">
            <FiShield size={14} /> Admin Login
          </div>
          <h1>Admin Access</h1>
          <p className="role-login-subtitle">Secure admin access to SkillConnect platform</p>

          <div className="security-warning">
            <FiShield size={16} />
            This area is restricted to authorized administrators only. All access is logged.
          </div>

          {/* Demo Login Button */}
          <button
            className="demo-quick-btn admin"
            onClick={handleDemoLogin}
            disabled={demoLoading || loading}
            aria-label="Quick demo login as admin"
          >
            <span className="demo-quick-emoji">🛡️</span>
            <span className="demo-quick-text">
              <strong>{demoLoading ? 'Authenticating...' : 'Try Demo — Admin Panel Access'}</strong>
              <small>admin@demo.com · Demo environment only</small>
            </span>
          </button>

          <div className="login-divider">
            <span>or sign in with admin credentials</span>
          </div>

          {error && <div className="alert alert-error">{error}</div>}

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label htmlFor="email">Admin Email</label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@skillconnect.com"
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
                  placeholder="Enter admin password"
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

            <button type="submit" className="role-login-btn admin" disabled={loading || demoLoading}>
              {loading ? 'Authenticating...' : <>Secure Sign In <FiLock size={16} /></>}
            </button>
          </form>

          <p className="role-login-footer" style={{ marginTop: '2rem' }}>
            <Link to="/login">← Choose a different role</Link>
          </p>
        </div>
      </div>
    </div>
  );
}

export default AdminLogin;
