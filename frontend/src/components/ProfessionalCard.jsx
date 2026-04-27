import { Link } from 'react-router-dom';
import { FiMapPin } from 'react-icons/fi';
import StarRating from './StarRating';
import './ProfessionalCard.css';

function ProfessionalCard({ professional }) {
  const {
    id,
    name,
    headline,
    photo,
    rating,
    reviews_count,
    location,
    categories,
    verified,
  } = professional;

  return (
    <div className="professional-card">
      <div className="professional-card-header">
        <img
          src={photo || `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&background=2563eb&color=fff`}
          alt={name}
          className="professional-card-photo"
        />
        {verified && <span className="professional-card-badge">✓ Verified</span>}
      </div>
      <div className="professional-card-body">
        <h3 className="professional-card-name">{name}</h3>
        <p className="professional-card-headline">{headline}</p>
        <div className="professional-card-rating">
          <StarRating rating={rating || 0} readonly />
          <span className="professional-card-reviews">({reviews_count || 0} reviews)</span>
        </div>
        <div className="professional-card-location">
          <FiMapPin size={14} />
          <span>{location || 'Location not set'}</span>
        </div>
        {categories && categories.length > 0 && (
          <div className="professional-card-tags">
            {categories.slice(0, 3).map((cat, i) => (
              <span key={i} className="tag">{cat}</span>
            ))}
          </div>
        )}
      </div>
      <div className="professional-card-footer">
        <Link to={`/professionals/${id}`} className="btn btn-primary btn-sm">
          View Profile
        </Link>
      </div>
    </div>
  );
}

export default ProfessionalCard;
