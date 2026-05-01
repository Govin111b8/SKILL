import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { FiGift, FiCopy, FiCheck, FiUsers, FiStar, FiAward } from 'react-icons/fi';
import { get, post } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './Referrals.css';

function Referrals() {
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState(null);
  const [copied, setCopied] = useState(false);
  const [applyCode, setApplyCode] = useState('');
  const [message, setMessage] = useState('');

  useEffect(() => {
    fetchData();
  }, []);

  async function fetchData() {
    try {
      const res = await get('/referrals/stats');
      setData(res.data || res);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }

  async function generateCode() {
    try {
      await post('/referrals/generate');
      fetchData();
    } catch (err) {
      setMessage('Error: ' + err.message);
    }
  }

  async function applyReferral(e) {
    e.preventDefault();
    if (!applyCode.trim()) return;
    try {
      const res = await post('/referrals/apply', { code: applyCode.trim() });
      setMessage((res.data || res).message || 'Referral applied!');
      setApplyCode('');
      fetchData();
    } catch (err) {
      setMessage('Error: ' + (err.data?.error || err.message));
    }
  }

  function copyCode(code) {
    navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  if (loading) return <LoadingSpinner />;

  const referralCode = data?.referral_code;
  const referrals = data?.referrals || [];
  const loyaltyBalance = data?.loyalty_balance || 0;

  return (
    <div className="referrals-page">
      <div className="container">
        <div className="page-header">
          <h1><FiGift /> Referrals & Rewards</h1>
          <p className="page-subtitle">Invite friends and earn rewards when they complete their first booking</p>
        </div>

        {message && <div className={`alert ${message.includes('Error') ? 'alert--error' : 'alert--success'}`}>{message}</div>}

        {/* Stats */}
        <div className="referral-stats">
          <div className="ref-stat">
            <FiUsers size={20} />
            <span className="ref-stat-value">{data?.total_referrals || 0}</span>
            <span className="ref-stat-label">Total Referrals</span>
          </div>
          <div className="ref-stat">
            <FiCheck size={20} />
            <span className="ref-stat-value">{data?.completed_referrals || 0}</span>
            <span className="ref-stat-label">Completed</span>
          </div>
          <div className="ref-stat">
            <FiAward size={20} />
            <span className="ref-stat-value">₹{loyaltyBalance}</span>
            <span className="ref-stat-label">Loyalty Balance</span>
          </div>
        </div>

        {/* Your Referral Code */}
        <div className="referral-code-section">
          <h2>Your Referral Code</h2>
          {referralCode ? (
            <div className="code-display">
              <span className="the-code">{referralCode.code}</span>
              <button className="btn btn-outline btn-sm" onClick={() => copyCode(referralCode.code)}>
                {copied ? <><FiCheck /> Copied!</> : <><FiCopy /> Copy</>}
              </button>
            </div>
          ) : (
            <div>
              <p className="text-muted">You don't have a referral code yet.</p>
              <button className="btn btn-primary" onClick={generateCode}>
                <FiGift /> Generate My Code
              </button>
            </div>
          )}
          {referralCode && (
            <p className="code-info">
              Share this code with friends. You earn ₹{referralCode.reward_amount} when they complete their first booking!
              {referralCode.uses_count > 0 && ` Used ${referralCode.uses_count} time(s).`}
            </p>
          )}
        </div>

        {/* Apply Code */}
        <div className="apply-code-section">
          <h2>Have a Referral Code?</h2>
          <form onSubmit={applyReferral} className="apply-form">
            <input
              type="text"
              value={applyCode}
              onChange={e => setApplyCode(e.target.value)}
              placeholder="Enter referral code"
              className="form-input"
            />
            <button type="submit" className="btn btn-primary btn-sm" disabled={!applyCode.trim()}>
              Apply
            </button>
          </form>
        </div>

        {/* Referral History */}
        {referrals.length > 0 && (
          <div className="referral-history">
            <h2><FiUsers /> Your Referrals</h2>
            <div className="referral-list">
              {referrals.map(r => (
                <div key={r.id} className="referral-item">
                  <div className="referral-item-info">
                    <strong>{r.referred_name}</strong>
                    <span className="referral-date">{new Date(r.created_at).toLocaleDateString()}</span>
                  </div>
                  <span className={`status-badge status-badge--${r.status}`}>{r.status}</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default Referrals;
