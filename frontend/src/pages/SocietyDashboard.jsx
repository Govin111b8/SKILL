import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import {
  FiHome, FiBriefcase, FiFileText, FiDollarSign, FiClock,
  FiPlus, FiUser, FiMapPin, FiPhone, FiMail, FiChevronDown, FiChevronUp,
  FiStar, FiUsers, FiCheckCircle, FiSend,
} from 'react-icons/fi';
import { get, post } from '../api/client';
import { useAuth } from '../context/AuthContext';
import SEOMeta from '../components/SEOMeta';
import './SocietyDashboard.css';

const SOCIETY_TYPES = [
  { value: 'housing', label: 'Housing Society', icon: '🏢', desc: 'Apartment complexes, gated communities, townships' },
  { value: 'corporate', label: 'Corporate Office', icon: '🏬', desc: 'IT parks, offices, co-working spaces' },
  { value: 'government', label: 'Government Institute', icon: '🏛️', desc: 'Govt offices, PSUs, public institutions' },
  { value: 'ngo', label: 'NGO / Trust', icon: '🤝', desc: 'Non-profits and charitable organisations' },
];

const SERVICE_CATEGORIES = [
  'Deep Cleaning', 'Pest Control', 'Plumbing', 'Electrical', 'Security Guards',
  'CCTV Maintenance', 'Elevator Maintenance', 'Landscaping', 'Painting', 'Carpentry',
  'Fire Safety', 'Water Tank Cleaning', 'Generator Maintenance', 'AC Servicing',
];

