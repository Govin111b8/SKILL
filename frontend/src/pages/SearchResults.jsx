import { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import {
  FiSearch, FiSliders, FiGrid, FiList, FiX, FiStar, FiArrowDown,
  FiChevronDown, FiFilter,
} from 'react-icons/fi';
import { get } from '../api/client';
import ProfessionalCard from '../components/ProfessionalCard';
import SearchBar from '../components/SearchBar';
import LoadingSpinner from '../components/LoadingSpinner';
import './SearchResults.css';

function mapProfessional(p) {
  return {
    ...p,
    rating: p.average_rating ?? p.rating ?? 0,
    reviews_count: parseInt(p.review_count || p.reviews_count || 0),
    available: p.availability_status === 'available',
    pricing: p.pricing_estimate || p.pricing,
    verified: p.reputation_score >= 4,
    provider_type: p.provider_type || 'individual',
    company_name: p.company_name,
    team_size: p.team_size,
    categories: p.categories?.map(c => typeof c === 'string' ? c : c.name) || [],
  };
}

const CATEGORIES = [
  'All', 'Plumbing', 'Electrical', 'Cleaning', 'Tutoring',
  'Beauty', 'Home Repair', 'Moving', 'Photography', 'Music', 'Fitness', 'Technology',
];

const SORT_OPTIONS = [
  { value: 'relevance', label: 'Relevance' },
  { value: 'rating', label: 'Top Rated' },
  { value: 'reviews', label: 'Most Reviewed' },
  { value: 'price_asc', label: 'Price: Low to High' },
  { value: 'price_desc', label: 'Price: High to Low' },
];

function SearchResults() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [viewMode, setViewMode] = useState('grid');
  const [sort, setSort] = useState('relevance');
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const [filters, setFilters] = useState({
    category: searchParams.get('category') || '',
    minRating: searchParams.get('minRating') || '0',
    minPrice: searchParams.get('minPrice') || '',
    maxPrice: searchParams.get('maxPrice') || '',
    available: searchParams.get('available') === 'true',
    provider_type: searchParams.get('provider_type') || '',
  });

  const query = searchParams.get('q') || '';
  const location = searchParams.get('location') || '';

  useEffect(() => { fetchResults(); }, [searchParams, page, sort]);

  async function fetchResults() {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (query) params.set('q', query);
      if (location) params.set('location', location);
      if (filters.category && filters.category !== 'All') params.set('category', filters.category);
      if (Number(filters.minRating) > 0) params.set('minRating', filters.minRating);
      if (filters.minPrice) params.set('minPrice', filters.minPrice);
      if (filters.maxPrice) params.set('maxPrice', filters.maxPrice);
      if (filters.available) params.set('available', 'true');
      if (filters.provider_type) params.set('provider_type', filters.provider_type);
      params.set('page', page);
      if (sort !== 'relevance') params.set('sort', sort);

      const res = await get(`/search?${params.toString()}`);
      const payload = res.data || res;
      const items = Array.isArray(payload) ? payload : (payload.professionals || payload.results || []);
      setResults(items.map(mapProfessional));
      setTotalPages(res.pagination?.pages || payload.totalPages || 1);
    } catch {
      setResults([]);
    } finally {
      setLoading(false);
    }
  }

  function handleFilterChange(key, value) {
    const newFilters = { ...filters, [key]: value };
    setFilters(newFilters);
    setPage(1);
    const params = new URLSearchParams(searchParams);
    if (value && value !== 'All' && value !== '0' && value !== false) {
      params.set(key, value);
    } else {
      params.delete(key);
    }
    setSearchParams(params);
  }

  function clearFilter(key) { handleFilterChange(key, key === 'minRating' ? '0' : key === 'available' ? false : ''); }

  // Active filter chips
  const activeFilters = [];
  if (filters.category && filters.category !== 'All') activeFilters.push({ key: 'category', label: filters.category });
  if (Number(filters.minRating) > 0) activeFilters.push({ key: 'minRating', label: `${filters.minRating}★+ Rating` });
  if (filters.minPrice) activeFilters.push({ key: 'minPrice', label: `Min $${filters.minPrice}` });
  if (filters.maxPrice) activeFilters.push({ key: 'maxPrice', label: `Max $${filters.maxPrice}` });
  if (filters.available) activeFilters.push({ key: 'available', label: 'Available now' });
  if (filters.provider_type) activeFilters.push({ key: 'provider_type', label: filters.provider_type === 'organization' ? 'Companies' : 'Individuals' });

  const ratingStars = [0, 3, 4, 4.5, 5];

  const sidebar = (
    <aside className={`sr-sidebar ${sidebarOpen ? 'sr-sidebar--open' : ''}`}>
      <div className="sr-sidebar-header">
        <h3><FiSliders size={16} /> Filters</h3>
        <button className="sr-sidebar-close" onClick={() => setSidebarOpen(false)}><FiX size={18} /></button>
      </div>

      <div className="filter-group">
        <label>Category</label>
        <div className="filter-cat-grid" role="group" aria-label="Filter by category">
          {CATEGORIES.map(cat => (
            <button
              key={cat}
              className={`filter-cat-btn ${(filters.category === (cat === 'All' ? '' : cat.toLowerCase())) || (cat === 'All' && !filters.category) ? 'active' : ''}`}
              onClick={() => handleFilterChange('category', cat === 'All' ? '' : cat.toLowerCase())}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      <div className="filter-group">
        <label>Minimum Rating</label>
        <div className="filter-rating-btns">
          {ratingStars.map(r => (
            <button
              key={r}
              className={`filter-rating-btn ${Number(filters.minRating) === r ? 'active' : ''}`}
              onClick={() => handleFilterChange('minRating', String(r))}
            >
              {r === 0 ? 'Any' : (
                <><FiStar size={12} fill={Number(filters.minRating) === r ? 'white' : '#f59e0b'} color={Number(filters.minRating) === r ? 'white' : '#f59e0b'} /> {r}+</>
              )}
            </button>
          ))}
        </div>
      </div>

      <div className="filter-group">
        <label>Price Range ($/hr)</label>
        <div className="price-inputs">
          <input type="number" placeholder="Min" value={filters.minPrice} onChange={e => handleFilterChange('minPrice', e.target.value)} />
          <span className="price-sep">–</span>
          <input type="number" placeholder="Max" value={filters.maxPrice} onChange={e => handleFilterChange('maxPrice', e.target.value)} />
        </div>
      </div>

      <div className="filter-group">
        <label className="filter-toggle-label">
          <span>Available Now</span>
          <div
            className={`toggle-switch ${filters.available ? 'on' : ''}`}
            onClick={() => handleFilterChange('available', !filters.available)}
          >
            <div className="toggle-thumb" />
          </div>
        </label>
      </div>

      <div className="filter-group">
        <label>Provider Type</label>
        <div className="filter-cat-grid">
          {[{ value: '', label: 'All' }, { value: 'individual', label: 'Individual' }, { value: 'organization', label: 'Company' }].map(opt => (
            <button
              key={opt.value}
              className={`filter-cat-btn ${filters.provider_type === opt.value ? 'active' : ''}`}
              onClick={() => handleFilterChange('provider_type', opt.value)}
            >
              {opt.label}
            </button>
          ))}
        </div>
      </div>

      {activeFilters.length > 0 && (
        <button className="btn btn-outline btn-sm" style={{width:'100%',justifyContent:'center',marginTop:'0.5rem'}}
          onClick={() => {
            setFilters({ category: '', minRating: '0', minPrice: '', maxPrice: '', available: false });
            setSearchParams(new URLSearchParams(query ? { q: query } : {}));
          }}
        >
          <FiX size={13} /> Clear All Filters
        </button>
      )}
    </aside>
  );

  return (
    <div className="sr-page">
      {/* Sticky results toolbar */}
      <div className="sr-toolbar">
        <div className="container">
          <div className="sr-toolbar-inner">
            <div className="sr-search-mini">
              <SearchBar initialQuery={query} initialLocation={location} />
            </div>
            <div className="sr-toolbar-right">
              <button className="sr-filter-toggle" onClick={() => setSidebarOpen(!sidebarOpen)} aria-label="Toggle filters">
                <FiFilter size={16} />
                Filters
                {activeFilters.length > 0 && <span className="sr-filter-badge">{activeFilters.length}</span>}
              </button>

              <div className="sr-sort">
                <label><FiArrowDown size={14} /></label>
                <select value={sort} onChange={e => setSort(e.target.value)} aria-label="Sort results">
                  {SORT_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
                </select>
              </div>

              <div className="sr-view-toggle">
                <button className={viewMode === 'grid' ? 'active' : ''} onClick={() => setViewMode('grid')} aria-label="Grid view">
                  <FiGrid size={16} />
                </button>
                <button className={viewMode === 'list' ? 'active' : ''} onClick={() => setViewMode('list')} aria-label="List view">
                  <FiList size={16} />
                </button>
              </div>
            </div>
          </div>

          {/* Active filter chips */}
          {activeFilters.length > 0 && (
            <div className="sr-active-filters">
              {activeFilters.map(f => (
                <span key={f.key} className="sr-chip">
                  {f.label}
                  <button onClick={() => clearFilter(f.key)}><FiX size={11} /></button>
                </span>
              ))}
            </div>
          )}
        </div>
      </div>

      <div className="container">
        <div className="sr-layout">
          {/* Sidebar */}
          {sidebar}
          {sidebarOpen && <div className="sr-overlay" onClick={() => setSidebarOpen(false)} />}

          {/* Main */}
          <div className="sr-main" role="region" aria-label="Search results">
            <div className="sr-results-header">
              <div>
                <h2 className="sr-heading">
                  {query ? <>“{query}”</> : 'All Professionals'}
                  {location && <span className="sr-location"> in {location}</span>}
                </h2>
                <p className="sr-count">{results.length} professional{results.length !== 1 ? 's' : ''} found</p>
              </div>
            </div>

            {loading ? (
              <div className="sr-loading"><LoadingSpinner /></div>
            ) : results.length > 0 ? (
              <>
                <div className={`sr-results-grid ${viewMode === 'list' ? 'sr-results-list' : ''}`}>
                  {results.map(pro => (
                    <ProfessionalCard key={pro.id} professional={pro} />
                  ))}
                </div>

                {totalPages > 1 && (
                  <div className="sr-pagination">
                    <button className="btn btn-outline" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>
                      ← Previous
                    </button>
                    {Array.from({ length: totalPages }, (_, i) => i + 1).map(p => (
                      <button
                        key={p}
                        className={`sr-page-btn ${p === page ? 'active' : ''}`}
                        onClick={() => setPage(p)}
                      >
                        {p}
                      </button>
                    ))}
                    <button className="btn btn-outline" disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}>
                      Next →
                    </button>
                  </div>
                )}
              </>
            ) : (
              <div className="sr-empty">
                <div className="sr-empty-icon"><FiSearch size={40} /></div>
                <h3>No professionals found</h3>
                <p>Try adjusting your search terms or clearing some filters</p>
                <button className="btn btn-primary" onClick={() => { setFilters({ category: '', minRating: '0', minPrice: '', maxPrice: '', available: false }); setSearchParams(new URLSearchParams()); }}>
                  Clear All Filters
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default SearchResults;
