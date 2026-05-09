import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  FiSearch, FiShield, FiStar, FiArrowRight, FiCheck, FiTool, FiMapPin, FiClock,
  FiTrendingUp, FiZap, FiPlay,
} from 'react-icons/fi';
import { categoriesData } from '../data/categories';
import SearchBar from '../components/SearchBar';
import TrustSection from '../components/TrustSection';
import SEOMeta from '../components/SEOMeta';
import { get } from '../api/client';
import { useAuth } from '../context/AuthContext';
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

const DEFAULT_CITIES = [
  'Bangalore', 'Hyderabad', 'Mumbai', 'Delhi', 'Chennai', 'Pune',
  'Kolkata', 'Ahmedabad', 'Jaipur', 'Lucknow',
];

function Home() {
  const navigate = useNavigate();
  const { isAuthenticated } = useAuth();
  const [recentlyViewed, setRecentlyViewed] = useState([]);
  const [selectedCity, setSelectedCity] = useState(() => localStorage.getItem('sc_city') || 'Bangalore');
  const [supportedCities, setSupportedCities] = useState(DEFAULT_CITIES);
  const [storyFeed, setStoryFeed] = useState([]);
  const [trending, setTrending] = useState([]);
  const [newPros, setNewPros] = useState([]);
  const [responsive, setResponsive] = useState([]);

  // Load recently viewed from API if logged in
  useEffect(() => {
    if (isAuthenticated) {
      get('/growth/users/recently-viewed')
        .then(res => setRecentlyViewed(res.data || []))
        .catch(() => {});
    }
  }, [isAuthenticated]);

  // Fetch supported cities (single source of truth from DB)
  useEffect(() => {
    get('/growth/supported-cities')
      .then(res => {
        const cities = (res.data || []).filter(c => c.is_active !== false).map(c => c.name);
        if (cities.length > 0) setSupportedCities(cities);
      })
      .catch(() => {}); // silently fall back to DEFAULT_CITIES
  }, []);

  // Load discovery data
  useEffect(() => {
    get('/stories/feed?limit=10').then(res => setStoryFeed(res.data || [])).catch(() => {});
    get('/discover/trending?limit=8').then(res => setTrending(res.data || [])).catch(() => {});
    get('/discover/new?limit=8').then(res => setNewPros(res.data || [])).catch(() => {});
    get('/discover/responsive?limit=8').then(res => setResponsive(res.data || [])).catch(() => {});
  }, []);

  function handleCityChange(city) {
    setSelectedCity(city);
    localStorage.setItem('sc_city', city);
  }

  const homeStructuredData = {
    '@context': 'https://schema.org',
    '@type': 'WebSite',
    name: 'SkillConnect',
    url: 'https://skillconnect.in',
    potentialAction: {
      '@type': 'SearchAction',
      target: 'https://skillconnect.in/search?q={search_term_string}',
      'query-input': 'required name=search_term_string',
    },
  };

  return (
    <div className="home">
      <SEOMeta
        title="Find Skilled Professionals Near You"
        description="SkillConnect — India's trusted hyperlocal marketplace. Book verified plumbers, electricians, tutors, photographers and 50+ more services near you."
        structuredData={homeStructuredData}
      />
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
            {/* City selector */}
            <div className="city-selector" style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '10px' }}>
              <FiMapPin size={14} style={{ color: 'var(--primary-light)' }} />
              <span style={{ fontSize: '0.8rem', color: 'var(--gray-400)' }}>Searching in</span>
              <select
                value={selectedCity}
                onChange={e => handleCityChange(e.target.value)}
                style={{
                  background: 'rgba(255,255,255,0.1)',
                  border: '1px solid rgba(255,255,255,0.2)',
                  borderRadius: '6px',
                  color: '#fff',
                  fontSize: '0.85rem',
                  padding: '3px 8px',
                  cursor: 'pointer',
                }}
              >
                {supportedCities.map(c => <option key={c} value={c} style={{ color: '#000' }}>{c}</option>)}
              </select>
            </div>
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

      {/* STORY BUBBLES */}
      {storyFeed.length > 0 && (
        <section className="section" style={{ padding: '20px 0' }}>
          <div className="container">
            <div className="story-bubbles-row">
              {storyFeed.map(group => (
                <Link
                  key={group.professional_id}
                  to={`/professionals/${group.professional_id}/storefront`}
                  className="story-bubble"
                >
                  <div className="story-avatar-ring">
                    <img
                      src={group.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(group.professional_name)}&background=6366f1&color=fff&size=56`}
                      alt={group.professional_name}
                    />
                  </div>
                  <span className="story-name">{group.professional_name?.split(' ')[0]}</span>
                </Link>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* TRENDING PROFESSIONALS */}
      {trending.length > 0 && (
        <section className="section discovery-section">
          <div className="container">
            <div className="section-header">
              <div>
                <span className="section-eyebrow"><FiTrendingUp size={14} /> Trending</span>
                <h2 className="section-title">Top Professionals This Week</h2>
              </div>
            </div>
            <div className="discovery-scroll">
              {trending.map(pro => (
                <Link key={pro.id} to={`/professionals/${pro.id}/storefront`} className="discovery-card">
                  <div className="discovery-avatar">
                    <img
                      src={pro.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(pro.name)}&background=4f46e5&color=fff&size=64`}
                      alt={pro.name}
                    />
                  </div>
                  <strong>{pro.name}</strong>
                  <span className="discovery-headline">{pro.headline || pro.location || ''}</span>
                  <div className="discovery-meta">
                    {pro.average_rating > 0 && <span><FiStar size={12} fill="#f59e0b" /> {pro.average_rating.toFixed(1)}</span>}
                    {pro.completed_jobs > 0 && <span>{pro.completed_jobs} jobs</span>}
                  </div>
                </Link>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* NEWLY VERIFIED */}
      {newPros.length > 0 && (
        <section className="section discovery-section">
          <div className="container">
            <div className="section-header">
              <div>
                <span className="section-eyebrow"><FiShield size={14} /> New on SkillConnect</span>
                <h2 className="section-title">Recently Verified Professionals</h2>
              </div>
            </div>
            <div className="discovery-scroll">
              {newPros.map(pro => (
                <Link key={pro.id} to={`/professionals/${pro.id}/storefront`} className="discovery-card">
                  <div className="discovery-avatar">
                    <img
                      src={pro.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(pro.name)}&background=10b981&color=fff&size=64`}
                      alt={pro.name}
                    />
                  </div>
                  <strong>{pro.name}</strong>
                  <span className="discovery-headline">{pro.headline || pro.location || ''}</span>
                  <div className="discovery-meta">
                    <span><FiShield size={12} /> Verified</span>
                    {pro.average_rating > 0 && <span><FiStar size={12} fill="#f59e0b" /> {pro.average_rating.toFixed(1)}</span>}
                  </div>
                </Link>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* FASTEST RESPONDERS */}
      {responsive.length > 0 && (
        <section className="section discovery-section">
          <div className="container">
            <div className="section-header">
              <div>
                <span className="section-eyebrow"><FiZap size={14} /> Lightning Fast</span>
                <h2 className="section-title">Fastest Responders</h2>
              </div>
            </div>
            <div className="discovery-scroll">
              {responsive.map(pro => (
                <Link key={pro.id} to={`/professionals/${pro.id}/storefront`} className="discovery-card">
                  <div className="discovery-avatar">
                    <img
                      src={pro.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(pro.name)}&background=f97316&color=fff&size=64`}
                      alt={pro.name}
                    />
                  </div>
                  <strong>{pro.name}</strong>
                  <span className="discovery-headline">{pro.headline || pro.location || ''}</span>
                  <div className="discovery-meta">
                    <span><FiZap size={12} /> {pro.response_time_hours < 1
                      ? `${Math.round(pro.response_time_hours * 60)}min`
                      : `${Math.round(pro.response_time_hours)}hr`
                    } response</span>
                  </div>
                </Link>
              ))}
            </div>
          </div>
        </section>
      )}

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

      {/* TRUST & SAFETY */}
      <TrustSection />

      {/* RECENTLY VIEWED (authenticated customers) */}
      {isAuthenticated && recentlyViewed.length > 0 && (
        <section className="section" style={{ padding: '40px 0 20px' }}>
          <div className="container">
            <div className="section-header">
              <h2 className="section-title"><FiClock size={18} style={{ marginRight: 6 }} />Recently Viewed</h2>
            </div>
            <div style={{ display: 'flex', gap: '16px', flexWrap: 'wrap', marginTop: '16px' }}>
              {recentlyViewed.slice(0, 5).map(pro => (
                <Link
                  key={pro.id}
                  to={`/professionals/${pro.id}`}
                  style={{
                    display: 'flex', alignItems: 'center', gap: '10px',
                    background: 'var(--gray-50)', borderRadius: '12px',
                    padding: '10px 16px', textDecoration: 'none', color: 'inherit',
                    border: '1px solid var(--gray-200)', minWidth: '200px',
                  }}
                >
                  <img
                    src={pro.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(pro.name)}&background=4f46e5&color=fff&size=36`}
                    alt={pro.name}
                    style={{ width: 36, height: 36, borderRadius: '50%', objectFit: 'cover' }}
                  />
                  <div>
                    <p style={{ fontWeight: 600, fontSize: '0.85rem', margin: 0 }}>{pro.name}</p>
                    <p style={{ fontSize: '0.75rem', color: 'var(--gray-500)', margin: 0 }}>
                      {pro.primary_category} • {pro.avg_rating ? `${pro.avg_rating}★` : 'New'}
                    </p>
                  </div>
                </Link>
              ))}
            </div>
          </div>
        </section>
      )}

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
