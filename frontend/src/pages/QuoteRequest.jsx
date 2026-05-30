import { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  FiUpload, FiSend, FiClock, FiDollarSign, FiMapPin, FiCamera,
  FiCheckCircle, FiAlertCircle, FiUser, FiStar, FiArrowLeft,
} from 'react-icons/fi';
import { get, post } from '../api/client';
import { useAuth } from '../context/AuthContext';
import SEOMeta from '../components/SEOMeta';
import LoadingSpinner from '../components/LoadingSpinner';
import './QuoteRequest.css';

const PREFERRED_TIMES = [
  { value: 'morning', label: '🌅 Morning (8am–12pm)' },
  { value: 'afternoon', label: '☀️ Afternoon (12pm–5pm)' },
  { value: 'evening', label: '🌆 Evening (5pm–8pm)' },
  { value: 'anytime', label: '🕐 Anytime' },
];

const BID_STATUS_LABELS = {
  submitted: { label: 'Awaiting Response', color: '#f59e0b' },
  shortlisted: { label: 'Shortlisted', color: '#3b82f6' },
  accepted: { label: 'Accepted', color: '#10b981' },
  rejected: { label: 'Not Selected', color: '#9ca3af' },
};

function getBidBadge(bids, bid) {
  if (!bids || bids.length < 2) return null;
  const prices = bids
    .map((b) => parseFloat(b.price || b.quoted_amount || b.amount || 0))
    .filter((p) => p > 0);
  const minPrice = Math.min(...prices);
  const maxRating = Math.max(...bids.map((b) => parseFloat(b.professional_rating || b.avg_rating || 0)));
  const minResponseTime = Math.min(...bids.map((b) => parseFloat(b.response_time_hours || 999)));

  const myPrice = parseFloat(bid.price || bid.quoted_amount || bid.amount || 0);
  const myRating = parseFloat(bid.professional_rating || bid.avg_rating || 0);
  const myResponseTime = parseFloat(bid.response_time_hours || 999);

  if (myPrice === minPrice && prices.length > 0) return { label: '💰 Best Value', color: '#10b981' };
  if (myRating === maxRating && myRating >= 4.5) return { label: '⭐ Most Trusted', color: '#3b82f6' };
  if (myResponseTime === minResponseTime && myResponseTime < 999) return { label: '⚡ Fastest Reply', color: '#f59e0b' };
  return null;
}

// ── Quote Submission Form ─────────────────────────────────────────────────────

