import { useState } from 'react';
import { Link } from 'react-router-dom';
import { FiSearch, FiArrowRight } from 'react-icons/fi';
import { categoriesData } from '../data/categories';
import './Categories.css';

function Categories() {
  const [search, setSearch] = useState('');
  const [active, setActive] = useState('All');

  const filters = ['All', 'Popular', 'Home', 'Education', 'Lifestyle'];

  const filtered = categoriesData.filter(cat => {
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

  return (
    <div className="categories-page">
      {/* Hero */}
      <div className="cat-hero">
        <div className="cat-hero-bg" />
        <div className="container">
          <div className="cat-hero-content">
            <span className="section-eyebrow" style={{ color: 'rgba(165,180,252,1)' }}>
              {categoriesData.length} Service Categories
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
              return (
                <div
                  key={cat.slug}
                  className="cat-card"
                  style={{ '--cat-color': cat.color, '--cat-bg': cat.bg }}
                >
                  {cat.popular && <span className="cat-card-popular">Popular</span>}
                  <div className="cat-card-icon">
                    <CatIcon size={28} />
                  </div>
                  <h3 className="cat-card-name">{cat.name}</h3>
                  <p className="cat-card-desc">{cat.desc}</p>
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
                  </div>
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
