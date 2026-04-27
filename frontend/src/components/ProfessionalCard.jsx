import { Link } from 'react-router-dom';
import { FiMapPin, FiStar, FiArrowRight, FiCheck } from 'react-icons/fi';
import StarRating from './StarRating';
import './ProfessionalCard.css';

function ProfessionalCard({ professional }) {
  const {
    id, name, headline, photo, rating,
    reviews_count, location, categories, verified, pricing, available,
  } = professional;

  const initial = name ? name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2) : '?';

  return (
    <div className="pro-card">
      {/* Top badges */}
      <div className="pro-card-badges">
        {verified && (
          <span className="pro-badge pro-badge--verified">
            <FiCheck size={10} /> Verified
          </span>
        )}
        {available !== undefined && (
          <span className={`pro-badge pro-avail ${available ? 'pro-avail--on' : 'pro-avail--off'}`}>
            <span className="avail-dot" /> {available ? 'Available' : 'Busy'}
          </span>
        )}
      </div>

      {/* Photo */}
      <div className="pro-card-photo-wrap">
        {photo ? (
          <img
            src={photo}
            alt={name}
            className="pro-card-photo"
          />
        ) : (
          <div className="pro-card-initials">{initial}</div>
        )}
        {rating >= 4.8 && (
          <div className="pro-top-badge">
            <FiStar size={10} fill="#f59e0b" /> Top Rated
          </div>
        )}
      </div>

      {/* Info */}
      <div className="pro-card-body">
        <h3 className="pro-card-name">{name}</h3>
        {headline && <p className="pro-card-headline">{headline}</p>}

        <div className="pro-card-rating">
          <StarRating rating={rating || 0} readonly size={14} />
          <span className="pro-rating-num">{rating ? rating.toFixed(1) : '—'}</span>
          <span className="pro-rating-count">({reviews_count || 0})</span>
        </div>

        {location && (
          <div className="pro-card-location">
            <FiMapPin size={13} />
            <span>{location}</span>
          </div>
        )}

        {categories && categories.length > 0 && (
          <div className="pro-card-tags">
            {categories.slice(0, 3).map((cat, i) => (
              <span key={i} className="tag">{cat}</span>
            ))}
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="pro-card-footer">
        {pricing ? (
          <span className="pro-pricing">{pricing}</span>
        ) : (
          <span className="pro-pricing pro-pricing--free">Contact for price</span>
        )}
        <Link to={`/professionals/${id}`} className="btn btn-primary btn-sm pro-card-cta">
          View Profile <FiArrowRight size={13} />
        </Link>
      </div>
    </div>
  );
}

export default ProfessionalCard;
