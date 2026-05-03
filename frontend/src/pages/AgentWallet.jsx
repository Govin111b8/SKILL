import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiDollarSign, FiArrowLeft, FiTrendingUp, FiArrowUpRight, FiArrowDownRight } from 'react-icons/fi';
import { get } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './AgentWallet.css';

function AgentWallet() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState(null);

  useEffect(() => {
    async function fetch() {
      try {
        const res = await get('/agents/wallet');
        setData(res.data || res);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    }
    fetch();
  }, []);

  if (loading) return <LoadingSpinner />;
  if (!data) return <p>Unable to load wallet.</p>;

  return (
    <div className="agent-wallet">
      <button className="back-btn" onClick={() => navigate('/agent/dashboard')}>
        <FiArrowLeft /> Back to Dashboard
      </button>

      <h1><FiDollarSign /> Agent Wallet</h1>

      <div className="wallet-summary">
        <div className="wallet-card balance">
          <div className="wallet-label">Current Balance</div>
          <div className="wallet-value">₹{parseFloat(data.wallet?.balance || 0).toFixed(2)}</div>
        </div>
        <div className="wallet-card earned">
          <div className="wallet-label">Total Earned</div>
          <div className="wallet-value">₹{parseFloat(data.wallet?.total_earned || 0).toFixed(2)}</div>
        </div>
      </div>

      <h2>Transaction History</h2>
      {data.transactions?.length === 0 ? (
        <p className="empty">No transactions yet. Start onboarding users to earn rewards!</p>
      ) : (
        <div className="txn-list">
          {data.transactions?.map(t => (
            <div key={t.id} className={`txn-row ${t.type}`}>
              <div className="txn-icon">
                {t.type === 'credit' ? <FiArrowDownRight /> : <FiArrowUpRight />}
              </div>
              <div className="txn-details">
                <div className="txn-desc">{t.description || t.type}</div>
                <div className="txn-date">{new Date(t.created_at).toLocaleString()}</div>
              </div>
              <div className="txn-amount">
                {t.type === 'credit' ? '+' : '-'}₹{parseFloat(t.amount).toFixed(2)}
              </div>
              <div className="txn-balance">
                Bal: ₹{parseFloat(t.balance_after).toFixed(2)}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default AgentWallet;
