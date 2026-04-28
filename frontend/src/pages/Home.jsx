import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  FiTool, FiZap, FiDroplet, FiBook, FiScissors, FiTruck,
  FiCamera, FiHome as FiHomeIcon, FiMusic, FiHeart, FiCpu,
  FiSearch, FiShield, FiStar, FiArrowRight, FiCheck,
} from 'react-icons/fi';
import { get } from '../api/client';
import SearchBar from '../components/SearchBar';
import ProfessionalCard from '../components/ProfessionalCard';
import './Home.css';

const featuredCategories = [
  { name: 'Plumbing', icon: FiDroplet, color: '#3b82f6', bg: '#eff6ff', slug: 'plumbing' },
  { name: 'Electrical', icon: FiZap, color: '#f59e0b', bg: '#fffbeb', slug: 'electrical' },
  { name: 'Home Repair', icon: FiTool, color: '#8b5cf6', bg: '#f5f3ff', slug: 'home-repair' },
  { name: 'Cleaning', icon: FiHomeIcon, color: '#10b981', bg: '#ecfdf5', slug: 'cleaning' },
  { name: 'Tutoring', icon: FiBook, color: '#ef4444', bg: '#fef2f2', slug: 'tutoring' },
  { name: 'Beauty', icon: FiScissors, color: '#ec4899', bg: '#fdf2f8', slug: 'beauty' },
  { name: 'Photography', icon: FiCamera, color: '#f97316', bg: '#fff7ed', slug: 'photography' },
  { name: 'Fitness', icon: FiHeart, color: '#14b8a6', bg: '#f0fdfa', slug: 'fitness' },
  { name: 'Music', icon: FiMusic, color: '#6366f1', bg: '#eef2ff', slug: 'music' },
  { name: 'Moving', icon: FiTruck, color: '#64748b', bg: '#f8fafc', slug: 'moving' },
  { name: 'Technology', icon: FiCpu, color: '#0ea5e9', bg: '#f0f9ff', slug: 'technology' },
];

const trendingSearches = [
  'Plumber near me', 'House cleaning', 'Math tutor', 'Electrician',
  'Wedding photographer', 'Personal trainer', 'Web developer',
];

const stats = [
  { value: '5,000+', label: 'Verified Pros', icon: FiShield },
  { value: '50+', label: 'Categories', icon: FiTool },
  { value: '25K+', label: 'Happy Clients', icon: FiStar },
  { value: '100+', label: 'Cities', icon: FiSearch },
];

const howItWorks = [
  {
    step: '01',
    icon: FiSearch,
    title: 'Search & Filter',
    desc: 'Find professionals by skill, location, price, and rating. Hundreds of verified experts ready.',
    color: '#6366f1',
  },
  {
    step: '02',
    icon: FiStar,
    title: 'Compare & Review',
    desc: 'Browse portfolios, read verified reviews, and compare pricing to find your perfect match.',
    color: '#f97316',
  },
  {
    step: '03',
    icon: FiCheck,
    title: 'Hire & Relax',
    desc: 'Connect directly, schedule your service, and enjoy quality work with our satisfaction guarantee.',
    color: '#10b981',
  },
];

const testimonials = [
  {
    name: 'Sarah M.',
    role: 'Homeowner',
    text: 'Found an amazing plumber within minutes. Showed up on time, fixed the issue perfectly. 10/10 would use again!',
    rating: 5,
    avatar: 'SM',
  },
  {
    name: 'James T.',
    role: 'Small Business Owner',
    text: "Hired a web developer through SkillConnect. Delivered my site ahead of schedule. Incredibly easy process.",
    rating: 5,
    avatar: 'JT',
  },
  {
    name: 'Priya K.',
    role: 'Parent',
    text: 'The math tutor we found has been incredible for my daughter. Her grades improved dramatically in just a month!',
    rating: 5,
    avatar: 'PK',
  },
];

function StarRow({ count }) {
  return (
    <div style={{ display: 'flex', gap: '2px', color: '#f59e0b' }}>
      {Array.from({ length: count }).map((_, i) => <FiStar key={i} size={14} fill="#f59e0b" />)}
    </div>
  );
}

