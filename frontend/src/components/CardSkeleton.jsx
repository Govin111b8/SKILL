import PropTypes from 'prop-types';
import './CardSkeleton.css';

function CardSkeleton({ count = 3, variant = 'card' }) {
  return (
    <div className={`skeleton-grid skeleton-grid--${variant}`}>
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="skeleton-card" aria-hidden="true">
          <div className="skeleton-avatar skeleton-pulse" />
          <div className="skeleton-body">
            <div className="skeleton-line skeleton-line--title skeleton-pulse" />
            <div className="skeleton-line skeleton-line--subtitle skeleton-pulse" />
            <div className="skeleton-line skeleton-line--short skeleton-pulse" />
          </div>
        </div>
      ))}
    </div>
  );
}

CardSkeleton.propTypes = {
  count: PropTypes.number,
  variant: PropTypes.oneOf(['card', 'list', 'compact']),
};

export default CardSkeleton;
