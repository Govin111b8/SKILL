import { useState, useEffect } from 'react';
import { FiAward, FiClock, FiUsers, FiStar, FiShield, FiTrendingUp } from 'react-icons/fi';
import { get } from '../api/client';
import './TrustTimeline.css';

const MILESTONE_ICONS = {
  joined: FiClock,
  verified: FiShield,
  first_job: FiAward,
  jobs_10: FiAward,
  jobs_50: FiAward,
  jobs_100: FiAward,
  first_review: FiStar,
  reviews_10: FiStar,
  reviews_50: FiStar,
  repeat_customer: FiUsers,
  rating_above_4_5: FiTrendingUp,
  badge_earned: FiAward,
};

export default function TrustTimeline({ professionalId }) {
  const [timeline, setTimeline] = useState([]);
  const [loading, setLoading] = useState(true);
  const [expanded, setExpanded] = useState(false);

  useEffect(() => {
    if (!professionalId) return;
    get(`/trust/${professionalId}/timeline`)
      .then(res => setTimeline(res.data || []))
      .catch(() => setTimeline([]))
      .finally(() => setLoading(false));
  }, [professionalId]);

  if (loading || timeline.length === 0) return null;

  const displayed = expanded ? timeline : timeline.slice(0, 5);

  function formatDate(d) {
    return new Date(d).toLocaleDateString('en-US', { month: 'short', year: 'numeric' });
  }

  return (
    <div className="trust-timeline">
      <h3 className="timeline-title">📈 Professional Journey</h3>
      <div className="timeline-track">
        {displayed.map((item, i) => {
          const Icon = MILESTONE_ICONS[item.type] || FiAward;
          return (
            <div key={i} className="timeline-item">
              <div className="timeline-dot">
                <Icon size={14} />
              </div>
              {i < displayed.length - 1 && <div className="timeline-connector" />}
              <div className="timeline-content">
                <span className="timeline-label">{item.label}</span>
                {item.date && <span className="timeline-date">{formatDate(item.date)}</span>}
              </div>
            </div>
          );
        })}
      </div>
      {timeline.length > 5 && (
        <button className="timeline-toggle" onClick={() => setExpanded(!expanded)}>
          {expanded ? 'Show less' : `Show all ${timeline.length} milestones`}
        </button>
      )}
    </div>
  );
}
