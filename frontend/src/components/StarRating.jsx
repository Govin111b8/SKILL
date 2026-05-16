import PropTypes from 'prop-types';
import { FiStar } from 'react-icons/fi';
import { FaStar, FaStarHalfAlt } from 'react-icons/fa';
import './StarRating.css';

function StarRating({ rating = 0, onChange, readonly = true, size = 16 }) {
  function handleClick(value) {
    if (!readonly && onChange) {
      onChange(value);
    }
  }

  const stars = [];
  for (let i = 1; i <= 5; i++) {
    if (rating >= i) {
      stars.push(
        <button
          key={i}
          type="button"
          className="star-btn filled"
          onClick={() => handleClick(i)}
          disabled={readonly}
          aria-label={`${i} star`}
        >
          <FaStar size={size} />
        </button>
      );
    } else if (rating >= i - 0.5) {
      stars.push(
        <button
          key={i}
          type="button"
          className="star-btn half"
          onClick={() => handleClick(i)}
          disabled={readonly}
          aria-label={`${i} star`}
        >
          <FaStarHalfAlt size={size} />
        </button>
      );
    } else {
      stars.push(
        <button
          key={i}
          type="button"
          className="star-btn empty"
          onClick={() => handleClick(i)}
          disabled={readonly}
          aria-label={`${i} star`}
        >
          <FiStar size={size} />
        </button>
      );
    }
  }

  return <div className={`star-rating ${readonly ? 'readonly' : 'interactive'}`}>{stars}</div>;
}

StarRating.propTypes = {
  rating: PropTypes.number,
  onChange: PropTypes.func,
  readonly: PropTypes.bool,
  size: PropTypes.number,
};

export default StarRating;
