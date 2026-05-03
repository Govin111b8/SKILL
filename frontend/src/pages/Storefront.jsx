import { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import {
  FiMapPin, FiClock, FiDollarSign, FiPhone, FiMail, FiMessageSquare,
  FiStar, FiCheck, FiShare2, FiHeart, FiArrowLeft, FiGlobe, FiInstagram,
  FiCalendar, FiAward, FiZap, FiShield,
} from 'react-icons/fi';
import { get, post } from '../api/client';
import { useAuth } from '../context/AuthContext';
import StarRating from '../components/StarRating';
import ReviewCard from '../components/ReviewCard';
import LoadingSpinner from '../components/LoadingSpinner';
import './Storefront.css';

function Storefront() {
  const { id } = useParams();
  const { isAuthenticated } = useAuth();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('portfolio');
  const [saved, setSaved] = useState(false);

  useEffect(() => { fetchStorefront(); }, [id]);

  useEffect(() => {
    if (isAuthenticated) {
      get(`/favorites/check/${id}`).then(res => setSaved(res.favorited || false)).catch(() => {});
    }
  }, [id, isAuthenticated]);

  async function fetchStorefront() {
    try {
      const res = await get(`/storefront/${id}`);
      setData(res.data || res);
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

  return (
    <div className="storefront">
      {/* Hero Banner */}
      <div className="storefront-hero" style={{ backgroundImage: data.cover_image_url ? `url(${data.cover_image_url})` : undefined }}>
        <div className="storefront-hero-overlay">
          <div className="storefront-hero-content">
            <div className="storefront-avatar">
              {data.avatar_url
                ? <img src={data.avatar_url} alt={data.name} />
                : <span>{data.name?.[0]?.toUpperCase()}</span>
              }
            </div>
            <h1>{data.name} {data.government_id_verified && <FiShield className="verified-icon" />}</h1>
            {data.headline && <p className="storefront-headline">{data.headline}</p>}
            <div className="storefront-hero-meta">
              {data.show_rating !== false && (
                <span className="storefront-rating">
                  <FiStar /> {parseFloat(data.average_rating).toFixed(1)} ({data.review_count})
                </span>
              )}
              {data.location && <span><FiMapPin /> {data.location}</span>}
            </div>
          </div>
        </div>
        <div className="storefront-hero-actions">
          <button onClick={handleShare} title="Share"><FiShare2 /></button>
          <button onClick={toggleFavorite} title="Save" className={saved ? 'active' : ''}><FiHeart /></button>
        </div>
      </div>

      {/* Announcement */}
      {data.announcement && (
        <div className="storefront-announcement">
          <FiZap /> <span>{data.announcement}</span>
        </div>
      )}

      {/* Trust Badges */}
      <div className="storefront-badges">
        {data.government_id_verified && <span className="badge badge-verified"><FiShield /> Verified</span>}
        {data.response_time_hours && data.response_time_hours < 2 && <span className="badge badge-fast"><FiZap /> Fast Response</span>}
        {parseFloat(data.average_rating) >= 4.5 && <span className="badge badge-top"><FiStar /> Top Rated</span>}
        {data.completed_jobs >= 50 && <span className="badge badge-jobs"><FiAward /> {data.completed_jobs}+ Jobs</span>}
      </div>

      {/* Tabs */}
      <div className="storefront-tabs">
        {['portfolio', 'reviews', 'info', 'contact'].map(tab => (
          <button
            key={tab}
            className={activeTab === tab ? 'active' : ''}
            onClick={() => setActiveTab(tab)}
          >
            {tab.charAt(0).toUpperCase() + tab.slice(1)}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      <div className="storefront-content">
        {activeTab === 'portfolio' && (
          <div className="storefront-portfolio">
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
              <p className="empty-state">No portfolio items yet.</p>
            )}
          </div>
        )}

        {activeTab === 'reviews' && (
          <div className="storefront-reviews">
            <div className="reviews-summary">
              <div className="reviews-avg">
                <span className="avg-number">{parseFloat(data.average_rating).toFixed(1)}</span>
                <StarRating rating={parseFloat(data.average_rating)} />
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
            {/* About */}
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
                  <span className={`status-${data.availability_status}`}>{data.availability_status}</span>
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
          </div>
        )}

        {activeTab === 'contact' && (
          <div className="storefront-contact">
            <h3>Get in Touch</h3>
            <div className="contact-buttons">
              {data.whatsapp_number && (
                <a href={`https://wa.me/${data.whatsapp_number}`} target="_blank" rel="noopener noreferrer" className="contact-btn whatsapp">
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
    </div>
  );
}

export default Storefront;
