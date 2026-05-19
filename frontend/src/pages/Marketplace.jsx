import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import {
  FiBriefcase, FiFileText, FiDollarSign, FiClock, FiCheckCircle,
  FiPlus, FiUser, FiMessageCircle, FiStar, FiArrowRight,
} from 'react-icons/fi';
import { get, post } from '../api/client';
import { useAuth } from '../context/AuthContext';
import SEOMeta from '../components/SEOMeta';
import './Marketplace.css';

const marketplaceCategories = [
  { name: 'Tutors & Coaching', icon: '📚', desc: 'Find expert tutors for any subject', color: '#6366f1' },
  { name: 'Web & App Development', icon: '💻', desc: 'Developers for your digital projects', color: '#3b82f6' },
  { name: 'Graphic Design', icon: '🎨', desc: 'Logos, branding, UI/UX design', color: '#ec4899' },
  { name: 'Photography', icon: '📷', desc: 'Wedding, event & commercial shoots', color: '#f97316' },
  { name: 'Videography', icon: '🎬', desc: 'Video production & editing', color: '#ef4444' },
  { name: 'Interior Design', icon: '🏠', desc: 'Transform your living spaces', color: '#10b981' },
  { name: 'Architecture', icon: '🏗️', desc: 'Building design & planning', color: '#8b5cf6' },
  { name: 'Wedding Planning', icon: '💒', desc: 'Complete event coordination', color: '#f43f5e' },
  { name: 'Accounting & Tax', icon: '📊', desc: 'Financial services & tax filing', color: '#0ea5e9' },
  { name: 'Legal Consultation', icon: '⚖️', desc: 'Lawyers & legal advisors', color: '#1f2937' },
  { name: 'Catering', icon: '🍽️', desc: 'Event catering & food services', color: '#84cc16' },
  { name: 'Construction', icon: '🔨', desc: 'Contractors & builders', color: '#d97706' },
];