function Home() {
  const navigate = useNavigate();
  const [topPros, setTopPros] = useState([]);

  useEffect(() => {
    get('/search?limit=4&sort_by=reputation').then(res => {
      const items = Array.isArray(res.data) ? res.data : (res.data?.professionals || res.results || []);
      setTopPros(items.slice(0, 4).map(p => ({
        ...p,
        rating: p.average_rating ?? p.rating ?? 0,
        reviews_count: parseInt(p.review_count || p.reviews_count || 0),
        available: p.availability_status === 'available',
        pricing: p.pricing_estimate || p.pricing,
        verified: p.reputation_score >= 4,
        categories: p.categories?.map(c => typeof c === 'string' ? c : c.name) || [],
      })));
    }).catch(() => {});
  }, []);

  return (
    <div className="home">
      {/* ─── HERO ─── */}
      <section className="hero">
        <div className="hero-blobs">
          <div className="blob blob-1" />
          <div className="blob blob-2" />
          <div className="blob blob-3" />
        </div>
        <div className="hero-content">
          <div className="hero-badge animate-fade-up">
            <FiShield size={14} /> Trusted by 25,000+ customers
          </div>
          <h1 className="hero-title animate-fade-up" style={{ animationDelay: '0.1s' }}>
            Find the <span className="gradient-text">Perfect Professional</span><br />
            for Any Job
          </h1>
          <p className="hero-subtitle animate-fade-up" style={{ animationDelay: '0.2s' }}>
            Connect with verified, top-rated local experts — from plumbers and electricians
            to tutors and photographers. Quality work, every time.
          </p>

          <div className="hero-search-wrap animate-fade-up" style={{ animationDelay: '0.3s' }}>
            <SearchBar variant="hero" />
          </div>

          <div className="hero-trending animate-fade-up" style={{ animationDelay: '0.4s' }}>
            <span className="trending-label">Trending:</span>
            {trendingSearches.map(t => (
              <button key={t} className="trending-chip" onClick={() => navigate(`/search?q=${encodeURIComponent(t)}`)}>
                {t}
              </button>
            ))}
          </div>
        </div>

        {/* Floating cards decoration */}
        <div className="hero-float-cards">
          <div className="float-card">
            <img src="https://ui-avatars.com/api/?name=Sarah+M&background=4f46e5&color=fff&size=40" alt="" />
            <div>
              <p style={{fontWeight:700,fontSize:'0.8rem'}}>Sarah Miller</p>
              <p style={{fontSize:'0.7rem',color:'var(--gray-500)'}}>Plumbing Expert • 4.9★</p>
            </div>
          </div>
          <div className="float-card float-card-2">
            <FiCheck style={{color:'#10b981',fontSize:'1.2rem'}} />
            <div>
              <p style={{fontWeight:700,fontSize:'0.8rem'}}>Job Completed!</p>
              <p style={{fontSize:'0.7rem',color:'var(--gray-500)'}}>House cleaning • Just now</p>
            </div>
          </div>
        </div>
      </section>

      {/* ─── STATS BAR ─── */}
      <section className="stats-bar">
        <div className="container">
          <div className="stats-grid">
            {stats.map(({ value, label, icon: Icon }) => (
              <div key={label} className="stat-item">
                <div className="stat-icon"><Icon size={20} /></div>
                <div>
                  <div className="stat-value">{value}</div>
                  <div className="stat-label">{label}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ─── CATEGORIES ─── */}
      <section className="section categories-section">
        <div className="container">
          <div className="section-header">
            <div>
              <span className="section-eyebrow">Browse by Service</span>
              <h2 className="section-title">Popular Categories</h2>
            </div>
            <Link to="/categories" className="btn btn-outline btn-sm">
              All Categories <FiArrowRight size={14} />
            </Link>
          </div>
          <div className="home-categories-grid">
            {featuredCategories.map(cat => (
              <Link
                key={cat.slug}
                to={`/search?category=${cat.slug}`}
                className="home-cat-card"
                style={{ '--cat-color': cat.color, '--cat-bg': cat.bg }}
              >
                <div className="home-cat-icon">
                  <cat.icon size={24} />
                </div>
                <span className="home-cat-name">{cat.name}</span>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* ─── HOW IT WORKS ─── */}
      <section className="section how-section">
        <div className="container">
          <div className="section-header center">
            <span className="section-eyebrow">Simple Process</span>
            <h2 className="section-title">How SkillConnect Works</h2>
            <p className="section-subtitle">Get the help you need in three easy steps</p>
          </div>
          <div className="how-grid">
            {howItWorks.map((step, i) => (
              <div key={i} className="how-card" style={{ '--step-color': step.color }}>
                <div className="how-step-num">{step.step}</div>
                <div className="how-icon">
                  <step.icon size={26} />
                </div>
                <h3>{step.title}</h3>
                <p>{step.desc}</p>
                {i < howItWorks.length - 1 && <div className="how-connector" />}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ─── TOP PROFESSIONALS ─── */}
      {topPros.length > 0 && (
        <section className="section top-pros-section">
          <div className="container">
            <div className="section-header">
              <div>
                <span className="section-eyebrow">Featured Talent</span>
                <h2 className="section-title">Top-Rated Professionals</h2>
              </div>
              <Link to="/search" className="btn btn-outline btn-sm">
                View All <FiArrowRight size={14} />
              </Link>
            </div>
            <div className="top-pros-grid">
              {topPros.map(pro => (
                <ProfessionalCard key={pro.id} professional={pro} />
              ))}
            </div>
          </div>
        </section>
      )}

      {/* ─── TESTIMONIALS ─── */}
      <section className="section testimonials-section">
        <div className="container">
          <div className="section-header center">
            <span className="section-eyebrow">What Clients Say</span>
            <h2 className="section-title">Real Stories, Real Results</h2>
          </div>
          <div className="testimonials-grid">
            {testimonials.map((t, i) => (
              <div key={i} className="testimonial-card">
                <StarRow count={t.rating} />
                <p className="testimonial-text">“{t.text}”</p>
                <div className="testimonial-author">
                  <div className="testimonial-avatar">{t.avatar}</div>
                  <div>
                    <p className="testimonial-name">{t.name}</p>
                    <p className="testimonial-role">{t.role}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ─── CTA BANNER ─── */}
      <section className="cta-section">
        <div className="container">
          <div className="cta-inner">
            <div className="cta-blobs">
              <div className="cta-blob cta-blob-1" />
              <div className="cta-blob cta-blob-2" />
            </div>
            <div className="cta-content">
              <h2>Are You a Skilled Professional?</h2>
              <p>Join 5,000+ experts already growing their business on SkillConnect. Get discovered by thousands of local customers.</p>
              <div className="cta-actions">
                <Link to="/register" className="btn btn-ghost btn-lg">Join as Professional</Link>
                <Link to="/search" className="btn btn-lg" style={{background:'white',color:'var(--primary)'}}>Browse Services</Link>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}

export default Home;
