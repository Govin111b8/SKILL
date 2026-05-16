import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  FiUser, FiBriefcase, FiGrid, FiImage, FiCalendar, FiCheckCircle,
  FiArrowLeft, FiArrowRight, FiMapPin, FiPlus, FiTrash2, FiSkipForward,
  FiDollarSign, FiClock, FiCheck,
} from 'react-icons/fi';
import { get, post, put } from '../api/client';
import { useAuth } from '../context/AuthContext';
import './ProfessionalOnboarding.css';

const STEPS = [
  { key: 'type', label: 'Type', icon: FiUser, title: 'How do you work?', subtitle: 'Choose your provider type' },
  { key: 'details', label: 'Details', icon: FiBriefcase, title: 'Tell us about yourself', subtitle: 'Fill in your professional details' },
  { key: 'services', label: 'Services', icon: FiGrid, title: 'What do you offer?', subtitle: 'Select categories and add services' },
  { key: 'portfolio', label: 'Portfolio', icon: FiImage, title: 'Show your work', subtitle: 'Upload photos and showcase projects' },
  { key: 'availability', label: 'Availability', icon: FiCalendar, title: 'Set your schedule', subtitle: 'Let customers know when you\'re available' },
  { key: 'review', label: 'Publish', icon: FiCheckCircle, title: 'Review & Publish', subtitle: 'Make sure everything looks good' },
];

