import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import './CategoryCard.css';

function CategoryCard({ category }) {
  const { name, icon: Icon, count, slug } = category;

  return (
    <Link to={`/search?category=${slug || name.toLowerCase()}`} className="category-card">
      <div className="category-card-icon">
        {Icon && <Icon size={32} />}
      </div>
      <h3 className="category-card-name">{name}</h3>
      {count !== undefined && (
        <span className="category-card-count">{count} professionals</span>
      )}
    </Link>
  );
}

CategoryCard.propTypes = {
  category: PropTypes.shape({
    name: PropTypes.string.isRequired,
    icon: PropTypes.elementType,
    count: PropTypes.number,
    slug: PropTypes.string,
  }).isRequired,
};

import { memo } from 'react';

export default memo(CategoryCard);