function SubmitQuoteForm({ categories, onSubmit, loading }) {
  const [form, setForm] = useState({
    category_id: '',
    title: '',
    description: '',
    area_sqft: '',
    budget_min: '',
    budget_max: '',
    location_text: '',
    pincode: '',
    preferred_date: '',
    preferred_time: 'anytime',
  });

  const set = (k, v) => setForm((f) => ({ ...f, [k]: v }));

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit({
      ...form,
      category_id: parseInt(form.category_id),
      area_sqft: form.area_sqft ? parseFloat(form.area_sqft) : undefined,
      budget_min: form.budget_min ? parseFloat(form.budget_min) : undefined,
      budget_max: form.budget_max ? parseFloat(form.budget_max) : undefined,
    });
  };

  // Filter to quote_request mode categories only
  const quoteCategories = categories.filter((c) => c.service_mode === 'quote_request');

  return (
    <form className="qr-form" onSubmit={handleSubmit}>
      <div className="qr-form-group">
        <label>Service Category *</label>
        <select value={form.category_id} onChange={(e) => set('category_id', e.target.value)} required>
          <option value="">Select a service category</option>
          {quoteCategories.map((c) => (
            <option key={c.id} value={c.id}>{c.name}</option>
          ))}
        </select>
      </div>

      <div className="qr-form-group">
        <label>Brief Title *</label>
        <input
          type="text"
          placeholder="e.g. Paint 3BHK apartment in Koramangala"
          value={form.title}
          onChange={(e) => set('title', e.target.value)}
          required maxLength={300}
        />
      </div>

      <div className="qr-form-group">
        <label>Describe Your Requirement *</label>
        <textarea
          placeholder="Include details like: rooms, current condition, specific needs, urgency..."
          value={form.description}
          onChange={(e) => set('description', e.target.value)}
          required rows={4}
        />
      </div>

      <div className="qr-form-row">
        <div className="qr-form-group">
          <label>Area (sq ft)</label>
          <input
            type="number" min="0" step="1"
            placeholder="e.g. 1200"
            value={form.area_sqft}
            onChange={(e) => set('area_sqft', e.target.value)}
          />
        </div>
        <div className="qr-form-group">
          <label>Budget Range (₹)</label>
          <div className="qr-budget-range">
            <input type="number" min="0" placeholder="Min" value={form.budget_min} onChange={(e) => set('budget_min', e.target.value)} />
            <span>–</span>
            <input type="number" min="0" placeholder="Max" value={form.budget_max} onChange={(e) => set('budget_max', e.target.value)} />
          </div>
        </div>
      </div>

      <div className="qr-form-row">
        <div className="qr-form-group">
          <label>Location / Address</label>
          <input
            type="text"
            placeholder="Your locality, city"
            value={form.location_text}
            onChange={(e) => set('location_text', e.target.value)}
          />
        </div>
        <div className="qr-form-group">
          <label>Pincode</label>
          <input
            type="text" maxLength={6} pattern="\d{6}"
            placeholder="560001"
            value={form.pincode}
            onChange={(e) => set('pincode', e.target.value)}
          />
        </div>
      </div>

      <div className="qr-form-row">
        <div className="qr-form-group">
          <label>Preferred Date</label>
          <input
            type="date"
            value={form.preferred_date}
            onChange={(e) => set('preferred_date', e.target.value)}
            min={new Date().toISOString().split('T')[0]}
          />
        </div>
        <div className="qr-form-group">
          <label>Preferred Time</label>
          <select value={form.preferred_time} onChange={(e) => set('preferred_time', e.target.value)}>
            {PREFERRED_TIMES.map((t) => <option key={t.value} value={t.value}>{t.label}</option>)}
          </select>
        </div>
      </div>

      <div className="qr-info-box">
        <FiClock size={16} />
        <span>Up to <strong>3 verified professionals</strong> will respond within <strong>24 hours</strong>. Compare bids and choose the best.</span>
      </div>

      <button type="submit" className="qr-submit-btn" disabled={loading}>
        {loading ? <LoadingSpinner size="sm" /> : <><FiSend size={16} /> Submit Quote Request</>}
      </button>
    </form>
  );
}

// ── Bid Card ─────────────────────────────────────────────────────────────────

function BidCard({ bid, allBids, isAccepted, canAccept, onAccept }) {
  const bidBadge = getBidBadge(allBids, bid);

  return (
    <div className={`bid-card ${isAccepted ? 'bid-card--accepted' : ''}`}>
      <div className="bid-card-header">
        <div className="bid-pro-info">
          <div className="bid-pro-avatar">
            {bid.profile_photo
              ? <img src={bid.profile_photo} alt={bid.pro_name} />
              : <span>{(bid.business_name || bid.pro_name || 'P')[0].toUpperCase()}</span>
            }
          </div>
          <div>
            <h4>{bid.business_name || bid.pro_name}</h4>
            <div className="bid-pro-meta">
              {bid.avg_rating && <span><FiStar size={13} /> {Number(bid.avg_rating).toFixed(1)} ({bid.total_reviews || 0})</span>}
              {bid.trust_level && <span className={`trust-badge trust-badge--${bid.trust_level}`}>{bid.trust_level.charAt(0).toUpperCase() + bid.trust_level.slice(1)}</span>}
              {bidBadge ? (
                <span
                  style={{
                    backgroundColor: bidBadge.color,
                    color: 'white',
                    padding: '2px 8px',
                    borderRadius: '12px',
                    fontSize: '11px',
                    fontWeight: '600',
                    marginLeft: '8px',
                  }}
                >
                  {bidBadge.label}
                </span>
              ) : null}
            </div>
          </div>
        </div>
        <div className="bid-amount">
          <span className="bid-amount-value">₹{Number(bid.amount).toLocaleString('en-IN')}</span>
          {bid.includes_materials && <span className="bid-materials-tag">Includes materials</span>}
        </div>
      </div>

      {bid.message && <p className="bid-message">"{bid.message}"</p>}

      <div className="bid-meta-row">
        {bid.estimated_days && <span><FiClock size={13} /> {bid.estimated_days} day{bid.estimated_days > 1 ? 's' : ''}</span>}
        {bid.site_visit_date && <span><FiMapPin size={13} /> Site visit: {new Date(bid.site_visit_date).toLocaleDateString('en-IN')}</span>}
      </div>

      {!isAccepted && canAccept && (
        <button className="bid-accept-btn" onClick={() => onAccept(bid.id)}>
          <FiCheckCircle size={15} /> Accept This Bid
        </button>
      )}
      {isAccepted && <div className="bid-accepted-badge">✅ Accepted</div>}
    </div>
  );
}

