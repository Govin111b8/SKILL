import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  FiSearch, FiShield, FiStar, FiArrowRight, FiCheck, FiTool, FiMapPin, FiClock,
  FiTrendingUp, FiZap, FiPlay, FiMessageSquare, FiAward, FiCalendar,
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
  const [nearbyPros, setNearbyPros] = useState([]);
  const [userLocation, setUserLocation] = useState(null);
  const [locationStatus, setLocationStatus] = useState('idle'); // idle | requesting | granted | denied
  const [banners, setBanners] = useState([]);
  const [quickRebook, setQuickRebook] = useState([]);
  const [recommendations, setRecommendations] = useState([]);
  const [activeBanner, setActiveBanner] = useState(0);

  useEffect(() => {
    const stored = localStorage.getItem('sc_user_coords');
    if (stored) {
      try {
        const coords = JSON.parse(stored);
        setUserLocation(coords);
        setLocationStatus('granted');
        fetchNearby(coords.lat, coords.lng);
      } catch (err) { console.error('Failed to parse stored coords:', err.message); }
    }
  }, []);

  function requestLocation() {
    if (!navigator.geolocation) {
      setLocationStatus('denied');
      return;
    }
    setLocationStatus('requesting');
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const coords = { lat: pos.coords.latitude, lng: pos.coords.longitude };
        setUserLocation(coords);
        setLocationStatus('granted');
        localStorage.setItem('sc_user_coords', JSON.stringify(coords));
        fetchNearby(coords.lat, coords.lng);
      },
      () => setLocationStatus('denied'),
      { timeout: 10000 }
    );
  }

  async function fetchNearby(lat, lng) {
    try {
      const res = await get(`/search?latitude=${lat}&longitude=${lng}&radius_km=25&limit=8&sort_by=distance`);
      const items = res.data?.professionals || res.data || [];
      setNearbyPros(Array.isArray(items) ? items.slice(0, 8) : []);
    } catch (err) { console.error('Failed to load nearby professionals:', err.message); }
  }

  // Load recently viewed — localStorage first (instant), then API
  useEffect(() => {
    const stored = localStorage.getItem('sc_recently_viewed');
    if (stored) {
      try { setRecentlyViewed(JSON.parse(stored)); } catch (err) { console.error('Failed to parse recently viewed:', err.message); }
    }
    if (isAuthenticated) {
      get('/growth/users/recently-viewed')
        .then(res => {
          const data = res.data || [];
          setRecentlyViewed(data);
          localStorage.setItem('sc_recently_viewed', JSON.stringify(data.slice(0, 20)));
        })
        .catch((err) => { console.error('Failed to load recently viewed:', err.message); });
    }
  }, [isAuthenticated]);

  // Fetch supported cities (single source of truth from DB)
  useEffect(() => {
    get('/growth/supported-cities')
      .then(res => {
        const cities = (res.data || []).filter(c => c.is_active !== false).map(c => c.name);
        if (cities.length > 0) setSupportedCities(cities);
      })
      .catch((err) => { console.error('Failed to load cities:', err.message); }); // fall back to DEFAULT_CITIES
  }, []);

  // Load discovery data
  useEffect(() => {
    get('/stories/feed?limit=10').then(res => setStoryFeed(res.data || [])).catch((err) => console.error('Stories feed error:', err.message));
    get('/discover/trending?limit=8').then(res => setTrending(res.data || [])).catch((err) => console.error('Trending error:', err.message));
    get('/discover/new?limit=8').then(res => setNewPros(res.data || [])).catch((err) => console.error('New pros error:', err.message));
    get('/discover/responsive?limit=8').then(res => setResponsive(res.data || [])).catch((err) => console.error('Responsive error:', err.message));
    // Promotional banners
    get('/banners').then(res => setBanners(res.data || [])).catch(() => {});
    // Quick rebooking (recent completed bookings)
    if (isAuthenticated) {
      get('/bookings?status=completed&limit=5').then(res => setQuickRebook((res.data || []).slice(0, 4))).catch(() => {});
      get('/discover/trending?limit=4').then(res => setRecommendations(res.data || [])).catch(() => {});
    }
  }, [isAuthenticated]);

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

      {/* PROMOTIONAL BANNERS CAROUSEL */}
      {banners.length > 0 && (
        <section className="section" style={{ padding: '1rem 0' }}>
          <div className="container">
            <div className="promo-banner-carousel">
              {banners.map((banner, idx) => (
                <div key={banner.id} className={`promo-banner ${idx === activeBanner ? 'active' : ''}`}
                  style={{ display: idx === activeBanner ? 'flex' : 'none', background: 'linear-gradient(135deg, #6366f1, #8b5cf6)', borderRadius: '12px', padding: '1.5rem 2rem', color: '#fff', alignItems: 'center', justifyContent: 'space-between' }}>
                  <div>
                    <h3 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '0.25rem' }}>{banner.title}</h3>
                    {banner.subtitle && <p style={{ fontSize: '0.85rem', opacity: 0.9 }}>{banner.subtitle}</p>}
                  </div>
                  {banner.cta_text && banner.link_url && (
                    <Link to={banner.link_url} style={{ background: '#fff', color: '#6366f1', padding: '0.5rem 1rem', borderRadius: '8px', fontWeight: 600, fontSize: '0.85rem', textDecoration: 'none' }}>
                      {banner.cta_text}
                    </Link>
                  )}
                </div>
              ))}
              {banners.length > 1 && (
                <div style={{ display: 'flex', justifyContent: 'center', gap: '6px', marginTop: '0.75rem' }}>
                  {banners.map((_, idx) => (
                    <button key={idx} onClick={() => setActiveBanner(idx)}
                      style={{ width: '8px', height: '8px', borderRadius: '50%', border: 'none', background: idx === activeBanner ? '#6366f1' : '#d1d5db', cursor: 'pointer' }} />
                  ))}
                </div>
              )}
            </div>
          </div>
        </section>
      )}

      {/* QUICK RE-BOOKING SHORTCUTS */}
      {isAuthenticated && quickRebook.length > 0 && (
        <section className="section" style={{ padding: '1rem 0' }}>
          <div className="container">
            <div className="section-header">
              <h2><FiCalendar /> Book Again</h2>
            </div>
            <div className="horizontal-scroll" style={{ display: 'flex', gap: '0.75rem', overflowX: 'auto', paddingBottom: '0.5rem' }}>
              {quickRebook.map(booking => (
                <Link key={booking.id}
                  to={`/book?professional_id=${booking.professional_id}&professional_name=${encodeURIComponent(booking.professional_name || '')}&service=${encodeURIComponent(booking.title || '')}`}
                  style={{ minWidth: '220px', padding: '1rem', background: '#fff', borderRadius: '10px', border: '1px solid #e5e7eb', textDecoration: 'none', color: 'inherit' }}>
                  <p style={{ fontWeight: 600, fontSize: '0.85rem', marginBottom: '4px' }}>{booking.title}</p>
                  <p style={{ fontSize: '0.75rem', color: '#6b7280' }}>with {booking.professional_name}</p>
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', marginTop: '0.5rem', fontSize: '0.75rem', color: '#6366f1', fontWeight: 500 }}>
                    <FiCalendar size={12} /> Book again
                  </span>
                </Link>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* AI RECOMMENDATIONS */}
      {isAuthenticated && recommendations.length > 0 && (
        <section className="section" style={{ padding: '1rem 0' }}>
          <div className="container">
            <div className="section-header">
              <div>
                <span className="section-eyebrow"><FiAward size={14} /> Recommended for You</span>
                <h2 className="section-title">Based on Your Activity</h2>
              </div>
            </div>
            <div className="discovery-scroll">
              {recommendations.map(pro => (
                <Link key={pro.id} to={`/professionals/${pro.id}/storefront`} className="discovery-card">
                  <div className="discovery-avatar">
                    <img src={pro.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(pro.name)}&background=6366f1&color=fff&size=64`} alt={pro.name} />
                  </div>
                  <strong>{pro.name}</strong>
                  <span className="discovery-headline">{pro.headline || ''}</span>
                  <div className="discovery-meta">
                    {pro.average_rating > 0 && <span><FiStar size={12} fill="#f59e0b" /> {parseFloat(pro.average_rating).toFixed(1)}</span>}
                  </div>
                </Link>
              ))}
            </div>
          </div>
        </section>
      )}

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
                      alt={group.professional_name ? `${group.professional_name} profile` : 'User avatar'}
                    />
                  </div>
                  <span className="story-name">{group.professional_name?.split(' ')[0]}</span>
                </Link>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* Near You — Geolocation */}
      <section className="home-section">
        <div className="container">
          <div className="section-header">
            <h2><FiMapPin /> Professionals Near You</h2>
          </div>
          {locationStatus === 'idle' && (
            <div className="near-you-prompt" style={{ textAlign: 'center', padding: '2rem', background: 'var(--gray-50, #f9fafb)', borderRadius: '12px' }}>
              <FiMapPin size={32} style={{ color: 'var(--primary)', marginBottom: '0.5rem' }} />
              <p style={{ marginBottom: '1rem', color: 'var(--gray-600)' }}>Enable location to discover professionals near you</p>
              <button className="btn btn-primary btn-sm" onClick={requestLocation}>
                <FiMapPin size={14} /> Enable Location
              </button>
            </div>
          )}
          {locationStatus === 'requesting' && (
            <p style={{ textAlign: 'center', padding: '2rem', color: 'var(--gray-500)' }}>📍 Getting your location...</p>
          )}
          {locationStatus === 'denied' && (
            <p style={{ textAlign: 'center', padding: '1rem', color: 'var(--gray-500)', fontSize: '0.9rem' }}>
              Location access denied. <button className="btn-link" onClick={requestLocation} style={{ color: 'var(--primary)', cursor: 'pointer', background: 'none', border: 'none' }}>Try again</button> or browse by city above.
            </p>
          )}
          {locationStatus === 'granted' && nearbyPros.length > 0 && (
            <div className="horizontal-scroll">
              {nearbyPros.map(p => (
                <Link key={p.id} to={`/professionals/${p.id}/storefront`} className="mini-pro-card" style={{ minWidth: '200px', padding: '1rem', background: '#fff', borderRadius: '12px', border: '1px solid var(--gray-200, #e5e7eb)', textDecoration: 'none', color: 'inherit' }}>
                  <div style={{ width: '48px', height: '48px', borderRadius: '50%', background: 'var(--primary-light, #eef2ff)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700, color: 'var(--primary)', marginBottom: '0.5rem' }}>
                    {(p.name || '?')[0]}
                  </div>
                  <p style={{ fontWeight: 600, fontSize: '0.9rem', marginBottom: '2px' }}>{p.name}</p>
                  <p style={{ fontSize: '0.75rem', color: 'var(--gray-500)' }}>{p.headline || p.category || 'Professional'}</p>
                  {p.average_rating > 0 && (
                    <span style={{ fontSize: '0.75rem', color: '#f59e0b' }}>⭐ {Number(p.average_rating).toFixed(1)}</span>
                  )}
                </Link>
              ))}
            </div>
          )}
          {locationStatus === 'granted' && nearbyPros.length === 0 && (
            <p style={{ textAlign: 'center', padding: '1rem', color: 'var(--gray-500)' }}>No professionals found nearby. Try expanding your search.</p>
          )}
        </div>
      </section>

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
                      alt={pro.name ? `${pro.name} profile` : 'User avatar'}
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
                      alt={pro.name ? `${pro.name} profile` : 'User avatar'}
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
                      alt={pro.name ? `${pro.name} profile` : 'User avatar'}
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

      {/* SERVICE ENGINES — 3 ways to use SkillConnect */}
      <section className="section" style={{ padding: '2rem 0' }}>
        <div className="container">
          <div className="section-header center">
            <span className="section-eyebrow">Three Ways to Get Help</span>
            <h2 className="section-title">Choose How You Want to Use SkillConnect</h2>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1.25rem', marginTop: '1.5rem' }}>
            <Link to="/categories" style={{ textDecoration: 'none', color: 'inherit', background: '#fff', border: '2px solid #6366f1', borderRadius: '16px', padding: '1.5rem', transition: 'transform 0.2s' }}>
              <div style={{ fontSize: '1.5rem', marginBottom: '0.5rem' }}>⚡</div>
              <h3 style={{ color: '#6366f1', marginBottom: '0.3rem' }}>Book Now</h3>
              <p style={{ fontSize: '0.9rem', color: '#6b7280' }}>Instant services — plumbing, electrical, cleaning, AC repair. Book a time slot, track live, pay on completion.</p>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', marginTop: '0.75rem', fontSize: '0.85rem', color: '#6366f1', fontWeight: 500 }}>Browse Services <FiArrowRight size={14} /></span>
            </Link>
            <Link to="/subscriptions" style={{ textDecoration: 'none', color: 'inherit', background: '#fff', border: '2px solid #10b981', borderRadius: '16px', padding: '1.5rem', transition: 'transform 0.2s' }}>
              <div style={{ fontSize: '1.5rem', marginBottom: '0.5rem' }}>🔄</div>
              <h3 style={{ color: '#10b981', marginBottom: '0.3rem' }}>Subscribe</h3>
              <p style={{ fontSize: '0.9rem', color: '#6b7280' }}>Recurring household services — maid, milk, laundry, gardening. Set a schedule, pause anytime, share with family.</p>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', marginTop: '0.75rem', fontSize: '0.85rem', color: '#10b981', fontWeight: 500 }}>View Plans <FiArrowRight size={14} /></span>
            </Link>
            <Link to="/marketplace" style={{ textDecoration: 'none', color: 'inherit', background: '#fff', border: '2px solid #1f2937', borderRadius: '16px', padding: '1.5rem', transition: 'transform 0.2s' }}>
              <div style={{ fontSize: '1.5rem', marginBottom: '0.5rem' }}>💼</div>
              <h3 style={{ color: '#1f2937', marginBottom: '0.3rem' }}>Get Quotes</h3>
              <p style={{ fontSize: '0.9rem', color: '#6b7280' }}>Project-based work — tutors, designers, photographers, contractors. Describe your project, compare proposals, pay by milestone.</p>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', marginTop: '0.75rem', fontSize: '0.85rem', color: '#1f2937', fontWeight: 500 }}>Find Professionals <FiArrowRight size={14} /></span>
            </Link>
          </div>
        </div>
      </section>

      {/* HOME SERVICES SPOTLIGHT */}
      <section className="section home-services-section">
        <div className="container">
          <div className="section-header">
            <div>
              <span className="section-eyebrow">🏠 Most Popular in India</span>
              <h2 className="section-title">Home Services</h2>
              <p className="section-subtitle" style={{ marginTop: '0.25rem' }}>
                Book instantly or get custom quotes — trusted professionals for every home need
              </p>
            </div>
            <Link to="/categories/home-services" className="section-link">View All <FiArrowRight size={14} /></Link>
          </div>
          <div className="hs-mode-tabs">
            <Link to="/categories/home-services" className="hs-mode-tab hs-mode-tab--instant">
              ⚡ Instant Book <span>AC, Plumbing, Electrical, Cleaning</span>
            </Link>
            <Link to="/quotes" className="hs-mode-tab hs-mode-tab--quote">
              📋 Get Quotes <span>Painting, Renovation, Interior Design</span>
            </Link>
            <Link to="/subscriptions" className="hs-mode-tab hs-mode-tab--sub">
              🔄 Subscribe <span>Maid, Cook, Daily Help</span>
            </Link>
          </div>
          <div className="hs-services-grid">
            {[
              { icon: '❄️', name: 'AC Repair & Service', tag: 'From ₹499', path: '/search?q=AC+repair', mode: 'instant' },
              { icon: '💧', name: 'Water Purifier / RO', tag: 'From ₹299', path: '/search?q=RO+service', mode: 'instant' },
              { icon: '🪲', name: 'Pest Control', tag: 'From ₹999', path: '/search?q=pest+control', mode: 'instant' },
              { icon: '🔌', name: 'Electrician', tag: 'From ₹199', path: '/search?q=electrician', mode: 'instant' },
              { icon: '🚿', name: 'Plumber', tag: 'From ₹199', path: '/search?q=plumber', mode: 'instant' },
              { icon: '🏠', name: 'Deep Home Cleaning', tag: 'From ₹999', path: '/search?q=home+cleaning', mode: 'instant' },
              { icon: '🪑', name: 'Sofa / Carpet Cleaning', tag: 'From ₹499', path: '/search?q=sofa+cleaning', mode: 'instant' },
              { icon: '🔨', name: 'Carpenter', tag: 'From ₹299', path: '/search?q=carpenter', mode: 'instant' },
              { icon: '🎨', name: 'Home Painting', tag: 'Get Quote', path: '/quotes?category=painting', mode: 'quote' },
              { icon: '🏗️', name: 'Renovation', tag: 'Get Quote', path: '/quotes?category=renovation', mode: 'quote' },
              { icon: '🛋️', name: 'Interior Design', tag: 'Get Quote', path: '/quotes?category=interior', mode: 'quote' },
              { icon: '👩‍🍳', name: 'Maid / Cook', tag: 'Subscribe', path: '/subscriptions', mode: 'sub' },
            ].map((svc) => (
              <Link key={svc.name} to={svc.path} className={`hs-service-chip hs-service-chip--${svc.mode}`}>
                <span className="hs-chip-icon">{svc.icon}</span>
                <span className="hs-chip-name">{svc.name}</span>
                <span className="hs-chip-tag">{svc.tag}</span>
              </Link>
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

      {/* TRUST & SAFETY */}
      <TrustSection />

      {/* RECENTLY VIEWED (authenticated customers) */}
      {isAuthenticated && recentlyViewed.length > 0 && (
        <section className="section" style={{ padding: '40px 0 20px' }}>
          <div className="container">
            <div className="section-header">
              <h2 className="section-title"><FiClock size={18} style={{ marginRight: 6 }} />Recently Viewed</h2>
              <Link to="/favorites" className="section-link">My Favorites <FiArrowRight size={14} /></Link>
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
                    alt={pro.name ? `${pro.name} profile` : 'User avatar'}
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

      {/* ENGAGEMENT CTAs for authenticated users */}
      {isAuthenticated && (
        <section className="section" style={{ padding: '20px 0 40px' }}>
          <div className="container">
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '1rem' }}>
              <Link to="/bookings" style={{ textDecoration: 'none', color: 'inherit', display: 'flex', alignItems: 'center', gap: '1rem', padding: '1.25rem', background: 'linear-gradient(135deg, #ecfdf5, #d1fae5)', borderRadius: '14px', border: '1px solid #a7f3d0' }}>
                <div style={{ width: '44px', height: '44px', borderRadius: '12px', background: '#10b981', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <FiCalendar size={20} color="#fff" />
                </div>
                <div>
                  <p style={{ fontWeight: 600, fontSize: '0.95rem', margin: 0 }}>My Bookings</p>
                  <p style={{ fontSize: '0.8rem', color: '#065f46', margin: '2px 0 0' }}>Track active & past bookings</p>
                </div>
              </Link>
              <Link to="/messages" style={{ textDecoration: 'none', color: 'inherit', display: 'flex', alignItems: 'center', gap: '1rem', padding: '1.25rem', background: 'linear-gradient(135deg, #eef2ff, #e0e7ff)', borderRadius: '14px', border: '1px solid #c7d2fe' }}>
                <div style={{ width: '44px', height: '44px', borderRadius: '12px', background: '#6366f1', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <FiMessageSquare size={20} color="#fff" />
                </div>
                <div>
                  <p style={{ fontWeight: 600, fontSize: '0.95rem', margin: 0 }}>Messages</p>
                  <p style={{ fontSize: '0.8rem', color: '#3730a3', margin: '2px 0 0' }}>Chat with your professionals</p>
                </div>
              </Link>
              <Link to="/referrals" style={{ textDecoration: 'none', color: 'inherit', display: 'flex', alignItems: 'center', gap: '1rem', padding: '1.25rem', background: 'linear-gradient(135deg, #fef3c7, #fde68a)', borderRadius: '14px', border: '1px solid #fcd34d' }}>
                <div style={{ width: '44px', height: '44px', borderRadius: '12px', background: '#f59e0b', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <FiAward size={20} color="#fff" />
                </div>
                <div>
                  <p style={{ fontWeight: 600, fontSize: '0.95rem', margin: 0 }}>Refer & Earn</p>
                  <p style={{ fontSize: '0.8rem', color: '#92400e', margin: '2px 0 0' }}>Invite friends, get rewards</p>
                </div>
              </Link>
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
