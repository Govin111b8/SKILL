import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { FiUser, FiBriefcase, FiUsers, FiShield, FiStar, FiZap, FiArrowRight } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import './Login.css';
import './RoleLogin.css';

function Login() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [demoLoading, setDemoLoading] = useState('');

  async function handleDemoLogin(role) {
    const credentials = {
      customer: { email: 'customer@demo.com', redirect: '/dashboard' },
      professional: { email: 'pro1@demo.com', redirect: '/dashboard' },
      agent: { email: 'agent@demo.com', redirect: '/agent/dashboard' },
      admin: { email: 'admin@demo.com', redirect: '/admin' },
    };
    const cred = credentials[role];
    if (!cred) return;
    setDemoLoading(role);
    try {
      await login(cred.email, 'demo123');
      navigate(cred.redirect);
    } catch {
      // If demo login fails, redirect to role-specific login page
      navigate(`/login/${role}`);
    } finally {
      setDemoLoading('');
    }
  }

  return (
    <div className="role-selection-page">
      {/* Left visual panel */}
      <div className="role-selection-visual">
        <div className="role-selection-visual-blobs">
          <div className="rs-blob rs-blob-1" />
          <div className="rs-blob rs-blob-2" />
        </div>
        <div className="role-selection-visual-content">
          <span className="rs-icon">⚡</span>
          <h2>Welcome to SkillConnect</h2>
          <p>Connect with verified professionals and get quality work done with confidence.</p>
          <div className="login-visual-features">
            <div className="lv-feature">
              <div className="lv-feature-icon"><FiShield size={18} /></div>
              <span>Verified &amp; trusted professionals</span>
            </div>
            <div className="lv-feature">
              <div className="lv-feature-icon"><FiStar size={18} /></div>
              <span>Real reviews from real customers</span>
            </div>
            <div className="lv-feature">
              <div className="lv-feature-icon"><FiZap size={18} /></div>
              <span>Instant booking &amp; secure payments</span>
            </div>
          </div>
        </div>
      </div>

      {/* Right panel — role selection */}
      <div className="role-selection-form-side">
        <div className="role-selection-card">
          <div className="role-selection-card-logo">
            <span>⚡</span> Skill<em>Connect</em>
          </div>
          <h1>Sign In</h1>
          <p className="role-selection-subtitle">Choose your role to sign in</p>

          <div className="role-cards-list">
            {/* Customer */}
            <div className="role-entry customer">
              <Link to="/login/customer" className="role-entry-info">
                <div className="role-entry-icon"><FiUser size={22} /></div>
                <div className="role-entry-text">
                  <span className="role-entry-title">Customer Login</span>
                  <span className="role-entry-desc">Find &amp; hire skilled professionals</span>
                </div>
                <FiArrowRight size={16} className="role-entry-arrow" />
              </Link>
              <button
                className="demo-login-btn customer"
                onClick={() => handleDemoLogin('customer')}
                disabled={!!demoLoading}
                aria-label="Demo login as Customer"
              >
                {demoLoading === 'customer' ? '⏳' : '🚀'} Try Demo
              </button>
            </div>

            {/* Professional */}
            <div className="role-entry professional">
              <Link to="/login/professional" className="role-entry-info">
                <div className="role-entry-icon"><FiBriefcase size={22} /></div>
                <div className="role-entry-text">
                  <span className="role-entry-title">Professional Login</span>
                  <span className="role-entry-desc">Manage bookings &amp; grow your business</span>
                </div>
                <FiArrowRight size={16} className="role-entry-arrow" />
              </Link>
              <button
                className="demo-login-btn professional"
                onClick={() => handleDemoLogin('professional')}
                disabled={!!demoLoading}
                aria-label="Demo login as Professional"
              >
                {demoLoading === 'professional' ? '⏳' : '🔧'} Try Demo
              </button>
            </div>

            {/* Agent */}
            <div className="role-entry agent">
              <Link to="/login/agent" className="role-entry-info">
                <div className="role-entry-icon"><FiUsers size={22} /></div>
                <div className="role-entry-text">
                  <span className="role-entry-title">Agent Login</span>
                  <span className="role-entry-desc">Earn referral commissions</span>
                </div>
                <FiArrowRight size={16} className="role-entry-arrow" />
              </Link>
              <button
                className="demo-login-btn agent"
                onClick={() => handleDemoLogin('agent')}
                disabled={!!demoLoading}
                aria-label="Demo login as Agent"
              >
                {demoLoading === 'agent' ? '⏳' : '🤝'} Try Demo
              </button>
            </div>

            {/* Admin */}
            <div className="role-entry admin">
              <Link to="/login/admin" className="role-entry-info">
                <div className="role-entry-icon"><FiShield size={22} /></div>
                <div className="role-entry-text">
                  <span className="role-entry-title">Admin Login</span>
                  <span className="role-entry-desc">Platform management &amp; oversight</span>
                </div>
                <FiArrowRight size={16} className="role-entry-arrow" />
              </Link>
              <button
                className="demo-login-btn admin"
                onClick={() => handleDemoLogin('admin')}
                disabled={!!demoLoading}
                aria-label="Demo login as Admin"
              >
                {demoLoading === 'admin' ? '⏳' : '🛡️'} Try Demo
              </button>
            </div>
          </div>

          <p className="role-selection-footer">
            Don&apos;t have an account? <Link to="/register">Create one</Link>
          </p>
        </div>
      </div>
    </div>
  );
}

export default Login;