function Marketplace() {
  const { isAuthenticated, user } = useAuth();
  const [proposals, setProposals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [view, setView] = useState('browse'); // browse | my-projects

  useEffect(() => {
    if (isAuthenticated) fetchProposals();
    else setLoading(false);
  }, [isAuthenticated]);

  async function fetchProposals() {
    try {
      const endpoint = user?.role === 'professional' ? '/marketplace/professional' : '/marketplace/customer';
      const res = await get(endpoint);
      setProposals(res.data || []);
    } catch (err) {
      console.error('Failed to fetch proposals:', err);
    } finally {
      setLoading(false);
    }
  }

  const statusLabels = {
    pending: { label: 'Awaiting Quote', color: '#f59e0b', icon: '⏳' },
    quoted: { label: 'Quote Received', color: '#3b82f6', icon: '💰' },
    negotiating: { label: 'Negotiating', color: '#8b5cf6', icon: '💬' },
    accepted: { label: 'Accepted', color: '#10b981', icon: '✅' },
    in_progress: { label: 'In Progress', color: '#6366f1', icon: '🔨' },
    completed: { label: 'Completed', color: '#059669', icon: '🎉' },
    cancelled: { label: 'Cancelled', color: '#ef4444', icon: '❌' },
  };

  return (
    <div className="marketplace-page">
      <SEOMeta title="Marketplace — SkillConnect" description="Find professionals for projects, get quotes, and manage milestones" />

      {/* Hero */}
      <section className="marketplace-hero">
        <h1>💼 Professional Marketplace</h1>
        <p>For complex projects that need custom quotes, negotiations, and milestone-based delivery. Find tutors, developers, designers, contractors & more.</p>
        <div className="marketplace-hero-flow">
          <span>Describe Project</span>
          <FiArrowRight />
          <span>Get Quotes</span>
          <FiArrowRight />
          <span>Choose Pro</span>
          <FiArrowRight />
          <span>Track Milestones</span>
          <FiArrowRight />
          <span>Pay on Completion</span>
        </div>
      </section>

      {/* View Toggle */}
      {isAuthenticated && (
        <div className="marketplace-view-toggle">
          <button className={view === 'browse' ? 'active' : ''} onClick={() => setView('browse')}>
            Browse Categories
          </button>
          <button className={view === 'my-projects' ? 'active' : ''} onClick={() => setView('my-projects')}>
            My Projects ({proposals.length})
          </button>
        </div>
      )}

      {/* Browse Categories */}
      {view === 'browse' && (
        <section className="marketplace-categories">
          <h2>Explore Professional Services</h2>
          <p className="section-subtitle">These services work on a quote/project basis — describe what you need, get proposals, and track delivery.</p>
          <div className="marketplace-grid">
            {marketplaceCategories.map((cat) => (
              <Link key={cat.name} to={`/search?engine=marketplace&q=${encodeURIComponent(cat.name)}`} className="marketplace-card">
                <div className="marketplace-card-icon" style={{ background: `${cat.color}15` }}>
                  <span style={{ fontSize: '1.5rem' }}>{cat.icon}</span>
                </div>
                <h3>{cat.name}</h3>
                <p>{cat.desc}</p>
                <span className="marketplace-card-action" style={{ color: cat.color }}>
                  Find Professionals <FiArrowRight />
                </span>
              </Link>
            ))}
          </div>
        </section>
      )}

      {/* My Projects */}
      {view === 'my-projects' && (
        <section className="my-projects">
          <h2>My Projects</h2>
          {loading ? (
            <div className="marketplace-loading">Loading projects...</div>
          ) : proposals.length === 0 ? (
            <div className="marketplace-empty">
              <FiBriefcase size={48} />
              <h3>No projects yet</h3>
              <p>Browse categories above and send a proposal request to a professional to get started.</p>
            </div>
          ) : (
            <div className="projects-list">
              {proposals.map((p) => {
                const statusInfo = statusLabels[p.status] || statusLabels.pending;
                return (
                  <div key={p.id} className="project-card">
                    <div className="project-card-header">
                      <h3>{p.title}</h3>
                      <span className="project-status" style={{ color: statusInfo.color, background: `${statusInfo.color}15` }}>
                        {statusInfo.icon} {statusInfo.label}
                      </span>
                    </div>
                    <p className="project-desc">{p.description?.substring(0, 120)}{p.description?.length > 120 ? '...' : ''}</p>
                    <div className="project-meta">
                      {p.professional_name && <span><FiUser size={14} /> {p.professional_name}</span>}
                      {p.category_name && <span><FiBriefcase size={14} /> {p.category_name}</span>}
                      {p.budget_max && <span><FiDollarSign size={14} /> Budget: ₹{p.budget_min?.toLocaleString('en-IN')} – ₹{p.budget_max?.toLocaleString('en-IN')}</span>}
                      {p.quoted_amount && <span><FiCheckCircle size={14} /> Quoted: ₹{p.quoted_amount?.toLocaleString('en-IN')}</span>}
                      {p.estimated_duration_days && <span><FiClock size={14} /> {p.estimated_duration_days} days</span>}
                    </div>
                    <div className="project-card-footer">
                      <span className="project-date">{new Date(p.created_at).toLocaleDateString('en-IN')}</span>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </section>
      )}

      {/* How Marketplace Works */}
      <section className="marketplace-how">
        <h2>How the Marketplace Works</h2>
        <div className="marketplace-steps">
          <div className="mkt-step">
            <div className="mkt-step-icon">📝</div>
            <h3>1. Describe Your Project</h3>
            <p>Tell us what you need — scope, timeline, budget range. The more detail, the better quotes you'll get.</p>
          </div>
          <div className="mkt-step">
            <div className="mkt-step-icon">💰</div>
            <h3>2. Receive Quotes</h3>
            <p>Professionals review your project and submit detailed quotes with milestone breakdowns.</p>
          </div>
          <div className="mkt-step">
            <div className="mkt-step-icon">🤝</div>
            <h3>3. Choose & Negotiate</h3>
            <p>Compare proposals, negotiate terms, review portfolios, and select the best professional.</p>
          </div>
          <div className="mkt-step">
            <div className="mkt-step-icon">🎯</div>
            <h3>4. Track & Pay</h3>
            <p>Track project milestones. Escrow payments release as milestones are approved. Full protection.</p>
          </div>
        </div>
      </section>
    </div>
  );
}

export default Marketplace;
