import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiSearch, FiMapPin } from 'react-icons/fi';
import './SearchBar.css';

function SearchBar({ initialQuery = '', initialLocation = '', variant = 'default' }) {
  const [query, setQuery] = useState(initialQuery);
  const [location, setLocation] = useState(initialLocation);
  const navigate = useNavigate();

  function handleSubmit(e) {
    e.preventDefault();
    const params = new URLSearchParams();
    if (query) params.set('q', query);
    if (location) params.set('location', location);
    navigate(`/search?${params.toString()}`);
  }

  return (
    <form className={`search-bar ${variant}`} onSubmit={handleSubmit}>
      <div className="search-bar-field">
        <FiSearch className="search-bar-icon" />
        <input
          type="text"
          placeholder="What service are you looking for?"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          aria-label="Search services"
        />
      </div>
      <div className="search-bar-field">
        <FiMapPin className="search-bar-icon" />
        <input
          type="text"
          placeholder="Location"
          value={location}
          onChange={(e) => setLocation(e.target.value)}
          aria-label="Location"
        />
      </div>
      <button type="submit" className="btn btn-primary search-bar-btn">
        <FiSearch /> Search
      </button>
    </form>
  );
}

export default SearchBar;
