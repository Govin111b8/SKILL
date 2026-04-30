import { useState, useEffect, useRef } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import {
  FiMapPin, FiClock, FiDollarSign, FiPhone, FiMail, FiMessageSquare,
  FiStar, FiCheck, FiShare2, FiHeart, FiArrowLeft, FiX, FiSend, FiCalendar,
} from 'react-icons/fi';
import { get, post } from '../api/client';
import { useAuth } from '../context/AuthContext';
import OnlineIndicator from '../components/OnlineIndicator';
import StarRating from '../components/StarRating';
import ReviewCard from '../components/ReviewCard';
import LoadingSpinner from '../components/LoadingSpinner';
import './ProfessionalProfile.css';

function ProfessionalProfile() {
  const { id } = useParams();
  const navigate = useNavigate();
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
      const res = await get(`/professionals/${id}`);
      const raw = res.data || res;

      // Fetch portfolio and reviews in parallel
      const [portfolioRes, reviewsRes] = await Promise.all([
        get(`/portfolio/${id}`).catch(() => ({ data: [] })),
        get(`/reviews/${id}`).catch(() => ({ data: [] })),
      ]);

      const p = {
        ...raw,
        rating: raw.average_rating ?? raw.rating ?? 0,
        reviews_count: parseInt(raw.review_count || raw.reviews_count || 0),
        available: raw.availability_status === 'available',
        pricing: raw.pricing_estimate || raw.pricing,
        verified: raw.reputation_score >= 4,
        categories: raw.categories?.map(c => typeof c === 'string' ? c : c.name) || [],
        portfolio: portfolioRes.data || portfolioRes || [],
        reviews: reviewsRes.data || reviewsRes || [],
      };
      setProfessional(p);
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
                  <h1>{name} <OnlineIndicator userId={id} size={12} style={{ marginLeft: 8, verticalAlign: 'middle' }} /></h1>
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
              <button
                className="btn btn-primary btn-lg profile-contact-btn"
                onClick={() => navigate(`/bookings/create?professional_id=${id}&professional_name=${encodeURIComponent(name)}`)}
              >
                <FiCalendar size={18} /> Book Now
              </button>
              <button
                className="btn btn-outline btn-lg profile-contact-btn"
                style={{ marginTop: '0.5rem' }}
                onClick={async () => {
                  if (!isAuthenticated) { navigate('/login'); return; }
                  try {
                    const res = await post('/messages/threads', { professional_id: id });
                    const thread = res.data || res;
                    navigate(`/messages/${thread.id}`);
                  } catch {
                    navigate('/messages');
                  }
                }}
              >
                <FiMessageSquare size={18} /> Message
              </button>
              <button className="btn btn-secondary btn-lg profile-contact-btn" style={{ marginTop: '0.5rem' }} onClick={() => setShowContact(true)}>
                <FiPhone size={18} /> Contact Info
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
                        <div key={item.id || i} className="portfolio-item">
                          <img src={item.media_url || item.image || item} alt={item.title || `Work ${i + 1}`}
                            onError={(e) => { e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(item.title || 'P')}&background=eef2ff&color=6366f1&size=200`; }} />
                          {item.title && <div className="portfolio-item-label">{item.title}</div>}
                          {item.description && <p className="portfolio-item-desc">{item.description}</p>}
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
        <ContactModal
          professional={professional}
          isAuthenticated={isAuthenticated}
          onClose={() => setShowContact(false)}
        />
      )}
    </div>
  );
}

function ContactModal({ professional, isAuthenticated, onClose }) {
  const { name, phone, email, id } = professional;
  const [tab, setTab] = useState('contact');
  const [quoteMsg, setQuoteMsg] = useState('');
  const [sent, setSent] = useState(false);
  const [sending, setSending] = useState(false);

  const whatsappUrl = phone
    ? `https://wa.me/${phone.replace(/[^0-9+]/g, '')}?text=${encodeURIComponent(`Hi ${name}, I found you on SkillConnect and I'm interested in your services.`)}`
    : null;

  async function handleQuoteRequest(e) {
    e.preventDefault();
    setSending(true);
    try {
      await post('/contacts', {
        professional_id: id,
        contact_type: 'quote_request',
        message: quoteMsg,
      });
      setSent(true);
    } catch {
      // ignore
    }
    setSending(false);
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={e => e.stopPropagation()}>
        <div className="modal-header">
          <h3>Contact {name}</h3>
          <button className="modal-close-btn" onClick={onClose}><FiX size={18} /></button>
        </div>

        {!isAuthenticated ? (
          <div className="contact-login-prompt">
            <p>Please log in to contact this professional.</p>
            <Link to="/login" className="btn btn-primary" style={{justifyContent:'center'}}>
              Log In to Contact
            </Link>
          </div>
        ) : sent ? (
          <div className="contact-sent">
            <FiCheck size={48} color="#10b981" />
            <h4>Quote Request Sent!</h4>
            <p>{name} will receive your message and respond shortly.</p>
            <button className="btn btn-primary" onClick={onClose}>Done</button>
          </div>
        ) : (
          <>
            <div className="contact-tabs">
              <button className={`contact-tab ${tab === 'contact' ? 'active' : ''}`} onClick={() => setTab('contact')}>
                <FiPhone size={14} /> Contact Info
              </button>
              <button className={`contact-tab ${tab === 'quote' ? 'active' : ''}`} onClick={() => setTab('quote')}>
                <FiSend size={14} /> Request Quote
              </button>
            </div>

            {tab === 'contact' && (
              <div className="contact-options">
                {phone && (
                  <a href={`tel:${phone}`} className="contact-option">
                    <div className="contact-option-icon"><FiPhone size={20} /></div>
                    <div>
                      <p className="contact-option-title">Call Directly</p>
                      <p className="contact-option-value">{phone}</p>
                    </div>
                  </a>
                )}
                {whatsappUrl && (
                  <a href={whatsappUrl} target="_blank" rel="noopener noreferrer" className="contact-option contact-option--whatsapp">
                    <div className="contact-option-icon" style={{background:'#dcfce7', color:'#16a34a'}}>
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/></svg>
                    </div>
                    <div>
                      <p className="contact-option-title">WhatsApp</p>
                      <p className="contact-option-value">Chat on WhatsApp</p>
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
              </div>
            )}

            {tab === 'quote' && (
              <form onSubmit={handleQuoteRequest} className="quote-form">
                <p className="quote-desc">Describe what you need and get a custom quote from {name?.split(' ')[0]}.</p>
                <textarea
                  value={quoteMsg}
                  onChange={e => setQuoteMsg(e.target.value)}
                  placeholder="Hi, I need help with..."
                  rows={4}
                  required
                  minLength={10}
                />
                <button type="submit" className="btn btn-primary" disabled={sending} style={{width:'100%', justifyContent:'center'}}>
                  <FiSend size={14} /> {sending ? 'Sending...' : 'Send Quote Request'}
                </button>
              </form>
            )}
          </>
        )}
      </div>
    </div>
  );
}

export default ProfessionalProfile;
