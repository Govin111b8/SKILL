import { FiShield, FiClock, FiDollarSign, FiAward, FiCheckCircle, FiTrendingUp } from 'react-icons/fi';
import './TrustSection.css';

const trustBadges = [
  {
    icon: FiShield,
    title: 'Background Verified',
    desc: 'Every professional is ID-verified with government documents',
    color: '#6366f1',
  },
  {
    icon: FiDollarSign,
    title: 'Secure Payments',
    desc: 'Escrow-protected payments released only after job completion',
    color: '#10b981',
  },
  {
    icon: FiClock,
    title: 'Satisfaction Guarantee',
    desc: 'Not happy? Get a free redo or 100% refund within 48 hours',
    color: '#f97316',
  },
  {
    icon: FiAward,
    title: 'Top-Rated Pros',
    desc: 'All professionals maintain 4.5+ rating to stay on platform',
    color: '#8b5cf6',
  },
];

const liveStats = [
  { value: '2,847', label: 'Active Bookings Today', icon: FiTrendingUp },
  { value: '12 sec', label: 'Avg Response Time', icon: FiClock },
  { value: '99.2%', label: 'Satisfaction Rate', icon: FiCheckCircle },
];

const pressLogos = [
  { name: 'YourStory', url: '#' },
  { name: 'Inc42', url: '#' },
  { name: 'TechCrunch', url: '#' },
  { name: 'Economic Times', url: '#' },
  { name: 'Mint', url: '#' },
];

function TrustSection() {
  return (
    <section className="trust-section">
      <div className="container">
        {/* Trust Badges */}
        <div className="trust-header">
          <span className="section-eyebrow">Why Choose Us</span>
          <h2 className="section-title">Built for Trust & Safety</h2>
          <p className="section-subtitle">Every interaction is protected. Your safety and satisfaction are our #1 priority.</p>
        </div>

        <div className="trust-grid">
          {trustBadges.map((badge, i) => (
            <div key={i} className="trust-card" style={{ '--badge-color': badge.color }}>
              <div className="trust-card-icon"><badge.icon size={22} /></div>
              <h3>{badge.title}</h3>
              <p>{badge.desc}</p>
            </div>
          ))}
        </div>

        {/* Live Activity Ticker */}
        <div className="trust-live-bar">
          <div className="live-dot" />
          <span className="live-label">Live Platform Activity</span>
          <div className="live-stats">
            {liveStats.map((stat, i) => (
              <div key={i} className="live-stat-item">
                <stat.icon size={14} />
                <strong>{stat.value}</strong>
                <span>{stat.label}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Press / Featured In */}
        <div className="press-section">
          <p className="press-label">As Featured In</p>
          <div className="press-logos">
            {pressLogos.map((logo, i) => (
              <a key={i} href={logo.url} className="press-logo" target="_blank" rel="noopener noreferrer">
                {logo.name}
              </a>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

export default TrustSection;
