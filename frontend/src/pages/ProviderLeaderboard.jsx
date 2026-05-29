import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { FiAward, FiStar, FiMapPin } from 'react-icons/fi';
import { get } from '../api/client';
import SEOMeta from '../components/SEOMeta';
import LoadingSpinner from '../components/LoadingSpinner';
import './ProviderLeaderboard.css';

const TRUST_COLORS = { platinum: '#6366f1', gold: '#f59e0b', silver: '#9ca3af', bronze: '#cd7f32' };

export default function ProviderLeaderboard() {
  const [entries, setEntries] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    get('/gamification/professional/leaderboard')
      .then(res => setEntries(res.data || []))
      .catch(() => setEntries([]))
      .finally(() => setLoading(false));
  }, []);

  const medals = ['🥇', '🥈', '🥉'];

  return (
    <div className="leaderboard-page">
      <SEOMeta title="Top Service Professionals — SkillConnect Leaderboard" description="Meet the most trusted, highest-rated service professionals in your city." />

      <div className="leaderboard-header">
        <h1><FiAward /> Top Professionals</h1>
        <p>Ranked by trust score, ratings, and completed bookings. Updated daily.</p>
      </div>

      {loading ? <LoadingSpinner /> : (
        <div className="leaderboard-list">
          {entries.map((pro, idx) => (
            <Link key={pro.professional_id || pro.id} to={`/storefront/${pro.professional_id || pro.id}`} className="leaderboard-card">
              <div className="leaderboard-rank">
                {idx < 3 ? <span className="medal">{medals[idx]}</span> : <span className="rank-num">#{idx + 1}</span>}
              </div>
              <img src={pro.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(pro.name || 'Pro')}&background=random`} alt={pro.name} className="leaderboard-avatar" />
              <div className="leaderboard-info">
                <div className="leaderboard-name">{pro.name}</div>
                <div className="leaderboard-meta">
                  {pro.trust_level && <span className="trust-badge" style={{ background: TRUST_COLORS[pro.trust_level] || '#6b7280' }}>{pro.trust_level}</span>}
                  {pro.city && <span className="leaderboard-city"><FiMapPin size={12} /> {pro.city}</span>}
                  <span className="leaderboard-rating"><FiStar size={12} color="#f59e0b" /> {parseFloat(pro.average_rating || 0).toFixed(1)}</span>
                </div>
                {pro.category_name && <div className="leaderboard-category">{pro.category_name}</div>}
              </div>
              <div className="leaderboard-points">
                <span className="points-value">{pro.lifetime_points || pro.total_points || 0}</span>
                <span className="points-label">pts</span>
              </div>
            </Link>
          ))}
          {entries.length === 0 && <div className="empty-state">No leaderboard data yet. Be the first top professional!</div>}
        </div>
      )}
    </div>
  );
}
