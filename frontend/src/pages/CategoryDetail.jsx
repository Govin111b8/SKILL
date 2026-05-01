import { useState, useEffect, useCallback, useMemo } from 'react';
import { useParams, useNavigate, Link, useSearchParams } from 'react-router-dom';
import {
  FiArrowLeft, FiSearch, FiArrowRight, FiChevronRight,
  FiSliders, FiCalendar,
} from 'react-icons/fi';
import { get } from '../api/client';
import { categoriesData } from '../data/categories';
import { useWebSocket } from '../context/WebSocketContext';
import ProfessionalCard from '../components/ProfessionalCard';
import LoadingSpinner from '../components/LoadingSpinner';
import './CategoryDetail.css';

function mapPro(p) {
  return {
    ...p,
    rating: p.average_rating ?? p.rating ?? 0,
    reviews_count: parseInt(p.review_count || p.reviews_count || 0),
    available: p.availability_status === 'available',
    pricing: p.pricing_estimate || p.pricing,
    categories: p.categories?.map(c => (typeof c === 'string' ? c : c.name)) || [],
    completedJobs: p.completed_jobs ?? p.completedJobs ?? 0,
    responseTime: p.response_time ?? p.responseTime ?? null,
  };
}

const SORT_OPTIONS = [
  { value: 'rating', label: 'Top Rated' },
  { value: 'price-low', label: 'Price: Low → High' },
  { value: 'price-high', label: 'Price: High → Low' },
  { value: 'jobs', label: 'Most Jobs' },
  { value: 'response', label: 'Fastest Response' },
];

function sortProfessionals(pros, sortBy) {
  const sorted = [...pros];
  switch (sortBy) {
    case 'rating':
      return sorted.sort((a, b) => (b.rating || 0) - (a.rating || 0));
    case 'price-low':
      return sorted.sort((a, b) => parsePriceNum(a.pricing) - parsePriceNum(b.pricing));
    case 'price-high':
      return sorted.sort((a, b) => parsePriceNum(b.pricing) - parsePriceNum(a.pricing));
    case 'jobs':
      return sorted.sort((a, b) => (b.completedJobs || 0) - (a.completedJobs || 0));
    case 'response':
      return sorted.sort((a, b) => (a.responseTime || 9999) - (b.responseTime || 9999));
    default:
      return sorted;
  }
}

function parsePriceNum(pricing) {
  if (!pricing) return 9999;
  const match = String(pricing).match(/[\d,.]+/);
  return match ? parseFloat(match[0].replace(',', '')) : 9999;
}

