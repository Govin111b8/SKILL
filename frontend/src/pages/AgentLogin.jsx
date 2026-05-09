import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { FiEye, FiEyeOff, FiUsers, FiArrowRight, FiDollarSign, FiAward, FiTrendingUp } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import './RoleLogin.css';

function AgentLogin() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
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
      if (result && result.user && result.user.role && result.user.role !== 'agent') {
        const roleName = result.user.role.charAt(0).toUpperCase() + result.user.role.slice(1);
        setError(`This account is registered as a ${roleName}. Please use the ${roleName} login.`);
        return;
      }
      navigate('/agent/dashboard');
    } catch (err) {
      setError(err.message || 'Login failed. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="role-login-page">
      <div className="role-login-visual role-agent">
        <div className="role-login-blobs">
          <div className="rl-blob rl-blob-1" />
          <div className="rl-blob rl-blob-2" />
        </div>
        <div className="role-login-visual-content">
          <span className="rl-icon"><FiUsers size={48} /></span>
          <h2>Earn Commissions &amp; Grow Your Network</h2>
          <p>Manage your referrals, track commissions, and climb the leaderboard as a SkillConnect agent.</p>
          <div className="rl-features">
            <div className="rl-feature">
              <div className="rl-feature-icon"><FiDollarSign size={18} /></div>
              <span>Earn commissions on every referral</span>
            </div>
            <div className="rl-feature">
              <div className="rl-feature-icon"><FiAward size={18} /></div>
              <span>Compete on the agent leaderboard</span>
            </div>
            <div className="rl-feature">
              <div className="rl-feature-icon"><FiTrendingUp size={18} /></div>
              <span>Track your wallet &amp; earnings</span>
            </div>
          </div>
        </div>
      </div>

      <div className="role-login-form-side">
        <div className="role-login-card">
          <div className="role-login-card-logo">
            <span>⚡</span> Skill<em>Connect</em>
          </div>
          <div className="role-login-badge agent">
            <FiUsers size={14} /> Agent Login
          </div>
          <h1>Welcome Back</h1>
          <p className="role-login-subtitle">Sign in to manage referrals &amp; earn commissions</p>

          <div className="demo-credentials">
            <strong>Demo Credentials</strong>
            <code>agent@demo.com</code> / <code>demo123</code>
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

            <button type="submit" className="role-login-btn agent" disabled={loading}>
              {loading ? 'Signing in...' : <>Sign In <FiArrowRight size={16} /></>}
            </button>
          </form>

          <p className="role-login-footer">
            Don&apos;t have an account? <Link to="/register/agent">Register as Agent</Link>
          </p>
          <p className="role-login-footer" style={{ marginTop: '0.5rem' }}>
            <Link to="/login">← Back to role selection</Link>
          </p>
        </div>
      </div>
    </div>
  );
}

export default AgentLogin;
