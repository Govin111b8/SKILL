import { Link } from 'react-router-dom';
import { FiUser, FiBriefcase, FiUsers, FiShield, FiStar, FiZap } from 'react-icons/fi';
import './Login.css';
import './RoleLogin.css';

function Login() {
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
          <p className="role-selection-subtitle">Choose how you want to sign in</p>

          <div className="role-cards">
            <Link to="/login/customer" className="role-card customer">
              <div className="role-card-icon"><FiUser size={24} /></div>
              <span className="role-card-title">Customer</span>
              <span className="role-card-desc">Find &amp; hire professionals</span>
            </Link>

            <Link to="/login/professional" className="role-card professional">
              <div className="role-card-icon"><FiBriefcase size={24} /></div>
              <span className="role-card-title">Professional</span>
              <span className="role-card-desc">Manage bookings &amp; grow</span>
            </Link>

            <Link to="/login/agent" className="role-card agent">
              <div className="role-card-icon"><FiUsers size={24} /></div>
              <span className="role-card-title">Agent</span>
              <span className="role-card-desc">Earn referral commissions</span>
            </Link>

            <Link to="/login/admin" className="role-card admin">
              <div className="role-card-icon"><FiShield size={24} /></div>
              <span className="role-card-title">Admin</span>
              <span className="role-card-desc">Platform management</span>
            </Link>
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
