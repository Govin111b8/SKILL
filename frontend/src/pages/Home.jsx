import { Link, useNavigate } from 'react-router-dom';
import {
  FiSearch, FiShield, FiStar, FiArrowRight, FiCheck, FiTool,
} from 'react-icons/fi';
import { categoriesData } from '../data/categories';
import SearchBar from '../components/SearchBar';
import './Home.css';

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
    step: '01', icon: FiSearch,
    title: 'Search & Filter',
    desc: 'Find professionals by skill, location, price, and rating. Hundreds of verified experts ready.',
    color: '#6366f1',
  },
  {
    step: '02', icon: FiStar,
    title: 'Compare & Review',
    desc: 'Browse portfolios, read verified reviews, and compare pricing to find your perfect match.',
    color: '#f97316',
  },
  {
    step: '03', icon: FiCheck,
    title: 'Hire & Relax',
    desc: 'Connect directly, schedule your service, and enjoy quality work with our satisfaction guarantee.',
    color: '#10b981',
  },
];

const testimonials = [
  {
    name: 'Sarah M.', role: 'Homeowner', rating: 5, avatar: 'SM',
    text: 'Found an amazing plumber within minutes. Showed up on time, fixed the issue perfectly. 10/10 would use again!',
  },
  {
    name: 'James T.', role: 'Small Business Owner', rating: 5, avatar: 'JT',
    text: "Hired a web developer through SkillConnect. Delivered my site ahead of schedule. Incredibly easy process.",
  },
  {
    name: 'Priya K.', role: 'Parent', rating: 5, avatar: 'PK',
    text: 'The math tutor we found has been incredible for my daughter. Her grades improved dramatically in just a month!',
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

  return (
    <div className="home">
      {/* HERO */}
      <section className="hero">
        <div className="hero-blobs">
          <div className="blob blob-1" /><div className="blob blob-2" /><div className="blob blob-3" />
        </div>
        <div className="hero-content">
          <div className="hero-badge animate-fade-up"><FiShield size={14} /> Trusted by 25,000+ customers</div>
          <h1 className="hero-title animate-fade-up" style={{ animationDelay: '0.1s' }}>
            Find the <span className="gradient-text">Perfect Professional</span><br />for Any Job
          </h1>
          <p className="hero-subtitle animate-fade-up" style={{ animationDelay: '0.2s' }}>
            Connect with verified, top-rated local experts — from plumbers and electricians to tutors and photographers.
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

      {/* STATS */}
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

      {/* ALL SERVICES */}
      <section className="section categories-section">
        <div className="container">
          <div className="section-header">
            <div>
              <span className="section-eyebrow">Browse by Service</span>
              <h2 className="section-title">All Services</h2>
              <p className="section-subtitle" style={{ marginTop: '0.25rem' }}>
                Tap any category to explore sub-services and find the right professional
              </p>
            </div>
          </div>
          <div className="home-categories-grid">
            {categoriesData.map(cat => {
              const CatIcon = cat.icon;
              return (
                <Link
                  key={cat.slug}
                  to={`/categories/${cat.slug}`}
                  className="home-cat-card"
                  style={{ '--cat-color': cat.color, '--cat-bg': cat.bg }}
                >
                  <div className="home-cat-icon"><CatIcon size={26} /></div>
                  <span className="home-cat-name">{cat.name}</span>
                  <span className="home-cat-sub-count">{cat.subcategories.length} services</span>
                  {cat.popular && <span className="home-cat-pop-dot" />}
                </Link>
              );
            })}
          </div>
        </div>
      </section>

      {/* HOW IT WORKS */}
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
                <div className="how-icon"><step.icon size={26} /></div>
                <h3>{step.title}</h3>
                <p>{step.desc}</p>
                {i < howItWorks.length - 1 && <div className="how-connector" />}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* TESTIMONIALS */}
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
                <p className="testimonial-text">"{t.text}"</p>
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

      {/* CTA */}
      <section className="cta-section">
        <div className="container">
          <div className="cta-inner">
            <div className="cta-blobs">
              <div className="cta-blob cta-blob-1" /><div className="cta-blob cta-blob-2" />
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
