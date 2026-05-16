import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { FiSearch, FiArrowRight, FiChevronDown, FiChevronUp, FiHome } from 'react-icons/fi';
import { get } from '../api/client';
import { categoriesData } from '../data/categories';
import './Categories.css';

/**
 * Merge API categories into the static data so we keep icons/colors while
 * gaining real sub-category counts from the backend when available.
 */
function mergeCategories(staticCats, apiCats) {
  if (!apiCats || apiCats.length === 0) return staticCats;

  const apiMap = new Map();
  apiCats.forEach(c => {
    apiMap.set(c.name.toLowerCase(), c);
  });

  // Enhance static cats with API children counts
  const merged = staticCats.map(sc => {
    const match = apiMap.get(sc.name.toLowerCase());
    if (match) {
      return {
        ...sc,
        apiId: match.id,
        apiChildren: match.children || [],
        apiDescription: match.description,
      };
    }
    return sc;
  });

  // Add any API-only categories not in static data
  apiCats.filter(ac => ac.parent_id === null).forEach(ac => {
    const exists = staticCats.some(sc => sc.name.toLowerCase() === ac.name.toLowerCase());
    if (!exists && ac.name) {
      merged.push({
        name: ac.name,
        slug: ac.name.toLowerCase().replace(/\s+/g, '-'),
        icon: FiHome,
        color: '#6366f1',
        bg: '#eef2ff',
        desc: ac.description || '',
        popular: false,
        subcategories: (ac.children || []).map(ch => ({
          name: ch.name,
          icon: FiHome,
          desc: ch.description || '',
        })),
        apiId: ac.id,
        apiChildren: ac.children || [],
      });
    }
  });

  return merged;
}

