import PropTypes from 'prop-types';
import { useState, useRef, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiSearch, FiMapPin, FiX } from 'react-icons/fi';
import './SearchBar.css';

function SearchBar({ initialQuery = '', initialLocation = '', variant = 'default' }) {
  const [query, setQuery] = useState(initialQuery);
  const [location, setLocation] = useState(initialLocation);
  const navigate = useNavigate();
  const debounceRef = useRef(null);

  function handleSubmit(e) {
    e.preventDefault();
    if (debounceRef.current) clearTimeout(debounceRef.current);
    doSearch();
  }

  function doSearch() {
    const params = new URLSearchParams();
    if (query) params.set('q', query);
    if (location) params.set('location', location);
    navigate(`/search?${params.toString()}`);
  }

  const handleQueryChange = useCallback((e) => {
    const val = e.target.value;
    setQuery(val);
    // Debounce auto-search on typing (300ms)
    if (debounceRef.current) clearTimeout(debounceRef.current);
    if (val.length >= 3) {
      debounceRef.current = setTimeout(() => {
        const params = new URLSearchParams();
        params.set('q', val);
        if (location) params.set('location', location);
        navigate(`/search?${params.toString()}`);
      }, 300);
    }
  }, [location, navigate]);

  return (
    <form className={`search-bar search-bar--${variant}`} onSubmit={handleSubmit}>
      <div className="sb-fields">
        <div className="sb-field">
          <FiSearch className="sb-icon" size={18} />
          <input
            type="text"
            placeholder="What service are you looking for?"
            value={query}
            onChange={handleQueryChange}
            aria-label="Search services"
          />
          {query && (
            <button type="button" className="sb-clear" onClick={() => setQuery('')} aria-label="Clear">
              <FiX size={14} />
            </button>
          )}
        </div>
        <div className="sb-divider" />
        <div className="sb-field sb-field--location">
          <FiMapPin className="sb-icon" size={18} />
          <input
            type="text"
            placeholder="City, state or zip"
            value={location}
            onChange={e => setLocation(e.target.value)}
            aria-label="Location"
          />
        </div>
      </div>
      <button type="submit" className="sb-submit">
        <FiSearch size={18} />
        <span>Search</span>
      </button>
    </form>
  );
}

SearchBar.propTypes = {
  initialQuery: PropTypes.string,
  initialLocation: PropTypes.string,
  variant: PropTypes.oneOf(['default', 'compact', 'hero']),
};

export default SearchBar;
