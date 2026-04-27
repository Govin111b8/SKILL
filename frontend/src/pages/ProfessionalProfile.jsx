import { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { FiMapPin, FiClock, FiDollarSign, FiPhone, FiMail, FiMessageSquare } from 'react-icons/fi';
import { get } from '../api/client';
import { useAuth } from '../context/AuthContext';
import StarRating from '../components/StarRating';
import ReviewCard from '../components/ReviewCard';
import LoadingSpinner from '../components/LoadingSpinner';
import './ProfessionalProfile.css';

function ProfessionalProfile() {
  const { id } = useParams();
  const { isAuthenticated } = useAuth();
  const [professional, setProfessional] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('about');
  const [showContact, setShowContact] = useState(false);

  useEffect(() => {
    fetchProfessional();
  }, [id]);

  async function fetchProfessional() {
    try {
      const data = await get(`/professionals/${id}`);
      setProfessional(data.professional || data);
    } catch {
      setProfessional(null);
    } finally {
      setLoading(false);
    }
  }

  if (loading) return <LoadingSpinner />;

  if (!professional) {
    return (
      <div className="profile-not-found">
        <h2>Professional not found</h2>
        <p>The profile you&apos;re looking for doesn&apos;t exist.</p>
      </div>
    );
  }

  const {
    name, headline, photo, rating, reviews_count, location,
    bio, years_of_experience, pricing, categories,
    portfolio, reviews, phone, email, available,
  } = professional;

  return (
    <div className="profile-page">
      <div className="profile-hero">
        <div className="container">
          <div className="profile-hero-content">
            <img
              src={photo || `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&size=120&background=2563eb&color=fff`}
              alt={name}
              className="profile-photo"
            />
            <div className="profile-hero-info">
              <h1>{name}</h1>
              <p className="profile-headline">{headline}</p>
              <div className="profile-meta">
                <span className="profile-rating">
                  <StarRating rating={rating || 0} readonly size={18} />
                  <span>({reviews_count || 0} reviews)</span>
                </span>
                {location && (
                  <span className="profile-location">
                    <FiMapPin /> {location}
                  </span>
                )}
                {years_of_experience && (
                  <span><FiClock /> {years_of_experience} years experience</span>
                )}
              </div>
              {available !== undefined && (
                <span className={`availability-badge ${available ? 'available' : 'unavailable'}`}>
                  {available ? '● Available' : '● Unavailable'}
                </span>
              )}
            </div>
            <div className="profile-hero-action">
              <button
                className="btn btn-primary"
                onClick={() => setShowContact(true)}
              >
                Contact Professional
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="container">
        <div className="profile-tabs">
          <button
            className={`tab-btn ${activeTab === 'about' ? 'active' : ''}`}
            onClick={() => setActiveTab('about')}
          >
            About
          </button>
          <button
            className={`tab-btn ${activeTab === 'portfolio' ? 'active' : ''}`}
            onClick={() => setActiveTab('portfolio')}
          >
            Portfolio
          </button>
          <button
            className={`tab-btn ${activeTab === 'reviews' ? 'active' : ''}`}
            onClick={() => setActiveTab('reviews')}
          >
            Reviews ({reviews_count || 0})
          </button>
        </div>

        <div className="profile-tab-content">
          {activeTab === 'about' && (
            <div className="tab-about">
              <div className="about-section">
                <h3>About</h3>
                <p>{bio || 'No bio provided.'}</p>
              </div>
              {pricing && (
                <div className="about-section">
                  <h3>Pricing</h3>
                  <p className="pricing-display">
                    <FiDollarSign /> {pricing}
                  </p>
                </div>
              )}
              {categories && categories.length > 0 && (
                <div className="about-section">
                  <h3>Services</h3>
                  <div className="profile-categories">
                    {categories.map((cat, i) => (
                      <span key={i} className="tag">{cat}</span>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}

          {activeTab === 'portfolio' && (
            <div className="tab-portfolio">
              {portfolio && portfolio.length > 0 ? (
                <div className="portfolio-grid">
                  {portfolio.map((item, i) => (
                    <div key={i} className="portfolio-item">
                      <img src={item.image || item} alt={`Portfolio ${i + 1}`} />
                    </div>
                  ))}
                </div>
              ) : (
                <p className="empty-state">No portfolio items yet.</p>
              )}
            </div>
          )}

          {activeTab === 'reviews' && (
            <div className="tab-reviews">
              {reviews && reviews.length > 0 ? (
                reviews.map((review, i) => (
                  <ReviewCard key={i} review={review} />
                ))
              ) : (
                <p className="empty-state">No reviews yet.</p>
              )}
            </div>
          )}
        </div>
      </div>

      {showContact && (
        <div className="modal-overlay" onClick={() => setShowContact(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <h3>Contact {name}</h3>
            {isAuthenticated ? (
              <div className="contact-options">
                {phone && (
                  <a href={`tel:${phone}`} className="contact-option">
                    <FiPhone size={20} />
                    <span>Call: {phone}</span>
                  </a>
                )}
                {email && (
                  <a href={`mailto:${email}`} className="contact-option">
                    <FiMail size={20} />
                    <span>Email: {email}</span>
                  </a>
                )}
                <button className="contact-option">
                  <FiMessageSquare size={20} />
                  <span>Request a Quote</span>
                </button>
              </div>
            ) : (
              <div className="contact-login-prompt">
                <p>Please log in to contact this professional.</p>
                <a href="/login" className="btn btn-primary">Log In</a>
              </div>
            )}
            <button className="modal-close" onClick={() => setShowContact(false)}>
              Close
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

export default ProfessionalProfile;