function SocietyDashboard() {
  const { isAuthenticated, user } = useAuth();
  const [view, setView] = useState('browse'); // browse | requests | enquiry
  const [openRequests, setOpenRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [expandedReq, setExpandedReq] = useState(null);

  // B2B Enquiry form state
  const [enquiry, setEnquiry] = useState({
    company_name: '', contact_name: '', contact_email: '', phone: '',
    service_type: '', employee_count: '', frequency: '', city: '', budget: '', additional_info: '',
  });
  const [enquirySubmitted, setEnquirySubmitted] = useState(false);
  const [enquiryLoading, setEnquiryLoading] = useState(false);
  const [enquiryError, setEnquiryError] = useState(null);

  // Bid state
  const [bidForms, setBidForms] = useState({});
  const [bidSubmitting, setBidSubmitting] = useState(null);

  useEffect(() => {
    fetchOpenRequests();
  }, []);

  async function fetchOpenRequests() {
    try {
      const res = await get('/societies/requests?limit=20');
      setOpenRequests(res.data?.requests || []);
    } catch (err) {
      console.error('Failed to fetch society requests:', err);
    } finally {
      setLoading(false);
    }
  }

  async function submitEnquiry(e) {
    e.preventDefault();
    setEnquiryLoading(true);
    setEnquiryError(null);
    try {
      await post('/societies/b2b-enquiry', {
        ...enquiry,
        employee_count: enquiry.employee_count ? parseInt(enquiry.employee_count, 10) : undefined,
      });
      setEnquirySubmitted(true);
    } catch (err) {
      setEnquiryError(err.message || 'Failed to submit enquiry. Please try again.');
    } finally {
      setEnquiryLoading(false);
    }
  }

  async function submitBid(requestId) {
    const form = bidForms[requestId] || {};
    if (!form.amount || !form.proposal) return;
    setBidSubmitting(requestId);
    try {
      await post(`/societies/requests/${requestId}/bids`, {
        amount: parseFloat(form.amount),
        proposal: form.proposal,
        timeline_days: form.timeline_days ? parseInt(form.timeline_days, 10) : undefined,
      });
      setBidForms((prev) => ({ ...prev, [requestId]: { submitted: true } }));
    } catch (err) {
      console.error('Failed to submit bid:', err);
    } finally {
      setBidSubmitting(null);
    }
  }

  const statusColors = {
    open: '#10b981',
    bidding: '#f59e0b',
    awarded: '#6366f1',
    in_progress: '#3b82f6',
    completed: '#6b7280',
    cancelled: '#ef4444',
  };

  const statusLabels = {
    open: 'Open for Bids',
    bidding: 'Reviewing Bids',
    awarded: 'Awarded',
    in_progress: 'In Progress',
    completed: 'Completed',
    cancelled: 'Cancelled',
  };

  return (
    <div className="society-dashboard">
      <SEOMeta
        title="Society & B2B Services — SkillConnect"
        description="Bulk service solutions for housing societies, corporate offices, and B2B clients. Post requirements, get competitive bids from verified professionals."
      />

      {/* Hero */}
      <div className="society-hero">
        <div className="society-hero-content">
          <div className="society-hero-badge">🏢 B2B & Society Services</div>
          <h1>Services for Every Scale</h1>
          <p>
            Whether you manage a 500-unit housing society or a 1,000-employee corporate campus — get verified professionals for all your facility needs.
          </p>
          <div className="society-hero-cta">
            <button className="btn-primary-lg" onClick={() => setView('enquiry')}>
              <FiBriefcase /> Get a Custom Quote
            </button>
            <button className="btn-outline-lg" onClick={() => setView('requests')}>
              <FiFileText /> Browse Service Requests
            </button>
          </div>
        </div>
        <div className="society-hero-stats">
          <div className="stat-card"><span className="stat-value">500+</span><span className="stat-label">Societies Served</span></div>
          <div className="stat-card"><span className="stat-value">40+</span><span className="stat-label">Service Types</span></div>
          <div className="stat-card"><span className="stat-value">4.8★</span><span className="stat-label">Average Rating</span></div>
        </div>
      </div>

      {/* Society type cards */}
      <section className="society-types-section">
        <h2>Who We Serve</h2>
        <div className="society-types-grid">
          {SOCIETY_TYPES.map((t) => (
            <div key={t.value} className="society-type-card">
              <span className="society-type-icon">{t.icon}</span>
              <h3>{t.label}</h3>
              <p>{t.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Popular services */}
      <section className="society-services-section">
        <h2>Popular Society Services</h2>
        <div className="society-services-grid">
          {SERVICE_CATEGORIES.map((cat) => (
            <div key={cat} className="service-chip-card">
              <FiCheckCircle className="chip-check" />
              <span>{cat}</span>
            </div>
          ))}
        </div>
      </section>

      {/* Tab navigation */}
      <div className="society-tabs">
        <button className={view === 'browse' ? 'tab active' : 'tab'} onClick={() => setView('browse')}>
          <FiHome /> Overview
        </button>
        <button className={view === 'requests' ? 'tab active' : 'tab'} onClick={() => setView('requests')}>
          <FiFileText /> Open Requests {openRequests.length > 0 && <span className="badge">{openRequests.length}</span>}
        </button>
        <button className={view === 'enquiry' ? 'tab active' : 'tab'} onClick={() => setView('enquiry')}>
          <FiBriefcase /> B2B Enquiry
        </button>
      </div>

      {/* Open Requests */}
      {view === 'requests' && (
        <section className="society-requests-section">
          <div className="section-header">
            <h2>Open Service Requests</h2>
            <p>Browse bulk service requirements from housing societies and corporates</p>
          </div>
          {loading ? (
            <div className="loading-state">Loading requests...</div>
          ) : openRequests.length === 0 ? (
            <div className="empty-state">
              <FiFileText size={48} />
              <h3>No open requests yet</h3>
              <p>Check back soon — societies post new requirements regularly.</p>
            </div>
          ) : (
            <div className="requests-list">
              {openRequests.map((req) => (
                <div key={req.id} className="request-card">
                  <div className="request-header" onClick={() => setExpandedReq(expandedReq === req.id ? null : req.id)}>
                    <div className="request-meta">
                      <span className="request-badge" style={{ background: statusColors[req.status] }}>
                        {statusLabels[req.status]}
                      </span>
                      <span className="request-type">{req.society_type === 'corporate' ? '🏬 Corporate' : '🏢 Housing Society'}</span>
                      {req.category_name && <span className="request-category">{req.category_name}</span>}
                    </div>
                    <h3>{req.title}</h3>
                    <div className="request-info">
                      <span><FiMapPin /> {req.city}</span>
                      {req.units_covered && <span><FiUsers /> {req.units_covered} units</span>}
                      {req.budget_range && <span><FiDollarSign /> {req.budget_range}</span>}
                      {req.preferred_date && <span><FiClock /> {new Date(req.preferred_date).toLocaleDateString('en-IN')}</span>}
                      <span className="bid-count">{req.bid_count || 0} bids</span>
                    </div>
                    <button className="expand-btn">
                      {expandedReq === req.id ? <FiChevronUp /> : <FiChevronDown />}
                    </button>
                  </div>

                  {expandedReq === req.id && (
                    <div className="request-details">
                      <p className="request-description">{req.description}</p>
                      <div className="request-detail-grid">
                        {req.frequency && req.frequency !== 'one_time' && (
                          <div><strong>Frequency:</strong> {req.frequency.replace('_', ' ')}</div>
                        )}
                        {req.preferred_time && <div><strong>Preferred Time:</strong> {req.preferred_time}</div>}
                        <div><strong>Posted by:</strong> {req.society_name}</div>
                      </div>

                      {isAuthenticated && user?.role === 'professional' && (
                        <div className="bid-form">
                          {bidForms[req.id]?.submitted ? (
                            <div className="bid-success">
                              <FiCheckCircle /> Bid submitted successfully!
                            </div>
                          ) : (
                            <>
                              <h4>Submit Your Bid</h4>
                              <div className="bid-fields">
                                <input
                                  type="number"
                                  placeholder="Total bid amount (₹)"
                                  value={bidForms[req.id]?.amount || ''}
                                  onChange={(e) => setBidForms((p) => ({ ...p, [req.id]: { ...p[req.id], amount: e.target.value } }))}
                                />
                                <input
                                  type="number"
                                  placeholder="Timeline (days)"
                                  value={bidForms[req.id]?.timeline_days || ''}
                                  onChange={(e) => setBidForms((p) => ({ ...p, [req.id]: { ...p[req.id], timeline_days: e.target.value } }))}
                                />
                                <textarea
                                  placeholder="Your proposal — explain your approach, experience, and why you're the best fit..."
                                  rows={3}
                                  value={bidForms[req.id]?.proposal || ''}
                                  onChange={(e) => setBidForms((p) => ({ ...p, [req.id]: { ...p[req.id], proposal: e.target.value } }))}
                                />
                                <button
                                  className="btn-submit-bid"
                                  onClick={() => submitBid(req.id)}
                                  disabled={bidSubmitting === req.id || !bidForms[req.id]?.amount || !bidForms[req.id]?.proposal}
                                >
                                  {bidSubmitting === req.id ? 'Submitting...' : <><FiSend /> Submit Bid</>}
                                </button>
                              </div>
                            </>
                          )}
                        </div>
                      )}
                      {(!isAuthenticated || user?.role !== 'professional') && (
                        <p className="login-prompt">
                          <Link to="/login">Login as a professional</Link> to submit a bid
                        </p>
                      )}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </section>
      )}

      {/* B2B Enquiry Form */}
      {view === 'enquiry' && (
        <section className="b2b-enquiry-section">
          <div className="section-header">
            <h2>B2B Service Enquiry</h2>
            <p>Tell us about your organisation's service needs and we'll connect you with the right professionals.</p>
          </div>

          {enquirySubmitted ? (
            <div className="enquiry-success">
              <FiCheckCircle size={64} />
              <h3>Enquiry Received!</h3>
              <p>Thank you for reaching out. Our B2B team will contact you within 24 hours at your provided email or phone.</p>
              <button className="btn-primary" onClick={() => { setEnquirySubmitted(false); setEnquiry({ company_name: '', contact_name: '', contact_email: '', phone: '', service_type: '', employee_count: '', frequency: '', city: '', budget: '', additional_info: '' }); }}>
                Submit Another Enquiry
              </button>
            </div>
          ) : (
            <form className="b2b-form" onSubmit={submitEnquiry}>
              <div className="form-grid">
                <div className="form-group">
                  <label>Company / Organisation Name *</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Prestige Shantiniketan Society"
                    value={enquiry.company_name}
                    onChange={(e) => setEnquiry((p) => ({ ...p, company_name: e.target.value }))}
                  />
                </div>
                <div className="form-group">
                  <label>Contact Person Name *</label>
                  <input
                    type="text"
                    required
                    placeholder="Your full name"
                    value={enquiry.contact_name}
                    onChange={(e) => setEnquiry((p) => ({ ...p, contact_name: e.target.value }))}
                  />
                </div>
                <div className="form-group">
                  <label>Email Address *</label>
                  <div className="input-icon-wrap">
                    <FiMail className="input-icon" />
                    <input
                      type="email"
                      required
                      placeholder="contact@company.com"
                      value={enquiry.contact_email}
                      onChange={(e) => setEnquiry((p) => ({ ...p, contact_email: e.target.value }))}
                    />
                  </div>
                </div>
                <div className="form-group">
                  <label>Phone Number *</label>
                  <div className="input-icon-wrap">
                    <FiPhone className="input-icon" />
                    <input
                      type="tel"
                      required
                      placeholder="+91 98765 43210"
                      value={enquiry.phone}
                      onChange={(e) => setEnquiry((p) => ({ ...p, phone: e.target.value }))}
                    />
                  </div>
                </div>
                <div className="form-group full-width">
                  <label>Type of Service Required</label>
                  <input
                    type="text"
                    placeholder="e.g. Monthly pest control, annual AC servicing, daily housekeeping"
                    value={enquiry.service_type}
                    onChange={(e) => setEnquiry((p) => ({ ...p, service_type: e.target.value }))}
                  />
                </div>
                <div className="form-group">
                  <label>Number of Units / Employees</label>
                  <input
                    type="number"
                    min="1"
                    placeholder="e.g. 250 apartments"
                    value={enquiry.employee_count}
                    onChange={(e) => setEnquiry((p) => ({ ...p, employee_count: e.target.value }))}
                  />
                </div>
                <div className="form-group">
                  <label>Service Frequency</label>
                  <select value={enquiry.frequency} onChange={(e) => setEnquiry((p) => ({ ...p, frequency: e.target.value }))}>
                    <option value="">Select frequency</option>
                    <option value="one_time">One-time</option>
                    <option value="weekly">Weekly</option>
                    <option value="monthly">Monthly</option>
                    <option value="quarterly">Quarterly</option>
                  </select>
                </div>
                <div className="form-group">
                  <label>City</label>
                  <div className="input-icon-wrap">
                    <FiMapPin className="input-icon" />
                    <input
                      type="text"
                      placeholder="Bangalore, Mumbai, Delhi..."
                      value={enquiry.city}
                      onChange={(e) => setEnquiry((p) => ({ ...p, city: e.target.value }))}
                    />
                  </div>
                </div>
                <div className="form-group">
                  <label>Approximate Budget</label>
                  <input
                    type="text"
                    placeholder="e.g. ₹50,000 - ₹1,00,000"
                    value={enquiry.budget}
                    onChange={(e) => setEnquiry((p) => ({ ...p, budget: e.target.value }))}
                  />
                </div>
                <div className="form-group full-width">
                  <label>Additional Information</label>
                  <textarea
                    rows={4}
                    placeholder="Any specific requirements, constraints, or details you'd like us to know..."
                    value={enquiry.additional_info}
                    onChange={(e) => setEnquiry((p) => ({ ...p, additional_info: e.target.value }))}
                  />
                </div>
              </div>

              {enquiryError && <div className="error-banner">{enquiryError}</div>}

              <button type="submit" className="btn-submit-enquiry" disabled={enquiryLoading}>
                {enquiryLoading ? 'Submitting...' : <><FiSend /> Submit Enquiry</>}
              </button>
              <p className="form-note">
                🔒 Your details are secure. We'll never share your information without permission.
              </p>
            </form>
          )}
        </section>
      )}

      {/* Overview / Why section */}
      {view === 'browse' && (
        <section className="society-why-section">
          <h2>Why Choose SkillConnect for Your Society?</h2>
          <div className="why-grid">
            <div className="why-card">
              <span className="why-icon">✅</span>
              <h3>Verified Professionals</h3>
              <p>All professionals are background-checked and have verified government IDs before being listed.</p>
            </div>
            <div className="why-card">
              <span className="why-icon">💼</span>
              <h3>Single-Point Management</h3>
              <p>One account to manage all your society services — cleaning, maintenance, security, and more.</p>
            </div>
            <div className="why-card">
              <span className="why-icon">💳</span>
              <h3>GST Invoices</h3>
              <p>Automatic GST-compliant invoicing for every service — perfect for corporate and society accounting.</p>
            </div>
            <div className="why-card">
              <span className="why-icon">📊</span>
              <h3>Competitive Bidding</h3>
              <p>Post your requirement once and receive bids from multiple verified professionals. Pick the best value.</p>
            </div>
            <div className="why-card">
              <span className="why-icon">🔄</span>
              <h3>AMC / Subscriptions</h3>
              <p>Set up Annual Maintenance Contracts for regular services. Never worry about reminders again.</p>
            </div>
            <div className="why-card">
              <span className="why-icon">⭐</span>
              <h3>Quality Guarantee</h3>
              <p>Rate every service. Professionals with low ratings are automatically reviewed and removed.</p>
            </div>
          </div>

          <div className="society-cta-block">
            <h3>Ready to simplify your society's service management?</h3>
            <p>Join 500+ societies and 200+ corporates who trust SkillConnect for their facility needs.</p>
            <div className="cta-buttons">
              <button className="btn-primary-lg" onClick={() => setView('enquiry')}>
                <FiBriefcase /> Get a Custom Quote
              </button>
              <button className="btn-outline-lg" onClick={() => setView('requests')}>
                <FiFileText /> Browse Open Requests
              </button>
            </div>
          </div>
        </section>
      )}
    </div>
  );
}

export default SocietyDashboard;
