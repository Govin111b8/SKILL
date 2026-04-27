import { useState } from 'react';
import { Link } from 'react-router-dom';
import {
  FiDroplet, FiZap, FiTool, FiBook, FiScissors, FiTruck,
  FiCamera, FiHome, FiMusic, FiHeart, FiCpu, FiStar,
  FiSearch, FiArrowRight,
} from 'react-icons/fi';
import './Categories.css';

const categoriesData = [
  {
    name: 'Plumbing', slug: 'plumbing', icon: FiDroplet,
    color: '#3b82f6', bg: '#eff6ff',
    desc: 'Pipe repairs, drain cleaning, water heater installation and more',
    subcategories: ['Pipe Repair', 'Drain Cleaning', 'Water Heater', 'Bathroom Installation', 'Leak Detection'],
    popular: true,
  },
  {
    name: 'Electrical', slug: 'electrical', icon: FiZap,
    color: '#f59e0b', bg: '#fffbeb',
    desc: 'Wiring, panel upgrades, lighting, and outlet installations',
    subcategories: ['Wiring', 'Panel Upgrade', 'Lighting', 'Outlet Installation', 'EV Charger'],
    popular: true,
  },
  {
    name: 'Home Repair', slug: 'home-repair', icon: FiTool,
    color: '#8b5cf6', bg: '#f5f3ff',
    desc: 'Painting, carpentry, drywall, roofing and general handyman',
    subcategories: ['Painting', 'Carpentry', 'Drywall', 'Roofing', 'Flooring'],
  },
  {
    name: 'Cleaning', slug: 'cleaning', icon: FiHome,
    color: '#10b981', bg: '#ecfdf5',
    desc: 'Deep cleaning, move-in/out, office cleaning and window washing',
    subcategories: ['Deep Cleaning', 'Move-in/out', 'Office Cleaning', 'Window Washing', 'Carpet Cleaning'],
    popular: true,
  },
  {
    name: 'Tutoring', slug: 'tutoring', icon: FiBook,
    color: '#ef4444', bg: '#fef2f2',
    desc: 'Math, science, language tutoring and test prep',
    subcategories: ['Math', 'Science', 'Language', 'Test Prep', 'SAT/ACT'],
    popular: true,
  },
  {
    name: 'Beauty', slug: 'beauty', icon: FiScissors,
    color: '#ec4899', bg: '#fdf2f8',
    desc: 'Hair styling, makeup, nails, and skincare services',
    subcategories: ['Hair Styling', 'Makeup', 'Nails', 'Skincare', 'Eyebrows'],
  },
  {
    name: 'Moving', slug: 'moving', icon: FiTruck,
    color: '#64748b', bg: '#f8fafc',
    desc: 'Local and long-distance moving, packing and storage',
    subcategories: ['Local Moving', 'Long Distance', 'Packing', 'Storage', 'Assembly'],
  },
  {
    name: 'Photography', slug: 'photography', icon: FiCamera,
    color: '#f97316', bg: '#fff7ed',
    desc: 'Wedding, portrait, event and product photography',
    subcategories: ['Wedding', 'Portrait', 'Event', 'Product', 'Headshots'],
  },
  {
    name: 'Music', slug: 'music', icon: FiMusic,
    color: '#6366f1', bg: '#eef2ff',
    desc: 'Guitar, piano, voice lessons and DJ services',
    subcategories: ['Guitar Lessons', 'Piano Lessons', 'Voice', 'DJ Services', 'Recording'],
  },
  {
    name: 'Health & Fitness', slug: 'fitness', icon: FiHeart,
    color: '#14b8a6', bg: '#f0fdfa',
    desc: 'Personal training, yoga, nutrition coaching and massage',
    subcategories: ['Personal Training', 'Yoga', 'Nutrition', 'Massage', 'Pilates'],
    popular: true,
  },
  {
    name: 'Technology', slug: 'technology', icon: FiCpu,
    color: '#0ea5e9', bg: '#f0f9ff',
    desc: 'Computer repair, web design, IT support and smart home',
    subcategories: ['Computer Repair', 'Web Design', 'IT Support', 'Smart Home', 'Data Recovery'],
  },
  {
    name: 'Other Services', slug: 'other', icon: FiStar,
    color: '#a855f7', bg: '#faf5ff',
    desc: 'Pet care, landscaping, auto repair and event planning',
    subcategories: ['Pet Care', 'Landscaping', 'Auto Repair', 'Event Planning', 'Delivery'],
  },
];

