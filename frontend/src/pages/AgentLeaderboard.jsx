import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiAward, FiArrowLeft } from 'react-icons/fi';
import { get } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './AgentLeaderboard.css';

function AgentLeaderboard() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [leaderboard, setLeaderboard] = useState([]);
  const [zones, setZones] = useState([]);
  const [selectedZone, setSelectedZone] = useState('');

  useEffect(() => {
    fetchZones();
    fetchLeaderboard();
  }, []);

  async function fetchZones() {
    try {
      const res = await get('/agents/zones');
      setZones((res.data || res).zones || []);
    } catch (err) {
      console.error(err);
    }
  }

  async function fetchLeaderboard(zone) {
    setLoading(true);
    try {
      const url = zone ? `/agents/leaderboard?zone=${zone}` : '/agents/leaderboard';
      const res = await get(url);
      setLeaderboard((res.data || res).leaderboard || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }

  function handleZoneChange(e) {
    setSelectedZone(e.target.value);
    fetchLeaderboard(e.target.value);
  }

  return (
    <div className="agent-leaderboard">
      <button className="back-btn" onClick={() => navigate('/agent/dashboard')}>
        <FiArrowLeft /> Back to Dashboard
      </button>

      <h1><FiAward /> Agent Leaderboard</h1>

      <div className="leaderboard-filter">
        <select value={selectedZone} onChange={handleZoneChange}>
          <option value="">All Zones</option>
          {zones.map(z => (
            <option key={z.id} value={z.name}>{z.name}</option>
          ))}
        </select>
      </div>

      {loading ? <LoadingSpinner /> : (
        <div className="leaderboard-table">
          <div className="lb-header">
            <span className="lb-rank">#</span>
            <span className="lb-name">Agent</span>
            <span className="lb-zone">Zone</span>
            <span className="lb-providers">Providers</span>
            <span className="lb-customers">Customers</span>
            <span className="lb-earned">Earned</span>
          </div>
          {leaderboard.length === 0 ? (
            <p className="empty">No agents found.</p>
          ) : (
            leaderboard.map((agent, idx) => (
              <div key={agent.agent_code} className={`lb-row ${idx < 3 ? 'top-' + (idx + 1) : ''}`}>
                <span className="lb-rank">{idx + 1}</span>
                <span className="lb-name">
                  {agent.name}
                  <small className="lb-level">{agent.level}</small>
                </span>
                <span className="lb-zone">{agent.zone || '-'}</span>
                <span className="lb-providers">{agent.providers_onboarded}</span>
                <span className="lb-customers">{agent.customers_onboarded}</span>
                <span className="lb-earned">₹{parseFloat(agent.total_earned).toFixed(0)}</span>
              </div>
            ))
          )}
        </div>
      )}
    </div>
  );
}

export default AgentLeaderboard;
