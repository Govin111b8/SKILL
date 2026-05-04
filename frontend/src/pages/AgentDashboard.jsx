import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { FiUsers, FiDollarSign, FiTrendingUp, FiAward, FiUserPlus, FiCopy, FiCheck, FiMapPin } from 'react-icons/fi';
import { get, post } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './AgentDashboard.css';

function AgentDashboard() {
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState(null);
  const [error, setError] = useState('');
  const [copied, setCopied] = useState(false);
  const [notAgent, setNotAgent] = useState(false);
  const [zones, setZones] = useState([]);
  const [registerForm, setRegisterForm] = useState({ zone: '' });
  const [registering, setRegistering] = useState(false);
  const [registerMsg, setRegisterMsg] = useState('');

  useEffect(() => {
    fetchDashboard();
  }, []);

  async function fetchDashboard() {
    try {
      const res = await get('/agents/dashboard');
      setData(res.data || res);
    } catch (err) {
      if (err.status === 404 || (err.data && err.data.error === 'Agent profile not found')) {
        setNotAgent(true);
        // Load zones for registration
        try {
          const zRes = await get('/agents/zones');
          setZones((zRes.data || zRes).zones || []);
        } catch (_) {}
      } else {
        setError(err.data?.error || err.message || 'Failed to load dashboard');
      }
    } finally {
      setLoading(false);
    }
  }

  async function handleRegister(e) {
    e.preventDefault();
    setRegistering(true);
    setRegisterMsg('');
    try {
      await post('/agents/register', registerForm);
      setNotAgent(false);
      await fetchDashboard();
    } catch (err) {
      setRegisterMsg('Error: ' + (err.data?.error || err.message));
    } finally {
      setRegistering(false);
    }
  }

  function copyCode() {
    if (data?.agent?.agent_code) {
      navigator.clipboard.writeText(data.agent.agent_code);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  }

  if (loading) return <LoadingSpinner />;

  // Show registration screen for non-agents
  if (notAgent) {
    return (
      <div className="agent-dashboard">
        <div className="agent-header">
          <h1>Become an Agent</h1>
          <p style={{ color: 'var(--gray-500)', marginTop: '0.5rem' }}>
            Join our agent network to earn rewards by onboarding service providers and customers.
          </p>
        </div>

        <div style={{ maxWidth: 480, margin: '2rem auto' }}>
          <div className="agent-stats-grid" style={{ marginBottom: '2rem' }}>
            <div className="stat-card">
              <FiDollarSign className="stat-icon" />
              <div className="stat-value">₹100</div>
              <div className="stat-label">Per Provider Onboarded</div>
            </div>
            <div className="stat-card">
              <FiUserPlus className="stat-icon" />
              <div className="stat-value">₹50</div>
              <div className="stat-label">Per Customer Onboarded</div>
            </div>
            <div className="stat-card">
              <FiTrendingUp className="stat-icon" />
              <div className="stat-value">₹200</div>
              <div className="stat-label">Provider First Job Bonus</div>
            </div>
            <div className="stat-card">
              <FiAward className="stat-icon" />
              <div className="stat-value">Unlimited</div>
              <div className="stat-label">Earning Potential</div>
            </div>
          </div>

          {registerMsg && <div className={`alert ${registerMsg.includes('Error') ? 'alert--error' : 'alert--success'}`}>{registerMsg}</div>}

          <form onSubmit={handleRegister} style={{ background: 'var(--white)', borderRadius: 12, padding: '1.5rem', boxShadow: 'var(--shadow-md)' }}>
            <h3 style={{ marginBottom: '1rem' }}>Register as Agent</h3>
            <div className="form-group">
              <label><FiMapPin size={14} /> Select Your Zone</label>
              <select
                className="form-input"
                value={registerForm.zone}
                onChange={e => setRegisterForm({ zone: e.target.value })}
              >
                <option value="">All India (no specific zone)</option>
                {zones.map(z => (
                  <option key={z.id} value={z.name}>{z.name}, {z.state}</option>
                ))}
              </select>
              <small style={{ color: 'var(--gray-500)' }}>Select the city/zone where you'll be most active.</small>
            </div>
            <button type="submit" className="btn btn-primary" style={{ width: '100%' }} disabled={registering}>
              {registering ? 'Registering...' : 'Register as Agent'}
            </button>
          </form>
        </div>
      </div>
    );
  }

  if (error) return <div className="agent-error">{error}</div>;
  if (!data) return null;

  const { agent, onboarded_users, reward_summary, reward_status, recent_transactions } = data;

  const pendingRewards = reward_status?.find(r => r.status === 'pending');
  const unlockedRewards = reward_status?.find(r => r.status === 'unlocked');

  return (
    <div className="agent-dashboard">
      <div className="agent-header">
        <h1>Agent Dashboard</h1>
        <div className="agent-code-box">
          <span className="agent-code-label">Your Agent Code:</span>
          <span className="agent-code">{agent.agent_code}</span>
          <button onClick={copyCode} className="copy-btn">
            {copied ? <FiCheck /> : <FiCopy />}
          </button>
        </div>
        <div className="agent-meta">
          <span className="agent-level">Level: <strong>{agent.level}</strong></span>
          <span className="agent-zone">Zone: <strong>{agent.zone || 'All India'}</strong></span>
          <span className={`agent-kyc ${agent.kyc_verified ? 'verified' : 'pending'}`}>
            KYC: {agent.kyc_verified ? '✓ Verified' : '⏳ Pending'}
          </span>
        </div>
      </div>

      <div className="agent-stats-grid">
        <div className="stat-card">
          <FiUsers className="stat-icon" />
          <div className="stat-value">{agent.providers_onboarded}</div>
          <div className="stat-label">Providers Onboarded</div>
        </div>
        <div className="stat-card">
          <FiUserPlus className="stat-icon" />
          <div className="stat-value">{agent.customers_onboarded}</div>
          <div className="stat-label">Customers Onboarded</div>
        </div>
        <div className="stat-card">
          <FiDollarSign className="stat-icon" />
          <div className="stat-value">₹{parseFloat(agent.wallet_balance).toFixed(0)}</div>
          <div className="stat-label">Wallet Balance</div>
        </div>
        <div className="stat-card">
          <FiTrendingUp className="stat-icon" />
          <div className="stat-value">₹{parseFloat(agent.total_earned).toFixed(0)}</div>
          <div className="stat-label">Total Earned</div>
        </div>
      </div>

      <div className="agent-actions">
        <Link to="/agent/onboard/provider" className="action-btn primary">
          <FiUserPlus /> Onboard Provider
        </Link>
        <Link to="/agent/onboard/customer" className="action-btn secondary">
          <FiUserPlus /> Onboard Customer
        </Link>
        <Link to="/agent/wallet" className="action-btn outline">
          <FiDollarSign /> View Wallet
        </Link>
        <Link to="/agent/leaderboard" className="action-btn outline">
          <FiAward /> Leaderboard
        </Link>
      </div>

      <div className="agent-sections">
        <section className="agent-section">
          <h2>Reward Summary</h2>
          <div className="reward-cards">
            {reward_summary?.map(r => (
              <div key={r.action} className="reward-card">
                <div className="reward-action">{r.action.replace(/_/g, ' ')}</div>
                <div className="reward-count">{r.count}x</div>
                <div className="reward-total">₹{parseFloat(r.total_amount || 0).toFixed(0)}</div>
              </div>
            ))}
          </div>
          <div className="reward-status-bar">
            <span>Pending: ₹{parseFloat(pendingRewards?.total || 0).toFixed(0)}</span>
            <span>Unlocked: ₹{parseFloat(unlockedRewards?.total || 0).toFixed(0)}</span>
          </div>
        </section>

        <section className="agent-section">
          <h2>Recent Onboarded Users</h2>
          {onboarded_users?.length === 0 ? (
            <p className="empty-text">No users onboarded yet. Start adding providers!</p>
          ) : (
            <div className="onboarded-list">
              {onboarded_users?.map(u => (
                <div key={u.id} className="onboarded-item">
                  <div className="onboarded-name">{u.name}</div>
                  <div className="onboarded-role">{u.user_role}</div>
                  <div className="onboarded-status">
                    {u.profile_completed && <span className="badge green">Profile ✓</span>}
                    {u.first_transaction_done && <span className="badge blue">1st Job ✓</span>}
                    {!u.profile_completed && <span className="badge gray">Profile Pending</span>}
                  </div>
                  <div className="onboarded-date">
                    {new Date(u.created_at).toLocaleDateString()}
                  </div>
                </div>
              ))}
            </div>
          )}
        </section>

        <section className="agent-section">
          <h2>Recent Transactions</h2>
          {recent_transactions?.length === 0 ? (
            <p className="empty-text">No wallet transactions yet.</p>
          ) : (
            <div className="txn-list">
              {recent_transactions?.map(t => (
                <div key={t.id} className={`txn-item ${t.type}`}>
                  <div className="txn-desc">{t.description}</div>
                  <div className="txn-amount">
                    {t.type === 'credit' ? '+' : '-'}₹{parseFloat(t.amount).toFixed(0)}
                  </div>
                  <div className="txn-date">
                    {new Date(t.created_at).toLocaleDateString()}
                  </div>
                </div>
              ))}
            </div>
          )}
        </section>
      </div>
    </div>
  );
}

export default AgentDashboard;
