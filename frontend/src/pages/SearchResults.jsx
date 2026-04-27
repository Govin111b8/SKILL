import { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import { get } from '../api/client';
import ProfessionalCard from '../components/ProfessionalCard';
import LoadingSpinner from '../components/LoadingSpinner';
import './SearchResults.css';

const CATEGORIES = [
  'All', 'Plumbing', 'Electrical', 'Cleaning', 'Tutoring',
  'Beauty', 'Home Repair', 'Moving', 'Photography', 'Cooking', 'Fitness',
];

function SearchResults() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  const [filters, setFilters] = useState({
    category: searchParams.get('category') || '',
    minRating: searchParams.get('minRating') || '0',
    minPrice: searchParams.get('minPrice') || '',
    maxPrice: searchParams.get('maxPrice') || '',
    available: searchParams.get('available') === 'true',
  });

  const query = searchParams.get('q') || '';
  const location = searchParams.get('location') || '';

  useEffect(() => {
    fetchResults();
  }, [searchParams, page]);

  async function fetchResults() {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (query) params.set('q', query);
      if (location) params.set('location', location);
      if (filters.category && filters.category !== 'All') params.set('category', filters.category);
      if (filters.minRating > 0) params.set('minRating', filters.minRating);
      if (filters.minPrice) params.set('minPrice', filters.minPrice);
      if (filters.maxPrice) params.set('maxPrice', filters.maxPrice);
      if (filters.available) params.set('available', 'true');
      params.set('page', page);

      const data = await get(`/professionals?${params.toString()}`);
      setResults(data.professionals || data.results || []);
      setTotalPages(data.totalPages || 1);
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

  return (
    <div className="search-results-page">
      <div className="container">
        <div className="search-results-layout">
          <aside className="search-sidebar">
            <h3>Filters</h3>

            <div className="filter-group">
              <label>Category</label>
              <select
                value={filters.category}
                onChange={(e) => handleFilterChange('category', e.target.value)}
              >
                {CATEGORIES.map((cat) => (
                  <option key={cat} value={cat === 'All' ? '' : cat.toLowerCase()}>
                    {cat}
                  </option>
                ))}
              </select>
            </div>

            <div className="filter-group">
              <label>Minimum Rating: {filters.minRating} stars</label>
              <input
                type="range"
                min="0"
                max="5"
                step="1"
                value={filters.minRating}
                onChange={(e) => handleFilterChange('minRating', e.target.value)}
              />
            </div>

            <div className="filter-group">
              <label>Price Range</label>
              <div className="price-inputs">
                <input
                  type="number"
                  placeholder="Min"
                  value={filters.minPrice}
                  onChange={(e) => handleFilterChange('minPrice', e.target.value)}
                />
                <span>–</span>
                <input
                  type="number"
                  placeholder="Max"
                  value={filters.maxPrice}
                  onChange={(e) => handleFilterChange('maxPrice', e.target.value)}
                />
              </div>
            </div>

            <div className="filter-group">
              <label className="checkbox-label">
                <input
                  type="checkbox"
                  checked={filters.available}
                  onChange={(e) => handleFilterChange('available', e.target.checked)}
                />
                Available now
              </label>
            </div>
          </aside>

          <div className="search-results-main">
            <div className="search-results-header">
              <h2>
                {query ? `Results for "${query}"` : 'All Professionals'}
                {location && ` in ${location}`}
              </h2>
              <span className="results-count">{results.length} found</span>
            </div>

            {loading ? (
              <LoadingSpinner />
            ) : results.length > 0 ? (
              <>
                <div className="results-grid">
                  {results.map((pro) => (
                    <ProfessionalCard key={pro.id} professional={pro} />
                  ))}
                </div>

                {totalPages > 1 && (
                  <div className="pagination">
                    <button
                      className="btn btn-outline"
                      disabled={page <= 1}
                      onClick={() => setPage(page - 1)}
                    >
                      Previous
                    </button>
                    <span className="page-info">
                      Page {page} of {totalPages}
                    </span>
                    <button
                      className="btn btn-outline"
                      disabled={page >= totalPages}
                      onClick={() => setPage(page + 1)}
                    >
                      Next
                    </button>
                  </div>
                )}
              </>
            ) : (
              <div className="no-results">
                <h3>No professionals found</h3>
                <p>Try adjusting your search or filters</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default SearchResults;