function CategoryDetail() {
  const { slug } = useParams();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  const category = categoriesData.find(c => c.slug === slug);
  const [selectedSub, setSelectedSub] = useState(null);
  const [professionals, setProfessionals] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);
  const [sortBy, setSortBy] = useState('rating');

  // WebSocket presence data
  let onlineUsers = {};
  try {
    const ws = useWebSocket();
    onlineUsers = ws?.onlineUsers || {};
  } catch {
    // WebSocket context may not be available
  }

  const fetchPros = useCallback(
    async (subName) => {
      if (!category) return;
      setLoading(true);
      setSearched(true);
      try {
        const q = subName || category.name;
        const res = await get(`/search?q=${encodeURIComponent(q)}&limit=20`);
        const data = res.data || res;
        const items = Array.isArray(data)
          ? data
          : data.professionals || data.results || [];
        setProfessionals(items.map(mapPro));
      } catch {
        setProfessionals([]);
      } finally {
        setLoading(false);
      }
    },
    [category]
  );

  // Init from URL query param ?sub=...
  useEffect(() => {
    const subParam = searchParams.get('sub');
    if (subParam && category) {
      const match = category.subcategories.find(
        s => s.name.toLowerCase() === subParam.toLowerCase()
      );
      if (match) {
        setSelectedSub(match);
        fetchPros(match.name);
        return;
      }
    }
    setSelectedSub(null);
    fetchPros(null);
  }, [slug, searchParams, category, fetchPros]);

  function handleSubClick(sub) {
    const isSame = selectedSub?.name === sub.name;
    const next = isSame ? null : sub;
    setSelectedSub(next);
    fetchPros(next ? next.name : null);
  }

  // Merge online status into professionals
  const prosWithPresence = useMemo(() => {
    return professionals.map(p => {
      const presence = onlineUsers[p.id] || onlineUsers[String(p.id)];
      if (presence) {
        return { ...p, isOnline: presence.status === 'online', lastSeen: presence.lastSeen };
      }
      return p;
    });
  }, [professionals, onlineUsers]);

  const sortedPros = useMemo(
    () => sortProfessionals(prosWithPresence, sortBy),
    [prosWithPresence, sortBy]
  );

  if (!category) {
    return (
      <div className="cd-not-found">
        <FiSearch size={48} />
        <h2>Category not found</h2>
        <Link to="/categories" className="btn btn-primary">← Back to Categories</Link>
      </div>
    );
  }

  const CatIcon = category.icon;

  return (
    <div className="cd-page">
      {/* ── Breadcrumb ── */}
      <div className="cd-breadcrumb">
        <div className="container">
          <nav className="breadcrumb-nav">
            <Link to="/">Home</Link>
            <span className="breadcrumb-sep">/</span>
            <Link to="/categories">Services</Link>
            <span className="breadcrumb-sep">/</span>
            <span className="breadcrumb-current">{category.name}</span>
            {selectedSub && (
              <>
                <span className="breadcrumb-sep">/</span>
                <span className="breadcrumb-current">{selectedSub.name}</span>
              </>
            )}
          </nav>
        </div>
      </div>

      {/* ── Banner ── */}
      <div className="cd-banner" style={{ '--cd-color': category.color, '--cd-bg': category.bg }}>
        <div className="container">
          <button className="cd-back" onClick={() => navigate(-1)}>
            <FiArrowLeft size={16} /> Back
          </button>
          <div className="cd-banner-body">
            <div className="cd-banner-icon">
              <CatIcon size={44} />
            </div>
            <div className="cd-banner-text">
              <div className="cd-banner-eyebrow">Service Category</div>
              <h1 className="cd-banner-title">{category.name}</h1>
              <p className="cd-banner-desc">{category.desc}</p>
              <div className="cd-banner-meta">
                <span className="cd-pill">{category.subcategories.length} Sub-services</span>
                {category.popular && <span className="cd-pill cd-pill--pop">⭐ Popular</span>}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* ── Sub-services chips ── */}
      <div className="cd-subs-wrap">
        <div className="container">
          <div className="cd-subs-header">
            <h2 className="cd-section-title">Choose a Sub-Service</h2>
            <p className="cd-section-sub">
              {selectedSub
                ? `Showing professionals for "${selectedSub.name}" — click again to reset`
                : 'Tap a service below to see matching professionals'}
            </p>
          </div>
          <div className="cd-subs-grid">
            {category.subcategories.map((sub) => {
              const isActive = selectedSub?.name === sub.name;
              const SubIcon = sub.icon;
              return (
                <button
                  key={sub.name}
                  className={`cd-sub-card ${isActive ? 'cd-sub-card--active' : ''}`}
                  style={{ '--cc': category.color, '--cbg': category.bg }}
                  onClick={() => handleSubClick(sub)}
                >
                  <div className="cd-sub-icon">
                    <SubIcon size={26} />
                  </div>
                  <div className="cd-sub-name">{sub.name}</div>
                  <div className="cd-sub-desc">{sub.desc}</div>
                  <div className="cd-sub-arrow">
                    <FiChevronRight size={14} />
                  </div>
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* ── Professionals ── */}
      <div className="cd-pros-wrap">
        <div className="container">
          <div className="cd-pros-header">
            <div>
              <h2 className="cd-section-title">
                {selectedSub
                  ? `${selectedSub.name} Experts`
                  : `All ${category.name} Professionals`}
              </h2>
              {!loading && searched && (
                <p className="cd-pros-count">
                  {professionals.length === 0
                    ? 'No professionals found'
                    : `${professionals.length} professional${professionals.length !== 1 ? 's' : ''} found`}
                </p>
              )}
            </div>
            <div className="cd-pros-controls">
              <div className="cd-sort-wrap">
                <FiSliders size={14} />
                <select
                  className="cd-sort-select"
                  value={sortBy}
                  onChange={e => setSortBy(e.target.value)}
                >
                  {SORT_OPTIONS.map(opt => (
                    <option key={opt.value} value={opt.value}>{opt.label}</option>
                  ))}
                </select>
              </div>
              <Link
                to={`/search?q=${encodeURIComponent(selectedSub?.name || category.name)}`}
                className="btn btn-outline btn-sm"
                style={{ flexShrink: 0 }}
              >
                View All <FiArrowRight size={13} />
              </Link>
            </div>
          </div>

          {loading ? (
            <div className="cd-loading">
              <LoadingSpinner />
              <p>Finding professionals…</p>
            </div>
          ) : sortedPros.length > 0 ? (
            <div className="cd-pros-grid">
              {sortedPros.map((pro) => (
                <div key={pro.id} className="cd-pro-card-wrap">
                  <ProfessionalCard professional={pro} />
                  {/* Online presence dot */}
                  {pro.isOnline !== undefined && (
                    <span
                      className={`cd-presence-dot ${pro.isOnline ? 'cd-presence-dot--online' : 'cd-presence-dot--offline'}`}
                      title={pro.isOnline ? 'Online now' : 'Offline'}
                    />
                  )}
                  {/* Enhanced footer: completed jobs + Book Now */}
                  <div className="cd-pro-extra">
                    {pro.completedJobs > 0 && (
                      <span className="cd-pro-jobs">
                        <FiCalendar size={12} /> {pro.completedJobs} jobs done
                      </span>
                    )}
                    <Link
                      to={`/bookings/create?professional_id=${pro.id}&professional_name=${encodeURIComponent(pro.name || '')}`}
                      className="btn btn-primary btn-sm cd-book-btn"
                    >
                      Book Now
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          ) : searched ? (
            <div className="cd-empty">
              <FiSearch size={44} />
              <h3>No professionals found</h3>
              <p>
                {selectedSub
                  ? `No one listed under "${selectedSub.name}" yet. Try a different sub-service.`
                  : `No professionals found for ${category.name} yet.`}
              </p>
              <div className="cd-empty-actions">
                {selectedSub && (
                  <button className="btn btn-outline btn-sm" onClick={() => { setSelectedSub(null); fetchPros(null); }}>
                    Show All {category.name}
                  </button>
                )}
                <Link to="/search" className="btn btn-primary btn-sm">
                  Browse All Professionals
                </Link>
              </div>
            </div>
          ) : null}
        </div>
      </div>

      {/* ── Other Categories ── */}
      <div className="cd-others">
        <div className="container">
          <h3 className="cd-section-title" style={{ marginBottom: '1rem' }}>Explore Other Categories</h3>
          <div className="cd-others-row">
            {categoriesData
              .filter((c) => c.slug !== slug)
              .slice(0, 5)
              .map((c) => {
                const OtherIcon = c.icon;
                return (
                  <Link
                    key={c.slug}
                    to={`/categories/${c.slug}`}
                    className="cd-other-chip"
                    style={{ '--oc': c.color, '--obg': c.bg }}
                  >
                    <OtherIcon size={14} />
                    {c.name}
                  </Link>
                );
              })}
            <Link to="/categories" className="cd-other-chip cd-other-chip--all">
              All Categories <FiArrowRight size={13} />
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}

export default CategoryDetail;
