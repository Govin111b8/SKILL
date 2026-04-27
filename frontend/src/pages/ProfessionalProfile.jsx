import { useState, useEffect, useRef } from 'react';
import { useParams, Link } from 'react-router-dom';
import {
  FiMapPin, FiClock, FiDollarSign, FiPhone, FiMail, FiMessageSquare,
  FiStar, FiCheck, FiShare2, FiHeart, FiArrowLeft, FiX,
} from 'react-icons/fi';
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
  const [saved, setSaved] = useState(false);
  const tabsRef = useRef(null);

  useEffect(() => { fetchProfessional(); }, [id]);

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

  function scrollToTabs() {
    tabsRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  if (loading) return <div style={{padding:'4rem'}}><LoadingSpinner /></div>;

  if (!professional) {
    return (
      <div className="profile-not-found">
        <h2>Professional not found</h2>
        <p>This profile doesn&apos;t exist or may have been removed.</p>
        <Link to="/search" className="btn btn-primary">Browse Professionals</Link>
      </div>
    );
  }

  const {
    name, headline, photo, rating, reviews_count, location,
    bio, years_of_experience, pricing, categories,
    portfolio, reviews, phone, email, available, verified,
  } = professional;

  const initials = name?.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);

  return (
    <div className="profile-page">
      {/* ── Hero ── */}
      <div className="profile-hero">
        <div className="profile-hero-bg" />
        <div className="container">
          <Link to="/search" className="profile-back">
            <FiArrowLeft size={16} /> Back to results
          </Link>

          <div className="profile-hero-layout">
            <div className="profile-hero-main">
              {/* Avatar */}
              <div className="profile-photo-wrap">
                {photo ? (
                  <img src={photo} alt={name} className="profile-photo" />
                ) : (
                  <div className="profile-initials">{initials}</div>
                )}
                {verified && (
                  <div className="profile-verified-ring">
                    <FiCheck size={12} />
                  </div>
                )}
              </div>

              {/* Info */}
              <div className="profile-info">
                <div className="profile-name-row">
                  <h1>{name}</h1>
                  {available !== undefined && (
                    <span className={`profile-avail ${available ? 'on' : 'off'}`}>
                      <span className="avail-dot" /> {available ? 'Available' : 'Unavailable'}
                    </span>
                  )}
                </div>

                {headline && <p className="profile-headline">{headline}</p>}

                <div className="profile-meta-row">
                  <div className="profile-rating-display">
                    <StarRating rating={rating || 0} readonly size={16} />
                    <span className="profile-rating-num">{rating ? rating.toFixed(1) : '—'}</span>
                    <span className="profile-rating-count">({reviews_count || 0} reviews)</span>
                  </div>
                  {location && (
                    <span className="profile-meta-item">
                      <FiMapPin size={14} /> {location}
                    </span>
                  )}
                  {years_of_experience && (
                    <span className="profile-meta-item">
                      <FiClock size={14} /> {years_of_experience} yrs exp.
                    </span>
                  )}
                </div>

                {categories && categories.length > 0 && (
                  <div className="profile-tags">
                    {categories.map((cat, i) => (
                      <span key={i} className="tag">{cat}</span>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Hero CTA */}
            <div className="profile-hero-cta">
              <button className="btn btn-primary btn-lg profile-contact-btn" onClick={() => setShowContact(true)}>
                <FiPhone size={18} /> Contact Professional
              </button>
              <div className="profile-hero-cta-actions">
                <button className={`profile-action-btn ${saved ? 'saved' : ''}`} onClick={() => setSaved(!saved)}>
                  <FiHeart size={16} fill={saved ? '#ef4444' : 'none'} color={saved ? '#ef4444' : 'currentColor'} />
                  {saved ? 'Saved' : 'Save'}
                </button>
                <button className="profile-action-btn" onClick={() => navigator.share?.({ title: name, url: window.location.href })}>
                  <FiShare2 size={16} /> Share
                </button>
              </div>
              {pricing && (
                <div className="profile-pricing-tag">
                  <FiDollarSign size={15} /> <span>{pricing}</span>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* ── Sticky Tabs ── */}
      <div className="profile-tabs-bar" ref={tabsRef}>
        <div className="container">
          {['about', 'portfolio', 'reviews'].map(tab => (
            <button
              key={tab}
              className={`profile-tab ${activeTab === tab ? 'active' : ''}`}
              onClick={() => setActiveTab(tab)}
            >
              {tab === 'about' ? 'About' : tab === 'portfolio' ? 'Portfolio' : `Reviews (${reviews_count || 0})`}
            </button>
          ))}
        </div>
      </div>

      {/* ── Content ── */}
      <div className="container">
        <div className="profile-content-layout">
          <div className="profile-main-content">
            {activeTab === 'about' && (
              <div className="profile-tab-panel animate-fade-up">
                {bio && (
                  <div className="profile-section">
                    <h3>About {name}</h3>
                    <p className="profile-bio">{bio}</p>
                  </div>
                )}

                {categories && categories.length > 0 && (
                  <div className="profile-section">
                    <h3>Services Offered</h3>
                    <div className="profile-services-grid">
                      {categories.map((cat, i) => (
                        <div key={i} className="profile-service-item">
                          <FiCheck size={14} color="var(--success)" />
                          {cat}
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {pricing && (
                  <div className="profile-section">
                    <h3>Pricing</h3>
                    <div className="profile-pricing-display">
                      <FiDollarSign size={20} color="var(--primary)" />
                      <span>{pricing}</span>
                    </div>
                  </div>
                )}
              </div>
            )}

            {activeTab === 'portfolio' && (
              <div className="profile-tab-panel animate-fade-up">
                <div className="profile-section">
                  <h3>Portfolio</h3>
                  {portfolio && portfolio.length > 0 ? (
                    <div className="profile-portfolio-grid">
                      {portfolio.map((item, i) => (
                        <div key={i} className="portfolio-item">
                          <img src={item.image || item} alt={`Work ${i + 1}`} />
                          {item.title && <div className="portfolio-item-label">{item.title}</div>}
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="profile-empty">
                      <FiStar size={36} />
                      <p>No portfolio items yet.</p>
                    </div>
                  )}
                </div>
              </div>
            )}

            {activeTab === 'reviews' && (
              <div className="profile-tab-panel animate-fade-up">
                <div className="profile-section">
                  <div className="reviews-header">
                    <h3>Reviews</h3>
                    {reviews_count > 0 && (
                      <div className="reviews-summary">
                        <span className="reviews-big-rating">{rating?.toFixed(1)}</span>
                        <div>
                          <StarRating rating={rating || 0} readonly size={18} />
                          <p style={{fontSize:'0.8rem',color:'var(--gray-500)'}}>{reviews_count} reviews</p>
                        </div>
                      </div>
                    )}
                  </div>
                  {reviews && reviews.length > 0 ? (
                    <div className="reviews-list">
                      {reviews.map((review, i) => (
                        <ReviewCard key={i} review={review} />
                      ))}
                    </div>
                  ) : (
                    <div className="profile-empty">
                      <FiStar size={36} />
                      <p>No reviews yet. Be the first!</p>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>

          {/* Sticky contact sidebar */}
          <aside className="profile-cta-sidebar">
            <div className="profile-cta-card">
              <div className="cta-card-header">
                {photo ? (
                  <img src={photo} alt={name} className="cta-card-photo" />
                ) : (
                  <div className="cta-card-initials">{initials}</div>
                )}
                <div>
                  <p className="cta-card-name">{name}</p>
                  {location && <p className="cta-card-location"><FiMapPin size={12} /> {location}</p>}
                </div>
              </div>

              {available !== undefined && (
                <div className={`cta-avail-banner ${available ? 'available' : ''}`}>
                  <span className="avail-dot" />
                  {available ? 'Currently Available' : 'Currently Unavailable'}
                </div>
              )}

              <button className="btn btn-primary" style={{width:'100%',justifyContent:'center'}} onClick={() => setShowContact(true)}>
                <FiPhone size={16} /> Contact {name?.split(' ')[0]}
              </button>

              {pricing && (
                <div className="cta-pricing">
                  <FiDollarSign size={14} />
                  <span>{pricing}</span>
                </div>
              )}

              <div className="cta-stats">
                <div className="cta-stat">
                  <span className="cta-stat-val">{rating?.toFixed(1) || '—'}</span>
                  <span className="cta-stat-label">Rating</span>
                </div>
                <div className="cta-stat-divider" />
                <div className="cta-stat">
                  <span className="cta-stat-val">{reviews_count || 0}</span>
                  <span className="cta-stat-label">Reviews</span>
                </div>
                <div className="cta-stat-divider" />
                <div className="cta-stat">
                  <span className="cta-stat-val">{years_of_experience || '—'}</span>
                  <span className="cta-stat-label">Yrs Exp.</span>
                </div>
              </div>
            </div>
          </aside>
        </div>
      </div>

      {/* Contact Modal */}
      {showContact && (
        <div className="modal-overlay" onClick={() => setShowContact(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Contact {name}</h3>
              <button className="modal-close-btn" onClick={() => setShowContact(false)}><FiX size={18} /></button>
            </div>

            {isAuthenticated ? (
              <div className="contact-options">
                {phone && (
                  <a href={`tel:${phone}`} className="contact-option">
                    <div className="contact-option-icon"><FiPhone size={20} /></div>
                    <div>
                      <p className="contact-option-title">Call</p>
                      <p className="contact-option-value">{phone}</p>
                    </div>
                  </a>
                )}
                {email && (
                  <a href={`mailto:${email}`} className="contact-option">
                    <div className="contact-option-icon"><FiMail size={20} /></div>
                    <div>
                      <p className="contact-option-title">Email</p>
                      <p className="contact-option-value">{email}</p>
                    </div>
                  </a>
                )}
                <div className="contact-option">
                  <div className="contact-option-icon" style={{background:'#eef2ff',color:'var(--primary)'}}><FiMessageSquare size={20} /></div>
                  <div>
                    <p className="contact-option-title">Request a Quote</p>
                    <p className="contact-option-value">Get a custom estimate</p>
                  </div>
                </div>
              </div>
            ) : (
              <div className="contact-login-prompt">
                <p>Please log in to contact this professional.</p>
                <Link to="/login" className="btn btn-primary" style={{justifyContent:'center'}}>
                  Log In to Contact
                </Link>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

export default ProfessionalProfile;