// ── My Quote Requests List ────────────────────────────────────────────────────

function MyQuoteRequests() {
  const [quotes, setQuotes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState(null);
  const [detail, setDetail] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);

  useEffect(() => { fetchQuotes(); }, []);

  async function fetchQuotes() {
    try {
      const res = await get('/quotes/my');
      setQuotes(res.data || []);
    } catch (err) {
      console.error('Failed to fetch quotes:', err);
    } finally {
      setLoading(false);
    }
  }

  async function fetchDetail(id) {
    setDetailLoading(true);
    try {
      const res = await get(`/quotes/${id}`);
      setDetail(res.data);
    } catch (err) {
      console.error('Failed to fetch quote detail:', err);
    } finally {
      setDetailLoading(false);
    }
  }

  async function handleAcceptBid(quoteId, bidId) {
    try {
      await post(`/quotes/${quoteId}/accept-bid/${bidId}`);
      await fetchDetail(quoteId);
      await fetchQuotes();
    } catch (err) {
      console.error('Failed to accept bid:', err);
      alert(err.message || 'Failed to accept bid.');
    }
  }

  const statusColors = {
    open: '#6366f1', bidding: '#f97316', accepted: '#10b981',
    in_progress: '#3b82f6', completed: '#059669', cancelled: '#ef4444', expired: '#9ca3af',
  };

  if (loading) return <LoadingSpinner />;

  if (selected && detail) {
    return (
      <div className="qr-detail">
        <button className="qr-back-btn" onClick={() => { setSelected(null); setDetail(null); }}>
          <FiArrowLeft size={16} /> Back to My Requests
        </button>
        <div className="qr-detail-header">
          <h2>{detail.title}</h2>
          <span className="qr-status-badge" style={{ backgroundColor: statusColors[detail.status] || '#9ca3af' }}>
            {detail.status.replace('_', ' ').replace(/\b\w/g, (c) => c.toUpperCase())}
          </span>
        </div>
        <p className="qr-detail-desc">{detail.description}</p>
        <div className="qr-detail-meta">
          {detail.area_sqft && <span>📐 {detail.area_sqft} sq ft</span>}
          {detail.budget_min && detail.budget_max && <span>💰 ₹{Number(detail.budget_min).toLocaleString('en-IN')} – ₹{Number(detail.budget_max).toLocaleString('en-IN')}</span>}
          {detail.location_text && <span>📍 {detail.location_text}</span>}
          {detail.preferred_date && <span>📅 {new Date(detail.preferred_date).toLocaleDateString('en-IN')}</span>}
        </div>

        <h3 className="qr-bids-heading">
          {detail.bids?.length ? `${detail.bids.length} Bid${detail.bids.length > 1 ? 's' : ''} Received` : 'No bids yet — professionals are reviewing your request'}
        </h3>
        {detailLoading ? <LoadingSpinner /> : (
          <div className="qr-bids-list">
            {(detail.bids || []).map((bid) => (
              <BidCard
                key={bid.id}
                bid={bid}
                allBids={detail.bids || []}
                isAccepted={detail.accepted_bid_id === bid.id}
                canAccept={['open', 'bidding'].includes(detail.status)}
                onAccept={(bidId) => handleAcceptBid(detail.id, bidId)}
              />
            ))}
          </div>
        )}
      </div>
    );
  }

  if (!quotes.length) {
    return (
      <div className="qr-empty">
        <FiAlertCircle size={48} />
        <h3>No quote requests yet</h3>
        <p>Submit a quote request to get bids from verified professionals.</p>
      </div>
    );
  }

  return (
    <div className="qr-list">
      {quotes.map((q) => (
        <button key={q.id} className="qr-list-item" onClick={() => { setSelected(q.id); fetchDetail(q.id); }}>
          <div className="qr-list-left">
            <h4>{q.title}</h4>
            <span className="qr-cat-tag">{q.category_name}</span>
          </div>
          <div className="qr-list-right">
            <span className="qr-bid-count">{q.bid_count} bid{q.bid_count !== 1 ? 's' : ''}</span>
            <span className="qr-status-badge" style={{ backgroundColor: statusColors[q.status] || '#9ca3af' }}>
              {q.status.replace('_', ' ').replace(/\b\w/g, (c) => c.toUpperCase())}
            </span>
          </div>
        </button>
      ))}
    </div>
  );
}

