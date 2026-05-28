import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { FiHeart, FiMapPin, FiStar, FiTrash2 } from 'react-icons/fi';
import { get, post } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './Favorites.css';

export default function Favorites() {
  const [favorites, setFavorites] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchFavorites();
  }, []);

  async function fetchFavorites() {
    try {
      const res = await get('/favorites');
      setFavorites(res.data || []);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  async function handleRemove(professionalId) {
    try {
      await post('/favorites/toggle', { professional_id: professionalId });
      setFavorites((prev) => prev.filter((f) => f.id !== professionalId));
    } catch (err) { console.error('Favorite toggle failed:', err.message); }
  }

  if (loading) return <LoadingSpinner />;

  return (
    <div className="favorites-page">
      <div className="container">
        <div className="favorites-header">
          <h1><FiHeart /> My Favorites</h1>
          <p className="favorites-subtitle">Professionals you've saved for quick access</p>
        </div>

        {error && <p className="favorites-error">{error}</p>}

        {favorites.length === 0 ? (
          <div className="favorites-empty">
            <FiHeart size={48} />
            <h3>No favorites yet</h3>
            <p>Save professionals you like to quickly find them later.</p>
            <Link to="/search" className="btn btn-primary">Find Professionals</Link>
          </div>
        ) : (
          <div className="favorites-grid">
            {favorites.map((fav) => (
              <div key={fav.id} className="favorite-card">
                <div className="favorite-card-top">
                  <img
                    src={fav.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(fav.name)}&background=6366f1&color=fff&size=80`}
                    alt={fav.name ? `${fav.name} profile` : 'User avatar'}
                    className="favorite-avatar"
                  />
                  <button
                    className="favorite-remove-btn"
                    onClick={() => handleRemove(fav.id)}
                    title="Remove from favorites"
                  >
                    <FiTrash2 />
                  </button>
                </div>
                <div className="favorite-card-body">
                  <Link to={`/professionals/${fav.id}`} className="favorite-name">{fav.name}</Link>
                  <p className="favorite-headline">{fav.headline || 'Professional'}</p>
                  {fav.location && (
                    <p className="favorite-location"><FiMapPin size={12} /> {fav.location}</p>
                  )}
                  <div className="favorite-stats">
                    <span className="favorite-rating"><FiStar size={12} fill="#f59e0b" color="#f59e0b" /> {Number(fav.avg_rating).toFixed(1)}</span>
                    <span className="favorite-reviews">{fav.review_count} reviews</span>
                    {fav.pricing_estimate && <span className="favorite-price">₹{fav.pricing_estimate}/hr</span>}
                  </div>
                  <span className={`favorite-status favorite-status--${fav.availability_status}`}>
                    {fav.availability_status}
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
