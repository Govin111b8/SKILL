import { FiTool, FiZap, FiDroplet, FiBook, FiScissors, FiTruck, FiCamera, FiHome as FiHomeIcon } from 'react-icons/fi';
import { FaSearch, FaBalanceScale, FaHandshake } from 'react-icons/fa';
import SearchBar from '../components/SearchBar';
import CategoryCard from '../components/CategoryCard';
import './Home.css';

const featuredCategories = [
  { name: 'Plumbing', icon: FiDroplet, count: 120, slug: 'plumbing' },
  { name: 'Electrical', icon: FiZap, count: 95, slug: 'electrical' },
  { name: 'Home Repair', icon: FiTool, count: 80, slug: 'home-repair' },
  { name: 'Cleaning', icon: FiHomeIcon, count: 150, slug: 'cleaning' },
  { name: 'Tutoring', icon: FiBook, count: 200, slug: 'tutoring' },
  { name: 'Beauty', icon: FiScissors, count: 110, slug: 'beauty' },
  { name: 'Moving', icon: FiTruck, count: 65, slug: 'moving' },
  { name: 'Photography', icon: FiCamera, count: 75, slug: 'photography' },
];

const steps = [
  { icon: FaSearch, title: 'Search', description: 'Find professionals by skill, location, or category' },
  { icon: FaBalanceScale, title: 'Compare', description: 'Review ratings, portfolios, and pricing' },
  { icon: FaHandshake, title: 'Connect', description: 'Contact and hire the perfect professional' },
];

function Home() {
  return (
    <div className="home">
      <section className="hero">
        <div className="hero-content">
          <h1>Find Trusted Professionals Near You</h1>
          <p className="hero-subtitle">
            Connect with verified experts for any service you need. Quality work, fair prices, guaranteed satisfaction.
          </p>
          <SearchBar variant="hero" />
        </div>
      </section>

      <section className="section categories-section">
        <div className="container">
          <h2 className="section-title">Featured Categories</h2>
          <p className="section-subtitle">Browse our most popular service categories</p>
          <div className="categories-grid">
            {featuredCategories.map((cat) => (
              <CategoryCard key={cat.slug} category={cat} />
            ))}
          </div>
        </div>
      </section>

      <section className="section how-it-works">
        <div className="container">
          <h2 className="section-title">How It Works</h2>
          <p className="section-subtitle">Get started in three simple steps</p>
          <div className="steps-grid">
            {steps.map((step, i) => (
              <div key={i} className="step-card">
                <div className="step-number">{i + 1}</div>
                <div className="step-icon">
                  <step.icon size={28} />
                </div>
                <h3>{step.title}</h3>
                <p>{step.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="section stats-section">
        <div className="container">
          <div className="stats-grid">
            <div className="stat-card">
              <span className="stat-number">5,000+</span>
              <span className="stat-label">Professionals</span>
            </div>
            <div className="stat-card">
              <span className="stat-number">50+</span>
              <span className="stat-label">Categories</span>
            </div>
            <div className="stat-card">
              <span className="stat-number">100+</span>
              <span className="stat-label">Cities</span>
            </div>
            <div className="stat-card">
              <span className="stat-number">25,000+</span>
              <span className="stat-label">Happy Customers</span>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}

export default Home;