// ── Main Page ─────────────────────────────────────────────────────────────────

export default function QuoteRequest() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { isAuthenticated } = useAuth();
  const [tab, setTab] = useState(searchParams.get('tab') || 'submit');
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    fetchCategories();
  }, []);

  async function fetchCategories() {
    try {
      const res = await get('/categories');
      // Flatten tree to get all categories with service_mode
      const flat = [];
      const flatten = (cats) => cats.forEach((c) => {
        flat.push(c);
        if (c.children?.length) flatten(c.children);
      });
      flatten(res.data || []);
      setCategories(flat);
    } catch (err) {
      console.error('Failed to fetch categories:', err);
    }
  }

  async function handleSubmit(formData) {
    if (!isAuthenticated) {
      navigate('/login?redirect=/quotes?tab=submit');
      return;
    }
    setLoading(true);
    try {
      await post('/quotes', formData);
      setSuccess(true);
      setTimeout(() => { setSuccess(false); setTab('my-requests'); }, 2500);
    } catch (err) {
      console.error('Failed to submit quote:', err);
      alert(err.message || 'Failed to submit quote request. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="quote-request-page">
      <SEOMeta
        title="Get Quotes — SkillConnect"
        description="Submit your home service requirement and get quotes from verified professionals within 24 hours."
      />

      {/* Hero */}
      <section className="qr-hero">
        <h1>📋 Get Custom Quotes</h1>
        <p>For painting, renovation, interior design, and other projects — describe your need and get up to 3 competitive bids.</p>
        <div className="qr-steps">
          <div className="qr-step"><span>1</span> Describe Need</div>
          <div className="qr-step-arrow">→</div>
          <div className="qr-step"><span>2</span> Get 3 Bids</div>
          <div className="qr-step-arrow">→</div>
          <div className="qr-step"><span>3</span> Compare & Accept</div>
          <div className="qr-step-arrow">→</div>
          <div className="qr-step"><span>4</span> Pay via Escrow</div>
        </div>
      </section>

      {/* Tabs */}
      <div className="qr-tabs">
        <button className={`qr-tab ${tab === 'submit' ? 'active' : ''}`} onClick={() => setTab('submit')}>
          + New Request
        </button>
        {isAuthenticated && (
          <button className={`qr-tab ${tab === 'my-requests' ? 'active' : ''}`} onClick={() => setTab('my-requests')}>
            My Requests
          </button>
        )}
      </div>

      <div className="qr-content">
        {success && (
          <div className="qr-success-banner">
            <FiCheckCircle size={20} />
            Quote request submitted! Professionals will respond within 24 hours.
          </div>
        )}

        {tab === 'submit' ? (
          <SubmitQuoteForm categories={categories} onSubmit={handleSubmit} loading={loading} />
        ) : (
          <MyQuoteRequests />
        )}
      </div>
    </div>
  );
}