export default function ProfessionalOnboarding() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [step, setStep] = useState(0);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);

  // Step 1: Provider type
  const [providerType, setProviderType] = useState('individual');

  // Step 2: Details
  const [details, setDetails] = useState({
    headline: '', bio: '', years_of_experience: '', pricing_estimate: '', location: '',
    company_name: '', registration_number: '', team_size: '', description: '', service_areas: '',
  });

  // Step 3: Services
  const [categories, setCategories] = useState([]);
  const [selectedCategories, setSelectedCategories] = useState([]);
  const [services, setServices] = useState([]);
  const [newService, setNewService] = useState({ name: '', description: '', price_min: '', price_max: '', duration_minutes: '' });

  // Step 4: Portfolio
  const [portfolioItems, setPortfolioItems] = useState([]);
  const [newPortfolioUrl, setNewPortfolioUrl] = useState('');
  const [newPortfolioCaption, setNewPortfolioCaption] = useState('');
  const [beforeAfterItems, setBeforeAfterItems] = useState([]);
  const [newBefore, setNewBefore] = useState('');
  const [newAfter, setNewAfter] = useState('');

  // Step 5: Availability
  const [availabilityStatus, setAvailabilityStatus] = useState('available');

  useEffect(() => {
    get('/categories')
      .then((res) => setCategories(res.data || res || []))
      .catch(() => setCategories([]));
  }, []);

  function handleDetailChange(e) {
    setDetails({ ...details, [e.target.name]: e.target.value });
  }

  function toggleCategory(catId) {
    setSelectedCategories((prev) =>
      prev.includes(catId) ? prev.filter((id) => id !== catId) : [...prev, catId]
    );
  }

  function addService() {
    if (!newService.name) return;
    setServices([...services, { ...newService, id: Date.now() }]);
    setNewService({ name: '', description: '', price_min: '', price_max: '', duration_minutes: '' });
  }

  function removeService(id) {
    setServices(services.filter((s) => s.id !== id));
  }

  function addPortfolioItem() {
    if (!newPortfolioUrl) return;
    setPortfolioItems([...portfolioItems, { url: newPortfolioUrl, caption: newPortfolioCaption, id: Date.now() }]);
    setNewPortfolioUrl('');
    setNewPortfolioCaption('');
  }

  function addBeforeAfter() {
    if (!newBefore || !newAfter) return;
    setBeforeAfterItems([...beforeAfterItems, { before: newBefore, after: newAfter, id: Date.now() }]);
    setNewBefore('');
    setNewAfter('');
  }

  function detectLocation() {
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setDetails((d) => ({ ...d, location: `${pos.coords.latitude.toFixed(4)}, ${pos.coords.longitude.toFixed(4)}` }));
      },
      () => setError('Could not detect location')
    );
  }

  async function saveStep() {
    setSaving(true);
    setError(null);
    try {
      if (step === 0) {
        await put('/professionals/profile', { provider_type: providerType });
      } else if (step === 1) {
        const payload = providerType === 'individual'
          ? { headline: details.headline, bio: details.bio, years_of_experience: Number(details.years_of_experience) || 0, pricing_estimate: details.pricing_estimate, location: details.location }
          : { company_name: details.company_name, registration_number: details.registration_number, team_size: Number(details.team_size) || 0, bio: details.description, location: details.service_areas, provider_type: 'organization' };
        await put('/professionals/profile', payload);
      } else if (step === 2) {
        if (selectedCategories.length > 0) {
          await put('/professionals/profile', { categories: selectedCategories });
        }
        for (const svc of services) {
          if (!svc.saved) {
            try {
              await post('/services/me', { name: svc.name, description: svc.description, price_min: Number(svc.price_min) || 0, price_max: Number(svc.price_max) || 0, duration_minutes: Number(svc.duration_minutes) || 60 });
              svc.saved = true;
            } catch (e) {
              console.error('Failed to save service:', svc.name, e);
            }
          }
        }
      } else if (step === 3) {
        for (const item of portfolioItems) {
          if (!item.saved) {
            try {
              await post('/portfolio', { media_url: item.url, title: item.caption || 'Portfolio Item', description: item.caption || '', media_type: 'image' });
              item.saved = true;
            } catch (e) {
              console.error('Failed to save portfolio item:', e);
            }
          }
        }
      } else if (step === 4) {
        await put('/professionals/profile', { availability_status: availabilityStatus });
      }
    } catch (e) {
      setError(e.message || 'Failed to save. Please try again.');
    } finally {
      setSaving(false);
    }
  }

  async function handleNext() {
    await saveStep();
    if (step < STEPS.length - 1) setStep(step + 1);
  }

  function handlePrev() {
    if (step > 0) setStep(step - 1);
  }

  function handleSkip() {
    if (step < STEPS.length - 1) setStep(step + 1);
  }

  async function handlePublish() {
    setSaving(true);
    setError(null);
    try {
      await put('/professionals/profile', { onboarding_complete: true });
      navigate('/dashboard');
    } catch (e) {
      setError(e.message || 'Failed to publish. Please try again.');
    } finally {
      setSaving(false);
    }
  }

  function renderStep() {
    switch (step) {
      case 0: return renderTypeStep();
      case 1: return renderDetailsStep();
      case 2: return renderServicesStep();
      case 3: return renderPortfolioStep();
      case 4: return renderAvailabilityStep();
      case 5: return renderReviewStep();
      default: return null;
    }
  }

  function renderTypeStep() {
    return (
      <div className="onb-type-cards">
        <div
          className={`onb-type-card ${providerType === 'individual' ? 'selected' : ''}`}
          onClick={() => setProviderType('individual')}
          role="button"
          tabIndex={0}
          aria-label="Select Individual"
        >
          <div className="onb-type-icon"><FiUser /></div>
          <h3>I&apos;m an Individual / Freelancer</h3>
          <p>I work independently and offer my personal skills and services to customers.</p>
          {providerType === 'individual' && <div className="onb-type-check"><FiCheck /></div>}
        </div>
        <div
          className={`onb-type-card ${providerType === 'organization' ? 'selected' : ''}`}
          onClick={() => setProviderType('organization')}
          role="button"
          tabIndex={0}
          aria-label="Select Company"
        >
          <div className="onb-type-icon"><FiBriefcase /></div>
          <h3>I&apos;m a Company / Consultancy</h3>
          <p>I run a business with a team and offer organized services under a brand.</p>
          {providerType === 'organization' && <div className="onb-type-check"><FiCheck /></div>}
        </div>
      </div>
    );
  }

  function renderDetailsStep() {
    if (providerType === 'individual') {
      return (
        <div className="onb-form">
          <div className="form-group">
            <label>Headline <span className="required">*</span></label>
            <input name="headline" value={details.headline} onChange={handleDetailChange} placeholder="e.g. Expert Plumber with 10+ years experience" />
          </div>
          <div className="form-group">
            <label>Bio / About</label>
            <textarea name="bio" value={details.bio} onChange={handleDetailChange} placeholder="Tell customers about yourself, your experience, and what makes you special..." />
          </div>
          <div className="form-group">
            <label>Years of Experience</label>
            <input name="years_of_experience" type="number" min="0" value={details.years_of_experience} onChange={handleDetailChange} placeholder="e.g. 5" />
          </div>
          <div className="form-group">
            <label>Pricing Estimate</label>
            <input name="pricing_estimate" value={details.pricing_estimate} onChange={handleDetailChange} placeholder="e.g. ₹500 - ₹2000 per session" />
          </div>
          <div className="form-group">
            <label>Location</label>
            <div className="onb-location-row">
              <input name="location" value={details.location} onChange={handleDetailChange} placeholder="Your city or area" />
              <button type="button" className="onb-detect-btn" onClick={detectLocation}><FiMapPin /> Detect</button>
            </div>
          </div>
        </div>
      );
    }
    return (
      <div className="onb-form">
        <div className="form-group">
          <label>Company Name <span className="required">*</span></label>
          <input name="company_name" value={details.company_name} onChange={handleDetailChange} placeholder="Your company or brand name" />
        </div>
        <div className="form-group">
          <label>Registration Number</label>
          <input name="registration_number" value={details.registration_number} onChange={handleDetailChange} placeholder="GST or registration number (optional)" />
        </div>
        <div className="form-group">
          <label>Team Size</label>
          <input name="team_size" type="number" min="1" value={details.team_size} onChange={handleDetailChange} placeholder="Number of team members" />
        </div>
        <div className="form-group">
          <label>Description</label>
          <textarea name="description" value={details.description} onChange={handleDetailChange} placeholder="Describe your company and the services you provide..." />
        </div>
        <div className="form-group">
          <label>Service Areas</label>
          <input name="service_areas" value={details.service_areas} onChange={handleDetailChange} placeholder="Cities or areas you serve" />
        </div>
      </div>
    );
  }

  function renderServicesStep() {
    return (
      <div className="onb-services">
        <div className="onb-section">
          <h3>Select Categories</h3>
          <p className="onb-section-hint">Choose the categories that match your services</p>
          <div className="onb-category-chips">
            {categories.map((cat) => (
              <button
                key={cat.id}
                className={`onb-chip ${selectedCategories.includes(cat.id) ? 'selected' : ''}`}
                onClick={() => toggleCategory(cat.id)}
                type="button"
              >
                {cat.icon && <span>{cat.icon}</span>} {cat.name}
              </button>
            ))}
            {categories.length === 0 && <p className="loading-text">Loading categories...</p>}
          </div>
        </div>

        <div className="onb-section">
          <h3>Add Your Services</h3>
          <p className="onb-section-hint">Add specific services with pricing</p>
          <div className="onb-add-service">
            <input placeholder="Service name" value={newService.name} onChange={(e) => setNewService({ ...newService, name: e.target.value })} />
            <input placeholder="Description (optional)" value={newService.description} onChange={(e) => setNewService({ ...newService, description: e.target.value })} />
            <div className="onb-price-row">
              <input type="number" placeholder="Min price" value={newService.price_min} onChange={(e) => setNewService({ ...newService, price_min: e.target.value })} />
              <span>–</span>
              <input type="number" placeholder="Max price" value={newService.price_max} onChange={(e) => setNewService({ ...newService, price_max: e.target.value })} />
              <input type="number" placeholder="Duration (min)" value={newService.duration_minutes} onChange={(e) => setNewService({ ...newService, duration_minutes: e.target.value })} />
            </div>
            <button type="button" className="onb-add-btn" onClick={addService}><FiPlus /> Add Service</button>
          </div>
          {services.length > 0 && (
            <div className="onb-service-list">
              {services.map((svc) => (
                <div key={svc.id} className="onb-service-item">
                  <div className="onb-service-info">
                    <strong>{svc.name}</strong>
                    {svc.description && <span className="onb-service-desc">{svc.description}</span>}
                    <span className="onb-service-meta">
                      <FiDollarSign /> ₹{svc.price_min || 0} – ₹{svc.price_max || 0}
                      {svc.duration_minutes && <><FiClock /> {svc.duration_minutes} min</>}
                    </span>
                  </div>
                  <button type="button" className="onb-remove-btn" onClick={() => removeService(svc.id)}><FiTrash2 /></button>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    );
  }

  function renderPortfolioStep() {
    return (
      <div className="onb-portfolio">
        <div className="onb-section">
          <h3>Portfolio Photos/Videos</h3>
          <p className="onb-section-hint">Add URLs of your work photos or videos</p>
          <div className="onb-add-portfolio">
            <input placeholder="Image or video URL" value={newPortfolioUrl} onChange={(e) => setNewPortfolioUrl(e.target.value)} />
            <input placeholder="Caption (optional)" value={newPortfolioCaption} onChange={(e) => setNewPortfolioCaption(e.target.value)} />
            <button type="button" className="onb-add-btn" onClick={addPortfolioItem}><FiPlus /> Add</button>
          </div>
          {portfolioItems.length > 0 && (
            <div className="onb-portfolio-grid">
              {portfolioItems.map((item) => (
                <div key={item.id} className="onb-portfolio-item">
                  <img src={item.url} alt={item.caption || 'Portfolio'} onError={(e) => { e.target.src = 'https://via.placeholder.com/200'; }} />
                  {item.caption && <span>{item.caption}</span>}
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="onb-section">
          <h3>Before & After Showcase</h3>
          <p className="onb-section-hint">Show transformations with before/after pairs</p>
          <div className="onb-add-portfolio">
            <input placeholder="Before image URL" value={newBefore} onChange={(e) => setNewBefore(e.target.value)} />
            <input placeholder="After image URL" value={newAfter} onChange={(e) => setNewAfter(e.target.value)} />
            <button type="button" className="onb-add-btn" onClick={addBeforeAfter}><FiPlus /> Add Pair</button>
          </div>
          {beforeAfterItems.length > 0 && (
            <div className="onb-ba-list">
              {beforeAfterItems.map((item) => (
                <div key={item.id} className="onb-ba-item">
                  <div className="onb-ba-img"><img src={item.before} alt="Before" onError={(e) => { e.target.src = 'https://via.placeholder.com/150'; }} /><span>Before</span></div>
                  <div className="onb-ba-arrow">→</div>
                  <div className="onb-ba-img"><img src={item.after} alt="After" onError={(e) => { e.target.src = 'https://via.placeholder.com/150'; }} /><span>After</span></div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    );
  }

  function renderAvailabilityStep() {
    return (
      <div className="onb-availability">
        <div className="onb-section">
          <h3>Availability Status</h3>
          <div className="onb-status-cards">
            {['available', 'busy', 'away'].map((status) => (
              <div
                key={status}
                className={`onb-status-card ${availabilityStatus === status ? 'selected' : ''}`}
                onClick={() => setAvailabilityStatus(status)}
                role="button"
                tabIndex={0}
              >
                <span className={`onb-status-dot ${status}`} />
                <span className="onb-status-label">{status === 'available' ? '🟢 Available Now' : status === 'busy' ? '🟡 Busy' : '🔴 Away'}</span>
              </div>
            ))}
          </div>
        </div>
        <div className="onb-section">
          <h3>Weekly Schedule</h3>
          <p className="onb-section-hint">Set up your detailed weekly schedule on the schedule page.</p>
          <button type="button" className="onb-link-btn" onClick={() => navigate('/schedule')}>
            <FiCalendar /> Go to Schedule Settings
          </button>
        </div>
      </div>
    );
  }

  function renderReviewStep() {
    return (
      <div className="onb-review">
        <div className="onb-review-section">
          <h4>Provider Type</h4>
          <p>{providerType === 'individual' ? '👤 Individual / Freelancer' : '🏢 Company / Consultancy'}</p>
        </div>
        <div className="onb-review-section">
          <h4>Details</h4>
          {providerType === 'individual' ? (
            <ul>
              {details.headline && <li><strong>Headline:</strong> {details.headline}</li>}
              {details.years_of_experience && <li><strong>Experience:</strong> {details.years_of_experience} years</li>}
              {details.pricing_estimate && <li><strong>Pricing:</strong> {details.pricing_estimate}</li>}
              {details.location && <li><strong>Location:</strong> {details.location}</li>}
            </ul>
          ) : (
            <ul>
              {details.company_name && <li><strong>Company:</strong> {details.company_name}</li>}
              {details.team_size && <li><strong>Team Size:</strong> {details.team_size}</li>}
              {details.service_areas && <li><strong>Areas:</strong> {details.service_areas}</li>}
            </ul>
          )}
        </div>
        <div className="onb-review-section">
          <h4>Services ({services.length})</h4>
          {services.length > 0 ? (
            <ul>{services.map((s) => <li key={s.id}>{s.name} — ₹{s.price_min}–₹{s.price_max}</li>)}</ul>
          ) : <p className="onb-review-empty">No services added yet</p>}
        </div>
        <div className="onb-review-section">
          <h4>Categories ({selectedCategories.length})</h4>
          <div className="onb-review-chips">
            {selectedCategories.map((catId) => {
              const cat = categories.find((c) => c.id === catId);
              return cat ? <span key={catId} className="onb-chip selected">{cat.name}</span> : null;
            })}
            {selectedCategories.length === 0 && <p className="onb-review-empty">No categories selected</p>}
          </div>
        </div>
        <div className="onb-review-section">
          <h4>Portfolio ({portfolioItems.length} items)</h4>
          {portfolioItems.length === 0 && <p className="onb-review-empty">No portfolio items added</p>}
        </div>
        <div className="onb-review-section">
          <h4>Availability</h4>
          <p>{availabilityStatus === 'available' ? '🟢 Available' : availabilityStatus === 'busy' ? '🟡 Busy' : '🔴 Away'}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="professional-onboarding">
      <div className="onb-container">
        {/* Progress Bar */}
        <div className="onb-progress">
          {STEPS.map((s, i) => {
            const Icon = s.icon;
            const isActive = i === step;
            const isDone = i < step;
            return (
              <div key={s.key} className={`onb-step ${isActive ? 'active' : ''} ${isDone ? 'done' : ''}`} onClick={() => isDone && setStep(i)} role="button" tabIndex={0}>
                <div className="onb-step-dot"><Icon /></div>
                <span className="onb-step-label">{s.label}</span>
                {i < STEPS.length - 1 && <div className="onb-step-line" />}
              </div>
            );
          })}
        </div>

        {/* Card */}
        <div className="onb-card">
          <div className="onb-header">
            <h1>{STEPS[step].title}</h1>
            <p>{STEPS[step].subtitle}</p>
          </div>

          {error && <div className="onb-error">{error}</div>}

          <div className="onb-body">
            {renderStep()}
          </div>

          {/* Navigation */}
          <div className="onb-nav">
            {step > 0 && (
              <button type="button" className="onb-btn onb-btn-prev" onClick={handlePrev}>
                <FiArrowLeft /> Back
              </button>
            )}
            <div className="onb-nav-spacer" />
            {step < STEPS.length - 1 && (
              <button type="button" className="onb-skip-link" onClick={handleSkip}>
                <FiSkipForward /> Skip
              </button>
            )}
            {step < STEPS.length - 1 ? (
              <button type="button" className="onb-btn onb-btn-next" onClick={handleNext} disabled={saving}>
                {saving ? 'Saving...' : 'Next'} <FiArrowRight />
              </button>
            ) : (
              <button type="button" className="onb-btn onb-btn-publish" onClick={handlePublish} disabled={saving}>
                {saving ? 'Publishing...' : '🚀 Publish Storefront'}
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
