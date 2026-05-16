import { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import {
  FiMapPin, FiClock, FiDollarSign, FiPhone, FiMail, FiMessageSquare,
  FiStar, FiCheck, FiShare2, FiHeart, FiArrowLeft, FiGlobe, FiInstagram,
  FiCalendar, FiAward, FiZap, FiShield, FiUsers, FiPlay, FiChevronRight,
  FiInfo, FiBookmark,
} from 'react-icons/fi';
import { get, post, del } from '../api/client';
import { useAuth } from '../context/AuthContext';
import StarRating from '../components/StarRating';
import ReviewCard from '../components/ReviewCard';
import LoadingSpinner from '../components/LoadingSpinner';
import TrustTimeline from '../components/TrustTimeline';
import SaveToCollectionModal from '../components/SaveToCollectionModal';
import './Storefront.css';

// Human-friendly availability labels
const AVAILABILITY_LABELS = {
  available: { label: 'Available Now', class: 'avail-now', icon: '🟢' },
  busy: { label: 'Currently Busy', class: 'avail-busy', icon: '🟡' },
  offline: { label: 'Offline', class: 'avail-offline', icon: '⚫' },
};

// Badge display config
const BADGE_CONFIG = {
  rising_pro: { emoji: '🌱', label: 'Rising Pro', bg: '#dcfce7', color: '#166534' },
  fast_responder: { emoji: '⚡', label: 'Fast Responder', bg: '#fff7ed', color: '#9a3412' },
  customer_favorite: { emoji: '⭐', label: 'Customer Favorite', bg: '#fef9c3', color: '#854d0e' },
  top_rated: { emoji: '🏆', label: 'Top Rated', bg: '#fef3c7', color: '#92400e' },
  elite_professional: { emoji: '💎', label: 'Elite Pro', bg: '#e0e7ff', color: '#3730a3' },
};

function Storefront() {
  const { id } = useParams();
  const { isAuthenticated, user } = useAuth();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('portfolio');
  const [saved, setSaved] = useState(false);
  const [following, setFollowing] = useState(false);
  const [trustData, setTrustData] = useState(null);
  const [showTrustModal, setShowTrustModal] = useState(false);
  const [showSaveModal, setShowSaveModal] = useState(false);
  const [proServices, setProServices] = useState([]);

  useEffect(() => { fetchStorefront(); }, [id]);

  useEffect(() => {
    if (isAuthenticated) {
      get(`/favorites/check/${id}`).then(res => setSaved(res.favorited || false)).catch((err) => console.error('Favorites check failed:', err.message));
      get(`/social/check/${id}`).then(res => setFollowing(res.following || false)).catch((err) => console.error('Follow check failed:', err.message));
    }
  }, [id, isAuthenticated]);

  async function fetchStorefront() {
    try {
      const res = await get(`/storefront/${id}`);
      setData(res.data || res);
      // Fetch professional services
      try {
        const svcRes = await get(`/services/${id}`);
        setProServices((svcRes.data || svcRes) || []);
      } catch {}
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }

  async function toggleFavorite() {
    if (!isAuthenticated) return;
    try {
      const res = await post('/favorites/toggle', { professional_id: id });
      setSaved(res.favorited);
    } catch {}
  }

  async function toggleFollow() {
    if (!isAuthenticated) return;
    try {
      if (following) {
        await del(`/social/unfollow/${id}`);
        setFollowing(false);
      } else {
        await post(`/social/follow/${id}`);
        setFollowing(true);
      }
    } catch {}
  }

  async function loadTrustExplanation() {
    try {
      const res = await get(`/trust/${id}/explain`);
      setTrustData(res.data || res);
      setShowTrustModal(true);
    } catch {}
  }

  function handleShare() {
    if (navigator.share) {
      navigator.share({ title: data?.name, url: window.location.href });
    } else {
      navigator.clipboard.writeText(window.location.href);
    }
  }

  if (loading) return <LoadingSpinner />;
  if (!data) return <div className="storefront-error">Professional not found.</div>;

  const dist = data.rating_distribution || {};
  const totalReviews = Object.values(dist).reduce((a, b) => a + b, 0);
  const avgRating = parseFloat(data.average_rating || 0);
  const avail = AVAILABILITY_LABELS[data.availability_status] || AVAILABILITY_LABELS.offline;
  const theme = data.theme || {};
  const badges = data.badges || [];
  const packages = data.packages || [];
  const media = data.media || [];
  const reels = media.filter(m => m.type === 'reel');
  const highlights = media.filter(m => m.type === 'highlight');
  const beforeAfters = media.filter(m => m.type === 'before_after');

  // Dynamic theme colors
  const themeStyle = {
    '--sf-primary': theme.primary_color || '#6366f1',
    '--sf-accent': theme.accent_color || '#8b5cf6',
  };

  return (
    <div className="storefront" style={themeStyle}>
      {/* ── Cinematic Hero Banner ── */}
      <div
        className="storefront-hero storefront-hero--cinematic"
        style={{ backgroundImage: data.cover_image_url ? `url(${data.cover_image_url})` : undefined }}
      >
        {/* Intro video (muted autoplay) */}
        {data.intro_video_url && (
          <video
            className="storefront-hero-video"
            src={data.intro_video_url}
            autoPlay muted loop playsInline
            aria-label={`Introduction video for ${data.name}`}
          />
        )}

        <div className="storefront-hero-overlay storefront-hero-overlay--cinematic">
          <div className="storefront-hero-content">
            <div className="storefront-avatar storefront-avatar--lg">
              {data.avatar_url
                ? <img src={data.avatar_url} alt={data.name} />
                : <span>{data.name?.[0]?.toUpperCase()}</span>
              }
              {data.government_id_verified && (
                <span className="verified-badge-animated" title="Verified Professional">
                  <FiShield />
                </span>
              )}
            </div>
            <h1 className="storefront-name">{data.name}</h1>
            {(data.tagline || data.headline) && (
              <p className="storefront-tagline">{data.tagline || data.headline}</p>
            )}

            {/* Trust indicators above the fold */}
            <div className="storefront-trust-row">
              {data.show_rating !== false && avgRating > 0 && (
                <span className="trust-chip">
                  <FiStar /> {avgRating.toFixed(1)} ({data.review_count})
                </span>
              )}
              {data.completed_jobs > 0 && (
                <span className="trust-chip">
                  <FiCheck /> {data.completed_jobs} jobs
                </span>
              )}
              {data.response_time_hours && data.response_time_hours < 4 && (
                <span className="trust-chip">
                  <FiZap /> {data.response_time_hours < 1
                    ? `${Math.round(data.response_time_hours * 60)}min`
                    : `${Math.round(data.response_time_hours)}hr`
                  } response
                </span>
              )}
              {data.repeat_customer_rate > 0 && (
                <span className="trust-chip">
                  <FiUsers /> {Math.round(data.repeat_customer_rate)}% repeat
                </span>
              )}
              {data.location && (
                <span className="trust-chip">
                  <FiMapPin /> {data.location}
                </span>
              )}
            </div>
          </div>
        </div>

        {/* Hero actions */}
        <div className="storefront-hero-actions">
          <button onClick={handleShare} title="Share"><FiShare2 /></button>
          <button onClick={toggleFavorite} title="Save" className={saved ? 'active' : ''}><FiHeart /></button>
          {isAuthenticated && (
            <button onClick={() => setShowSaveModal(true)} title="Save to Collection" className="save-collection-btn">
              <FiBookmark />
            </button>
          )}
        </div>

        {/* Availability indicator */}
        <div className={`storefront-availability ${avail.class}`}>
          <span>{avail.icon}</span> {avail.label}
        </div>
      </div>

      {/* ── Follow + Follower Count ── */}
      <div className="storefront-social-bar">
        <div className="social-stats">
          {data.follower_count > 0 && (
            <span className="follower-count">
              <FiUsers size={14} /> {data.follower_count} followers
            </span>
          )}
          {data.categories?.length > 0 && (
            <span className="category-chips">
              {data.categories.map(c => (
                <Link key={c.id} to={`/categories/${c.id}`} className="cat-chip">{c.name}</Link>
              ))}
            </span>
          )}
        </div>
        <div className="social-actions">
          {isAuthenticated && user?.role !== 'professional' && (
            <button
              className={`follow-btn ${following ? 'following' : ''}`}
              onClick={toggleFollow}
              aria-label={following ? `Unfollow ${data.name}` : `Follow ${data.name}`}
            >
              {following ? '✓ Following' : '+ Follow'}
            </button>
          )}
          <button className="trust-explain-btn" onClick={loadTrustExplanation} title="Why is this pro trusted?">
            <FiInfo size={14} /> Trust Info
          </button>
        </div>
      </div>

      {/* ── Announcement ── */}
      {data.announcement && (
        <div className="storefront-announcement">
          <FiZap /> <span>{data.announcement}</span>
        </div>
      )}

      {/* ── Earned Badges ── */}
      <div className="storefront-badges">
        {data.government_id_verified && <span className="badge badge-verified"><FiShield /> Verified</span>}
        {badges.map(b => {
          const cfg = BADGE_CONFIG[b.badge_type];
          if (!cfg) return null;
          return (
            <span key={b.badge_type} className="badge badge-earned" style={{ background: cfg.bg, color: cfg.color }}>
              {cfg.emoji} {cfg.label}
            </span>
          );
        })}
        {data.response_time_hours && data.response_time_hours < 2 && !badges.find(b => b.badge_type === 'fast_responder') && (
          <span className="badge badge-fast"><FiZap /> Fast Response</span>
        )}
        {avgRating >= 4.5 && !badges.find(b => b.badge_type === 'top_rated') && (
          <span className="badge badge-top"><FiStar /> Top Rated</span>
        )}
        {data.completed_jobs >= 50 && (
          <span className="badge badge-jobs"><FiAward /> {data.completed_jobs}+ Jobs</span>
        )}
      </div>

      {/* ── Story Highlights ── */}
      {highlights.length > 0 && (
        <div className="storefront-highlights">
          {highlights.map(h => (
            <div key={h.id} className="highlight-bubble">
              <img src={h.thumbnail_url || h.media_url} alt={h.caption || 'Highlight'} />
              {h.caption && <span className="highlight-label">{h.caption}</span>}
            </div>
          ))}
        </div>
      )}

      {/* Company-Specific Sections */}
      {data.provider_type === 'organization' && (
        <div className="storefront-company-info" style={{ background: 'var(--gray-50, #f8fafc)', padding: '1.5rem', borderRadius: '12px', margin: '1rem 0' }}>
          <h3 style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '1rem' }}>
            🏢 Company Information
          </h3>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1rem' }}>
            {data.company_name && (
              <div style={{ padding: '1rem', background: '#fff', borderRadius: '10px', border: '1px solid var(--gray-200)' }}>
                <div style={{ fontSize: '0.75rem', color: 'var(--gray-500)', marginBottom: '4px' }}>Company Name</div>
                <div style={{ fontWeight: 600 }}>{data.company_name}</div>
              </div>
            )}
            {data.team_size && (
              <div style={{ padding: '1rem', background: '#fff', borderRadius: '10px', border: '1px solid var(--gray-200)' }}>
                <div style={{ fontSize: '0.75rem', color: 'var(--gray-500)', marginBottom: '4px' }}>Team Size</div>
                <div style={{ fontWeight: 600, display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <FiUsers size={16} /> {data.team_size} members
                </div>
              </div>
            )}
            {data.company_registration_number && (
              <div style={{ padding: '1rem', background: '#fff', borderRadius: '10px', border: '1px solid var(--gray-200)' }}>
                <div style={{ fontSize: '0.75rem', color: 'var(--gray-500)', marginBottom: '4px' }}>Registration #</div>
                <div style={{ fontWeight: 600, display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <FiShield size={16} /> {data.company_registration_number}
                </div>
              </div>
            )}
            <div style={{ padding: '1rem', background: '#fff', borderRadius: '10px', border: '1px solid var(--gray-200)' }}>
              <div style={{ fontSize: '0.75rem', color: 'var(--gray-500)', marginBottom: '4px' }}>Provider Type</div>
              <div style={{ fontWeight: 600, display: 'flex', alignItems: 'center', gap: '6px' }}>
                🏢 Verified Company
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ── Tabs ── */}
      <div className="storefront-tabs">
        {['portfolio', 'services', 'reviews', 'info', 'contact'].map(tab => (
          <button
            key={tab}
            className={activeTab === tab ? 'active' : ''}
            onClick={() => setActiveTab(tab)}
          >
            {tab === 'services' ? 'Services' : tab.charAt(0).toUpperCase() + tab.slice(1)}
          </button>
        ))}
      </div>

      {/* ── Tab Content ── */}
      <div className="storefront-content">
        {activeTab === 'portfolio' && (
          <div className="storefront-portfolio">
            {/* Before/After Section */}
            {beforeAfters.length > 0 && (
              <div className="portfolio-section">
                <h3>Before & After</h3>
                <div className="before-after-grid">
                  {beforeAfters.map(item => (
                    <div key={item.id} className="before-after-card">
                      <div className="ba-images">
                        <div className="ba-side">
                          <img src={item.before_url || item.media_url} alt="Before" />
                          <span className="ba-label">Before</span>
                        </div>
                        <div className="ba-side">
                          <img src={item.media_url} alt="After" />
                          <span className="ba-label ba-label--after">After</span>
                        </div>
                      </div>
                      {item.caption && <p className="ba-caption">{item.caption}</p>}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Reels Section */}
            {reels.length > 0 && (
              <div className="portfolio-section">
                <h3><FiPlay size={16} /> Reels</h3>
                <div className="reels-grid">
                  {reels.map(reel => (
                    <div key={reel.id} className="reel-card">
                      <video src={reel.media_url} poster={reel.thumbnail_url} preload="metadata" />
                      <div className="reel-overlay">
                        <FiPlay size={24} />
                      </div>
                      {reel.caption && <p className="reel-caption">{reel.caption}</p>}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Standard Portfolio */}
            {data.portfolio?.length > 0 ? (
              <div className="portfolio-grid">
                {data.portfolio.map(item => (
                  <div key={item.id} className="portfolio-item">
                    {item.media_url && <img src={item.media_url} alt={item.title} />}
                    <div className="portfolio-item-info">
                      <h4>{item.title}</h4>
                      {item.description && <p>{item.description}</p>}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              media.length === 0 && <p className="empty-state">No portfolio items yet.</p>
            )}
          </div>
        )}

        {activeTab === 'services' && (
          <div className="storefront-services">
            {/* Custom Intro */}
            {(theme.custom_intro || data.bio) && (
              <div className="services-intro">
                <h3>About My Business</h3>
                <p>{theme.custom_intro || data.bio}</p>
              </div>
            )}

            {/* Individual Services Catalog */}
            {proServices.length > 0 && (
              <div className="services-catalog" style={{ marginBottom: '2rem' }}>
                <h3 style={{ marginBottom: '1rem', fontSize: '1.1rem' }}>Services Offered</h3>
                <div className="services-grid" style={{ display: 'grid', gap: '1rem', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))' }}>
                  {proServices.map(svc => (
                    <div key={svc.id} className="service-catalog-card" style={{ background: 'var(--sf-card-bg, #fff)', border: '1px solid var(--border-light, #e5e7eb)', borderRadius: '12px', padding: '1.25rem' }}>
                      <h4 style={{ margin: '0 0 0.25rem', fontSize: '1rem' }}>{svc.name}</h4>
                      {svc.description && <p style={{ margin: '0 0 0.75rem', fontSize: '0.85rem', color: 'var(--text-secondary, #666)' }}>{svc.description}</p>}
                      <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', fontSize: '0.875rem', marginBottom: '0.75rem' }}>
                        {(svc.price_min || svc.price_max) && (
                          <span style={{ fontWeight: 600, color: 'var(--sf-primary, #6366f1)' }}>
                            ₹{svc.price_min ? Number(svc.price_min).toLocaleString() : '—'} – ₹{svc.price_max ? Number(svc.price_max).toLocaleString() : '—'}
                          </span>
                        )}
                        {svc.duration_minutes && (
                          <span style={{ color: 'var(--text-secondary, #888)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                            <FiClock size={13} /> {svc.duration_minutes} min
                          </span>
                        )}
                      </div>
                      {svc.category_name && (
                        <span style={{ display: 'inline-block', fontSize: '0.75rem', background: 'var(--sf-accent-light, #eef2ff)', color: 'var(--sf-primary, #6366f1)', padding: '2px 8px', borderRadius: '12px', marginBottom: '0.75rem' }}>{svc.category_name}</span>
                      )}
                      <Link
                        to={`/bookings/create?professional_id=${id}&professional_name=${encodeURIComponent(data.name)}&service=${encodeURIComponent(svc.name)}&service_id=${svc.id}`}
                        className="package-book-btn"
                        style={{ display: 'block', textAlign: 'center', marginTop: '0.5rem' }}
                      >
                        Book This Service <FiChevronRight size={14} />
                      </Link>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Service Packages */}
            {packages.length > 0 ? (
              <div className="packages-grid">
                {packages.map(pkg => (
                  <div key={pkg.id} className={`package-card ${pkg.is_popular ? 'package-popular' : ''}`}>
                    {pkg.is_popular && <span className="popular-badge">Most Popular</span>}
                    <h4>{pkg.name}</h4>
                    <span className="package-tier">{pkg.tier}</span>
                    {pkg.price != null && (
                      <div className="package-price">₹{Number(pkg.price).toLocaleString()}</div>
                    )}
                    {pkg.description && <p className="package-desc">{pkg.description}</p>}
                    {pkg.features?.length > 0 && (
                      <ul className="package-features">
                        {pkg.features.map((f, i) => (
                          <li key={i}><FiCheck size={14} /> {f}</li>
                        ))}
                      </ul>
                    )}
                    <Link
                      to={`/bookings/create?professional_id=${id}&professional_name=${encodeURIComponent(data.name)}`}
                      className="package-book-btn"
                    >
                      Book This Package <FiChevronRight size={14} />
                    </Link>
                  </div>
                ))}
              </div>
            ) : (
              <div className="services-list">
                {data.categories?.length > 0 ? (
                  data.categories.map(c => (
                    <div key={c.id} className="service-item">
                      <span>{c.name}</span>
                      {data.pricing_estimate && <span className="service-price">{data.pricing_estimate}</span>}
                    </div>
                  ))
                ) : (
                  <p className="empty-state">No services listed yet.</p>
                )}
              </div>
            )}
          </div>
        )}

        {activeTab === 'reviews' && (
          <div className="storefront-reviews">
            <div className="reviews-summary">
              <div className="reviews-avg">
                <span className="avg-number">{avgRating.toFixed(1)}</span>
                <StarRating rating={avgRating} />
                <span className="review-count">{data.review_count} reviews</span>
              </div>
              <div className="rating-bars">
                {[5, 4, 3, 2, 1].map(star => (
                  <div key={star} className="rating-bar-row">
                    <span>{star} <FiStar size={12} /></span>
                    <div className="rating-bar">
                      <div className="rating-bar-fill" style={{ width: `${totalReviews > 0 ? ((dist[star] || 0) / totalReviews) * 100 : 0}%` }} />
                    </div>
                    <span className="rating-count">{dist[star] || 0}</span>
                  </div>
                ))}
              </div>
            </div>
            <div className="reviews-list">
              {data.reviews?.length > 0
                ? data.reviews.map(r => <ReviewCard key={r.id} review={r} />)
                : <p className="empty-state">No reviews yet.</p>
              }
            </div>
          </div>
        )}

        {activeTab === 'info' && (
          <div className="storefront-info">
            {data.bio && (
              <div className="info-section">
                <h3>About</h3>
                <p>{data.bio}</p>
              </div>
            )}
            <div className="info-grid">
              <div className="info-item">
                <FiClock />
                <div>
                  <strong>Availability</strong>
                  <span className={`status-${data.availability_status}`}>{avail.label}</span>
                </div>
              </div>
              {data.operating_hours && (
                <div className="info-item"><FiClock /><div><strong>Hours</strong><span>{data.operating_hours}</span></div></div>
              )}
              {data.operating_days && (
                <div className="info-item"><FiCalendar /><div><strong>Days</strong><span>{data.operating_days}</span></div></div>
              )}
              {data.years_of_experience && (
                <div className="info-item"><FiAward /><div><strong>Experience</strong><span>{data.years_of_experience} years</span></div></div>
              )}
              {data.pricing_estimate && (
                <div className="info-item"><FiDollarSign /><div><strong>Pricing</strong><span>{data.pricing_estimate}</span></div></div>
              )}
            </div>
            {data.return_policy && (
              <div className="info-section">
                <h3>Service Guarantee</h3>
                <p>{data.return_policy}</p>
              </div>
            )}
            <TrustTimeline professionalId={id} />
          </div>
        )}

        {activeTab === 'contact' && (
          <div className="storefront-contact">
            <h3>Get in Touch</h3>
            <div className="contact-buttons">
              {data.whatsapp_number && (
                <a href={`https://wa.me/${data.whatsapp_number}?text=${encodeURIComponent(`Hi ${data.name}, I found you on SkillConnect and would like to inquire about your services.`)}`} target="_blank" rel="noopener noreferrer" className="contact-btn whatsapp">
                  <FiMessageSquare /> WhatsApp
                </a>
              )}
              {data.email && (
                <a href={`mailto:${data.email}`} className="contact-btn email">
                  <FiMail /> Email
                </a>
              )}
              {data.instagram_handle && (
                <a href={`https://instagram.com/${data.instagram_handle}`} target="_blank" rel="noopener noreferrer" className="contact-btn instagram">
                  <FiInstagram /> Instagram
                </a>
              )}
              {data.website_url && (
                <a href={data.website_url} target="_blank" rel="noopener noreferrer" className="contact-btn website">
                  <FiGlobe /> Website
                </a>
              )}
            </div>
            {isAuthenticated && (
              <Link to="/messages" className="contact-btn message-btn">
                <FiMessageSquare /> Send Message
              </Link>
            )}
          </div>
        )}
      </div>

      {/* ── Sticky Book Now CTA ── */}
      <div className="storefront-sticky-cta">
        <div className="sticky-cta-info">
          <span className="sticky-cta-name">{data.name}</span>
          {avgRating > 0 && <span className="sticky-cta-rating"><FiStar size={12} /> {avgRating.toFixed(1)}</span>}
        </div>
        <Link
          to={`/bookings/create?professional_id=${id}&professional_name=${encodeURIComponent(data.name)}`}
          className="sticky-cta-btn"
        >
          Book Now
        </Link>
      </div>

      {/* ── Trust Explainer Modal ── */}
      {showTrustModal && trustData && (
        <div className="trust-modal-overlay" onClick={() => setShowTrustModal(false)}>
          <div className="trust-modal" onClick={e => e.stopPropagation()}>
            <h3>🛡️ Why {data.name} is Trusted</h3>
            <p className="trust-summary">{trustData.summary}</p>
            <div className="trust-signals">
              {trustData.signals?.map((s, i) => (
                <div key={i} className={`trust-signal trust-signal--${s.strength}`}>
                  <span className="signal-icon">{s.icon}</span>
                  <span className="signal-label">{s.label}</span>
                  <span className={`signal-strength strength-${s.strength}`}>{s.strength}</span>
                </div>
              ))}
            </div>
            <button className="trust-modal-close" onClick={() => setShowTrustModal(false)}>Close</button>
          </div>
        </div>
      )}

      {showSaveModal && (
        <SaveToCollectionModal
          itemType="professional"
          itemId={id}
          onClose={() => setShowSaveModal(false)}
        />
      )}
    </div>
  );
}

export default Storefront;