function Categories() {
  const [search, setSearch] = useState('');
  const [active, setActive] = useState('All');

  const filters = ['All', 'Popular', 'Home', 'Education', 'Lifestyle'];

  const filtered = categoriesData.filter(cat => {
    const matchSearch = cat.name.toLowerCase().includes(search.toLowerCase()) ||
      cat.desc.toLowerCase().includes(search.toLowerCase());
    if (active === 'Popular') return matchSearch && cat.popular;
    if (active === 'Home') return matchSearch && ['plumbing', 'electrical', 'home-repair', 'cleaning', 'moving'].includes(cat.slug);
    if (active === 'Education') return matchSearch && ['tutoring', 'music', 'fitness'].includes(cat.slug);
    if (active === 'Lifestyle') return matchSearch && ['beauty', 'photography', 'fitness', 'music'].includes(cat.slug);
    return matchSearch;
  });

  return (
    <div className="categories-page">
      {/* Hero */}
      <div className="cat-hero">
        <div className="cat-hero-bg" />
        <div className="container">
          <div className="cat-hero-content">
            <span className="section-eyebrow" style={{color:'rgba(165,180,252,1)'}}>50+ Service Types</span>
            <h1>Browse All Categories</h1>
            <p>Find the perfect professional for any job, from home repair to creative services</p>

            <div className="cat-search-wrap">
              <FiSearch size={18} className="cat-search-icon" />
              <input
                type="text"
                placeholder="Search categories..."
                value={search}
                onChange={e => setSearch(e.target.value)}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Filter tabs */}
      <div className="cat-filter-bar">
        <div className="container">
          <div className="cat-filter-tabs">
            {filters.map(f => (
              <button
                key={f}
                className={`cat-filter-tab ${active === f ? 'active' : ''}`}
                onClick={() => setActive(f)}
              >
                {f}
              </button>
            ))}
            <span className="cat-count">{filtered.length} categories</span>
          </div>
        </div>
      </div>

      {/* Grid */}
      <div className="container" style={{ padding: '3rem 1.5rem 5rem' }}>
        {filtered.length === 0 ? (
          <div className="cat-empty">
            <FiSearch size={48} />
            <h3>No categories found</h3>
            <p>Try adjusting your search terms</p>
          </div>
        ) : (
          <div className="cat-grid">
            {filtered.map(cat => (
              <div key={cat.slug} className="cat-card" style={{ '--cat-color': cat.color, '--cat-bg': cat.bg }}>
                {cat.popular && (
                  <span className="cat-card-popular">Popular</span>
                )}
                <div className="cat-card-icon">
                  <cat.icon size={28} />
                </div>
                <h3 className="cat-card-name">{cat.name}</h3>
                <p className="cat-card-desc">{cat.desc}</p>
                <div className="cat-card-subs">
                  {cat.subcategories.slice(0, 4).map(sub => (
                    <Link
                      key={sub}
                      to={`/search?category=${cat.slug}&q=${encodeURIComponent(sub)}`}
                      className="cat-sub-link"
                    >
                      {sub}
                    </Link>
                  ))}
                </div>
                <Link to={`/search?category=${cat.slug}`} className="cat-card-cta">
                  Browse {cat.name} <FiArrowRight size={14} />
                </Link>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default Categories;