function Categories() {
  const [search, setSearch] = useState('');
  const [active, setActive] = useState('All');
  const [expandedSlug, setExpandedSlug] = useState(null);
  const [categories, setCategories] = useState(categoriesData);

  useEffect(() => {
    let cancelled = false;
    get('/categories')
      .then(res => {
        if (cancelled) return;
        const data = res?.data || res || [];
        const topLevel = Array.isArray(data) ? data.filter(c => c.parent_id === null || c.parent_id === undefined) : [];
        if (topLevel.length > 0) {
          setCategories(prev => mergeCategories(prev, topLevel));
        }
      })
      .catch((err) => {
        console.error('Failed to load categories from API:', err.message);
        // API unavailable — keep static data
      });
    return () => { cancelled = true; };
  }, []);

  const filters = ['All', 'Popular', 'Home', 'Education', 'Lifestyle'];

  const filtered = categories.filter(cat => {
    const matchSearch =
      cat.name.toLowerCase().includes(search.toLowerCase()) ||
      cat.desc.toLowerCase().includes(search.toLowerCase()) ||
      cat.subcategories.some(s => s.name.toLowerCase().includes(search.toLowerCase()));
    if (active === 'Popular') return matchSearch && cat.popular;
    if (active === 'Home')
      return matchSearch && ['plumbing', 'electrical', 'home-repair', 'cleaning', 'moving'].includes(cat.slug);
    if (active === 'Education')
      return matchSearch && ['tutoring', 'music', 'fitness'].includes(cat.slug);
    if (active === 'Lifestyle')
      return matchSearch && ['beauty', 'photography', 'fitness', 'music'].includes(cat.slug);
    return matchSearch;
  });

  function toggleExpand(slug) {
    setExpandedSlug(prev => (prev === slug ? null : slug));
  }

  return (
    <div className="categories-page">
      {/* Breadcrumb */}
      <div className="cat-breadcrumb">
        <div className="container">
          <nav className="breadcrumb-nav">
            <Link to="/">Home</Link>
            <span className="breadcrumb-sep">/</span>
            <span className="breadcrumb-current">Services</span>
          </nav>
        </div>
      </div>

      {/* Hero */}
      <div className="cat-hero">
        <div className="cat-hero-bg" />
        <div className="container">
          <div className="cat-hero-content">
            <span className="section-eyebrow" style={{ color: 'rgba(165,180,252,1)' }}>
              {categories.length} Service Categories
            </span>
            <h1>Browse All Services</h1>
            <p>Find the perfect professional for any job, from home repair to creative services</p>
            <div className="cat-search-wrap">
              <FiSearch size={18} className="cat-search-icon" />
              <input
                type="text"
                placeholder="Search categories or services…"
                value={search}
                onChange={e => setSearch(e.target.value)}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Filter tabs */}
      <div className="cat-filter-bar">
        <div className="container">
          <div className="cat-filter-tabs">
            {filters.map(f => (
              <button
                key={f}
                className={`cat-filter-tab ${active === f ? 'active' : ''}`}
                onClick={() => setActive(f)}
              >
                {f}
              </button>
            ))}
            <span className="cat-count">{filtered.length} categories</span>
          </div>
        </div>
      </div>

      {/* Grid */}
      <div className="container" style={{ padding: '3rem 1.5rem 5rem' }}>
        {filtered.length === 0 ? (
          <div className="cat-empty">
            <FiSearch size={48} />
            <h3>No categories found</h3>
            <p>Try adjusting your search terms</p>
          </div>
        ) : (
          <div className="cat-grid">
            {filtered.map(cat => {
              const CatIcon = cat.icon;
              const isExpanded = expandedSlug === cat.slug;
              return (
                <div
                  key={cat.slug}
                  className={`cat-card ${isExpanded ? 'cat-card--expanded' : ''}`}
                  style={{ '--cat-color': cat.color, '--cat-bg': cat.bg }}
                >
                  {cat.popular && <span className="cat-card-popular">Popular</span>}
                  <div className="cat-card-icon">
                    <CatIcon size={28} />
                  </div>
                  <h3 className="cat-card-name">{cat.name}</h3>
                  <p className="cat-card-desc">{cat.desc}</p>

                  <div className="cat-card-meta">
                    <span className="cat-sub-count">{cat.subcategories.length} sub-services</span>
                    <button
                      className="cat-expand-btn"
                      onClick={() => toggleExpand(cat.slug)}
                      aria-label={isExpanded ? 'Collapse sub-services' : 'Expand sub-services'}
                    >
                      {isExpanded ? <FiChevronUp size={16} /> : <FiChevronDown size={16} />}
                    </button>
                  </div>

                  {/* Inline sub-categories (expandable) */}
                  <div className={`cat-card-subs-expandable ${isExpanded ? 'cat-card-subs-expandable--open' : ''}`}>
                    <div className="cat-card-subs-inner">
                      {cat.subcategories.map(sub => {
                        const SubIcon = sub.icon;
                        return (
                          <Link
                            key={sub.name}
                            to={`/categories/${cat.slug}?sub=${encodeURIComponent(sub.name)}`}
                            className="cat-sub-link"
                          >
                            <SubIcon size={11} />
                            {sub.name}
                          </Link>
                        );
                      })}
                    </div>
                  </div>

                  {/* Always-visible preview chips */}
                  {!isExpanded && (
                    <div className="cat-card-subs">
                      {cat.subcategories.slice(0, 4).map(sub => {
                        const SubIcon = sub.icon;
                        return (
                          <Link
                            key={sub.name}
                            to={`/categories/${cat.slug}`}
                            className="cat-sub-link"
                          >
                            <SubIcon size={11} />
                            {sub.name}
                          </Link>
                        );
                      })}
                      {cat.subcategories.length > 4 && (
                        <span className="cat-sub-more">+{cat.subcategories.length - 4} more</span>
                      )}
                    </div>
                  )}

                  <Link to={`/categories/${cat.slug}`} className="cat-card-cta">
                    Browse {cat.name} <FiArrowRight size={14} />
                  </Link>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}

export default Categories;
