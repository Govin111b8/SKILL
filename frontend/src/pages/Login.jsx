import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { FiEye, FiEyeOff, FiShield, FiStar, FiZap, FiArrowRight } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import './Login.css';

function Login() {
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
      await login(email, password);
      navigate('/dashboard');
    } catch (err) {
      setError(err.message || 'Login failed. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="login-page">
      {/* Left visual panel */}
      <div className="login-visual">
        <div className="login-visual-blobs">
          <div className="lv-blob lv-blob-1" />
          <div className="lv-blob lv-blob-2" />
        </div>
        <div className="login-visual-content">
          <span className="lv-icon">⚡</span>
          <h2>Welcome to SkillConnect</h2>
          <p>Connect with verified professionals and get quality work done with confidence.</p>
          <div className="login-visual-features">
            <div className="lv-feature">
              <div className="lv-feature-icon"><FiShield size={18} /></div>
              <span>Verified & trusted professionals</span>
            </div>
            <div className="lv-feature">
              <div className="lv-feature-icon"><FiStar size={18} /></div>
              <span>Real reviews from real customers</span>
            </div>
            <div className="lv-feature">
              <div className="lv-feature-icon"><FiZap size={18} /></div>
              <span>Instant booking & secure payments</span>
            </div>
          </div>
        </div>
      </div>

      {/* Right form panel */}
      <div className="login-form-side">
        <div className="login-card">
          <div className="login-card-logo">
            <span>⚡</span> Skill<em>Connect</em>
          </div>
          <h1>Welcome Back</h1>
          <p className="login-subtitle">Sign in to continue to your account</p>

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

            <button type="submit" className="btn btn-primary login-btn" disabled={loading}>
              {loading ? 'Signing in...' : <>Sign In <FiArrowRight size={16} /></>}
            </button>
          </form>

          <p className="login-footer">
            Don&apos;t have an account? <Link to="/register">Create one</Link>
          </p>
        </div>
      </div>
    </div>
  );
}

export default Login;
