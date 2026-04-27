import { useState } from 'react';
import { Link } from 'react-router-dom';
import {
  FiDroplet, FiZap, FiTool, FiBook, FiScissors, FiTruck,
  FiCamera, FiHome, FiMusic, FiHeart, FiCpu, FiStar,
} from 'react-icons/fi';
import './Categories.css';

const categoriesData = [
  {
    name: 'Plumbing',
    slug: 'plumbing',
    icon: FiDroplet,
    subcategories: ['Pipe Repair', 'Drain Cleaning', 'Water Heater', 'Bathroom Installation'],
  },
  {
    name: 'Electrical',
    slug: 'electrical',
    icon: FiZap,
    subcategories: ['Wiring', 'Panel Upgrade', 'Lighting', 'Outlet Installation'],
  },
  {
    name: 'Home Repair',
    slug: 'home-repair',
    icon: FiTool,
    subcategories: ['Painting', 'Carpentry', 'Drywall', 'Roofing'],
  },
  {
    name: 'Cleaning',
    slug: 'cleaning',
    icon: FiHome,
    subcategories: ['Deep Cleaning', 'Move-in/out', 'Office Cleaning', 'Window Washing'],
  },
  {
    name: 'Tutoring',
    slug: 'tutoring',
    icon: FiBook,
    subcategories: ['Math', 'Science', 'Language', 'Test Prep'],
  },
  {
    name: 'Beauty',
    slug: 'beauty',
    icon: FiScissors,
    subcategories: ['Hair Styling', 'Makeup', 'Nails', 'Skincare'],
  },
  {
    name: 'Moving',
    slug: 'moving',
    icon: FiTruck,
    subcategories: ['Local Moving', 'Long Distance', 'Packing', 'Storage'],
  },
  {
    name: 'Photography',
    slug: 'photography',
    icon: FiCamera,
    subcategories: ['Wedding', 'Portrait', 'Event', 'Product'],
  },
  {
    name: 'Music',
    slug: 'music',
    icon: FiMusic,
    subcategories: ['Guitar Lessons', 'Piano Lessons', 'Voice', 'DJ Services'],
  },
  {
    name: 'Health & Fitness',
    slug: 'fitness',
    icon: FiHeart,
    subcategories: ['Personal Training', 'Yoga', 'Nutrition', 'Massage'],
  },
  {
    name: 'Technology',
    slug: 'technology',
    icon: FiCpu,
    subcategories: ['Computer Repair', 'Web Design', 'IT Support', 'Smart Home'],
  },
  {
    name: 'Other Services',
    slug: 'other',
    icon: FiStar,
    subcategories: ['Pet Care', 'Landscaping', 'Auto Repair', 'Event Planning'],
  },
];

function Categories() {
  const [expandedCategory, setExpandedCategory] = useState(null);

  function toggleCategory(slug) {
    setExpandedCategory(expandedCategory === slug ? null : slug);
  }

  return (
    <div className="categories-page">
      <div className="container">
        <div className="categories-header">
          <h1>Browse Categories</h1>
          <p>Find the right professional for any job</p>
        </div>

        <div className="categories-list">
          {categoriesData.map((cat) => (
            <div key={cat.slug} className="category-item">
              <button
                className={`category-item-header ${expandedCategory === cat.slug ? 'expanded' : ''}`}
                onClick={() => toggleCategory(cat.slug)}
              >
                <div className="category-item-left">
                  <div className="category-item-icon">
                    <cat.icon size={24} />
                  </div>
                  <span className="category-item-name">{cat.name}</span>
                </div>
                <span className="category-item-toggle">
                  {expandedCategory === cat.slug ? '−' : '+'}
                </span>
              </button>

              {expandedCategory === cat.slug && (
                <div className="category-subcategories">
                  {cat.subcategories.map((sub) => (
                    <Link
                      key={sub}
                      to={`/search?category=${cat.slug}&q=${encodeURIComponent(sub)}`}
                      className="subcategory-link"
                    >
                      {sub}
                    </Link>
                  ))}
                  <Link
                    to={`/search?category=${cat.slug}`}
                    className="subcategory-link view-all"
                  >
                    View all {cat.name} →
                  </Link>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

export default Categories;
