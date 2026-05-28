import { useState, useEffect } from 'react';
import { useSearchParams, Link } from 'react-router-dom';
import { FiStar, FiClock, FiUsers, FiAward, FiMapPin, FiCheck, FiX, FiPlus } from 'react-icons/fi';
import { get } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './CompareProf.css';

export default function CompareProf() {
  const [searchParams] = useSearchParams();
  const [professionals, setProfessionals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const ids = searchParams.get('ids') || '';

  useEffect(() => {
    if (!ids) {
      setLoading(false);
      return;
    }
    setLoading(true);
    get(`/compare?ids=${ids}`)
      .then(res => setProfessionals(res.data || []))
      .catch(err => setError(err.message || 'Failed to load comparison'))
      .finally(() => setLoading(false));
  }, [ids]);

  if (loading) return <div className="compare-page"><LoadingSpinner /></div>;
  if (error) return <div className="compare-page"><div className="compare-error">{error}</div></div>;

  if (!professionals.length) {
    return (
      <div className="compare-page">
        <div className="compare-empty">
          <h2>Compare Professionals</h2>
          <p>Select 2-5 professionals to compare side by side</p>
          <Link to="/search" className="btn btn-primary">Browse Professionals</Link>
        </div>
      </div>
    );
  }

  const attributes = [
    { key: 'average_rating', label: 'Rating', icon: FiStar, format: v => v ? `${parseFloat(v).toFixed(1)} ⭐` : 'N/A' },
    { key: 'review_count', label: 'Reviews', icon: FiUsers, format: v => v || '0' },
    { key: 'experience_years', label: 'Experience', icon: FiAward, format: v => v ? `${v} years` : 'N/A' },
    { key: 'pricing_estimate', label: 'Pricing', icon: null, format: v => v ? `₹${v}` : 'Contact for quote' },
    { key: 'response_time_hours', label: 'Response Time', icon: FiClock, format: v => v ? `${v}h avg` : 'N/A' },
    { key: 'total_bookings', label: 'Total Jobs', icon: null, format: v => v || '0' },
    { key: 'completion_rate', label: 'Completion Rate', icon: null, format: v => v ? `${(v * 100).toFixed(0)}%` : 'N/A' },
    { key: 'repeat_client_rate', label: 'Repeat Clients', icon: null, format: v => v ? `${(v * 100).toFixed(0)}%` : 'N/A' },
    { key: 'availability_status', label: 'Available Now', icon: null, format: v => v === 'available' ? '✅ Yes' : '❌ No' },
    { key: 'city', label: 'Location', icon: FiMapPin, format: v => v || 'N/A' },
    { key: 'categories', label: 'Categories', icon: null, format: v => Array.isArray(v) ? v.filter(Boolean).join(', ') : 'N/A' },
    { key: 'services', label: 'Services', icon: null, format: v => Array.isArray(v) ? v.filter(Boolean).slice(0, 5).join(', ') : 'N/A' },
  ];

  // Find best values for highlighting
  const getBestValue = (key) => {
    const vals = professionals.map(p => parseFloat(p[key]) || 0);
    if (key === 'response_time_hours') return Math.min(...vals.filter(v => v > 0)) || 0;
    return Math.max(...vals);
  };

  return (
    <div className="compare-page">
      <div className="compare-header">
        <h1>Compare Professionals</h1>
        <p>Side-by-side comparison to help you choose</p>
      </div>

      <div className="compare-table-wrapper">
        <table className="compare-table">
          <thead>
            <tr>
              <th className="compare-attr-header">Attribute</th>
              {professionals.map(p => (
                <th key={p.id} className="compare-pro-header">
                  <div className="compare-pro-avatar">
                    {p.avatar_url ? (
                      <img src={p.avatar_url} alt={p.name} />
                    ) : (
                      <div className="compare-avatar-placeholder">{(p.name || '?')[0]}</div>
                    )}
                  </div>
                  <Link to={`/professionals/${p.id}`} className="compare-pro-name">{p.name}</Link>
                  {p.provider_type === 'organization' && <span className="compare-badge">🏢 Company</span>}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {attributes.map(attr => {
              const best = getBestValue(attr.key);
              return (
                <tr key={attr.key}>
                  <td className="compare-attr-cell">
                    {attr.icon && <attr.icon size={14} />}
                    <span>{attr.label}</span>
                  </td>
                  {professionals.map(p => {
                    const val = p[attr.key];
                    const numVal = parseFloat(val) || 0;
                    const isBest = attr.key !== 'response_time_hours'
                      ? numVal === best && numVal > 0
                      : numVal === best && numVal > 0;
                    return (
                      <td key={p.id} className={`compare-value-cell ${isBest ? 'compare-best' : ''}`}>
                        {attr.format(val)}
                        {isBest && professionals.length > 1 && <FiAward className="best-icon" size={12} />}
                      </td>
                    );
                  })}
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <div className="compare-actions">
        {professionals.map(p => (
          <div key={p.id} className="compare-action-col">
            <Link to={`/book?professional_id=${p.id}&professional_name=${encodeURIComponent(p.name)}`}
                  className="btn btn-primary btn-sm">
              Book Now
            </Link>
            <Link to={`/professionals/${p.id}`} className="btn btn-outline btn-sm">
              View Profile
            </Link>
          </div>
        ))}
      </div>
    </div>
  );
}
