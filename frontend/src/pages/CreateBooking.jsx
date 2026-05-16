import { useState, useEffect } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import {
  FiArrowLeft, FiArrowRight, FiSend, FiAlertCircle, FiCheckCircle, FiClock,
  FiMapPin, FiTag, FiFileText, FiCalendar, FiCheck,
} from 'react-icons/fi';
import { get, post } from '../api/client';
import { useAuth } from '../context/AuthContext';
import './CreateBooking.css';

const STEPS = [
  { key: 'what', label: 'What', icon: FiTag, title: 'What do you need?', subtitle: 'Tell us about the service you need' },
  { key: 'when', label: 'When', icon: FiCalendar, title: 'When do you need it?', subtitle: 'Choose your preferred date and time' },
  { key: 'where', label: 'Where', icon: FiMapPin, title: 'Where should we come?', subtitle: 'Add the service location' },
  { key: 'confirm', label: 'Confirm', icon: FiCheck, title: 'Review & Confirm', subtitle: 'Make sure everything looks good' },
];

export default function CreateBooking() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { user } = useAuth();

  const professionalId = searchParams.get('professional_id') || '';
  const professionalName = searchParams.get('professional_name') || '';
  const preselectedService = searchParams.get('service') || '';
  const preselectedServiceId = searchParams.get('service_id') || '';

  const [categories, setCategories] = useState([]);
  const [loadingCats, setLoadingCats] = useState(true);
  const [proServices, setProServices] = useState([]);
  const [step, setStep] = useState(0);
  const [form, setForm] = useState({
    professional_id: professionalId,
    category_id: '',
    title: preselectedService,
    description: '',
    service_address: '',
    preferred_date: '',
    preferred_time: '',
    service_id: preselectedServiceId,
  });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);
  const [availableSlots, setAvailableSlots] = useState(null);
  const [loadingSlots, setLoadingSlots] = useState(false);

  useEffect(() => {
    get('/categories')
      .then((res) => setCategories(res.data || res || []))
      .catch(() => setCategories([]))
      .finally(() => setLoadingCats(false));
    // Load professional's services if professional is pre-selected
    if (professionalId) {
      get(`/services/${professionalId}`)
        .then(res => setProServices((res.data || res) || []))
        .catch(() => setProServices([]));
    }
  }, []);

  // Fetch available time slots when professional and date are selected
  useEffect(() => {
    if (form.professional_id && form.preferred_date) {
      fetchSlots();
    } else {
      setAvailableSlots(null);
    }
  }, [form.professional_id, form.preferred_date]);

  async function fetchSlots() {
    setLoadingSlots(true);
    try {
      const res = await get(`/schedule/slots?professional_id=${form.professional_id}&date=${form.preferred_date}`);
      setAvailableSlots(res.data || res);
    } catch {
      setAvailableSlots(null);
    } finally {
      setLoadingSlots(false);
    }
  }

  function handleChange(e) {
    setForm({ ...form, [e.target.name]: e.target.value });
    setError(null);
  }

  function canAdvance() {
    if (step === 0) return form.title.trim() && form.category_id;
    if (step === 1) return form.preferred_date;
    if (step === 2) return true; // address is optional
    return true;
  }

  function nextStep() {
    if (!canAdvance()) {
      if (step === 0) setError('Please fill in the title and select a category');
      if (step === 1) setError('Please select a date');
      return;
    }
    setError(null);
    setStep(s => Math.min(s + 1, STEPS.length - 1));
  }

  function prevStep() {
    setError(null);
    setStep(s => Math.max(s - 1, 0));
  }

  async function handleSubmit() {
    setSubmitting(true);
    setError(null);
    try {
      const payload = {
        ...form,
        professional_id: form.professional_id || undefined,
        category_id: parseInt(form.category_id, 10),
      };
      const res = await post('/bookings', payload);
      const bookingData = res.data || res;
      const bookingId = bookingData.id;

      // If a time slot was selected, book it
      if (form.preferred_time && form.professional_id && bookingId) {
        const startTime = form.preferred_time;
        const endHour = parseInt(startTime.split(':')[0]) + 1;
        const endTime = `${String(endHour).padStart(2, '0')}:00`;
        try {
          await post('/schedule/slots/book', {
            professional_id: form.professional_id,
            date: form.preferred_date,
            start_time: startTime,
            end_time: endTime,
            booking_id: bookingId,
          });
        } catch { /* non-critical — slot booking is optional */ }
      }

      setSuccess(true);
      setTimeout(() => {
        navigate(`/bookings/${bookingId}`);
      }, 1500);
    } catch (err) {
      setError(err.message || 'Failed to create booking');
    } finally {
      setSubmitting(false);
    }
  }

  const initials = professionalName
    ? professionalName.split(' ').map((w) => w[0]).join('').toUpperCase().slice(0, 2)
    : '?';

  const slots = availableSlots?.slots || [];
  const isBlocked = availableSlots?.blocked;
  const currentStep = STEPS[step];
  const selectedCategory = categories.find(c => String(c.id) === String(form.category_id));

  return (
    <div className="create-booking">
      <div className="container">
        <Link to="/bookings" className="cb-back"><FiArrowLeft /> Back to Bookings</Link>

        {/* Step indicator */}
        <div className="wizard-steps">
          {STEPS.map((s, i) => {
            const Icon = s.icon;
            return (
              <div
                key={s.key}
                className={`wizard-step ${i === step ? 'active' : ''} ${i < step ? 'done' : ''}`}
                onClick={() => { if (i < step) setStep(i); }}
                role={i < step ? 'button' : undefined}
                tabIndex={i < step ? 0 : undefined}
              >
                <div className="wizard-step-dot">
                  {i < step ? <FiCheck size={14} /> : <Icon size={14} />}
                </div>
                <span className="wizard-step-label">{s.label}</span>
                {i < STEPS.length - 1 && <div className="wizard-step-line" />}
              </div>
            );
          })}
        </div>

        <div className="cb-card">
          {/* Step header */}
          <div className="step-header">
            <h1>{currentStep.title}</h1>
            <p>{currentStep.subtitle}</p>
          </div>

          {professionalName && step === 0 && (
            <div className="cb-pro-badge">
              <div className="pro-avatar">{initials}</div>
              <div className="pro-info">
                <div className="pro-label">Booking with</div>
                <div className="pro-name">{professionalName}</div>
              </div>
            </div>
          )}

          {error && <div className="cb-error"><FiAlertCircle /> {error}</div>}
          {success && <div className="cb-success"><FiCheckCircle /> Booking created! Redirecting...</div>}

          {/* ── Step 1: WHAT ── */}
          {step === 0 && (
            <div className="wizard-body">
              {/* Quick service selection if professional has services */}
              {proServices.length > 0 && (
                <div className="form-group">
                  <label><FiTag size={14} /> Select a service</label>
                  <div className="category-chips">
                    {proServices.map(svc => (
                      <button
                        key={svc.id}
                        type="button"
                        className={`category-chip ${form.service_id === svc.id ? 'selected' : ''}`}
                        onClick={() => setForm({
                          ...form,
                          service_id: svc.id,
                          title: svc.name,
                          category_id: svc.category_id ? String(svc.category_id) : form.category_id,
                        })}
                      >
                        {svc.name}
                        {(svc.price_min || svc.price_max) && (
                          <span style={{ fontSize: '0.75rem', opacity: 0.7, marginLeft: '0.25rem' }}>
                            (₹{svc.price_min || '—'}–₹{svc.price_max || '—'})
                          </span>
                        )}
                      </button>
                    ))}
                  </div>
                </div>
              )}
              <div className="form-group">
                <label><FiFileText size={14} /> What do you need done? <span className="required">*</span></label>
                <input
                  type="text" name="title" value={form.title}
                  onChange={handleChange}
                  placeholder="e.g. Fix leaking kitchen faucet"
                  autoFocus
                />
              </div>
              <div className="form-group">
                <label><FiTag size={14} /> Service category <span className="required">*</span></label>
                {loadingCats ? (
                  <p className="loading-text">Loading categories...</p>
                ) : (
                  <div className="category-chips">
                    {categories.map((cat) => (
                      <button
                        key={cat.id}
                        type="button"
                        className={`category-chip ${String(form.category_id) === String(cat.id) ? 'selected' : ''}`}
                        onClick={() => setForm({ ...form, category_id: String(cat.id) })}
                      >
                        {cat.name}
                      </button>
                    ))}
                  </div>
                )}
              </div>
              <div className="form-group">
                <label>Tell us more (optional)</label>
                <textarea
                  name="description" value={form.description}
                  onChange={handleChange}
                  placeholder="Describe what you need help with — the more detail, the better!"
                  rows={3}
                />
              </div>
            </div>
          )}

          {/* ── Step 2: WHEN ── */}
          {step === 1 && (
            <div className="wizard-body">
              <div className="form-group">
                <label><FiCalendar size={14} /> Preferred date <span className="required">*</span></label>
                <input
                  type="date" name="preferred_date"
                  value={form.preferred_date}
                  onChange={handleChange}
                  min={new Date().toISOString().split('T')[0]}
                  autoFocus
                />
              </div>

              {form.professional_id && form.preferred_date && (
                <div className="form-group">
                  <label><FiClock size={14} /> Available Time Slots</label>
                  {loadingSlots ? (
                    <p className="slots-loading">Loading available times...</p>
                  ) : isBlocked ? (
                    <p className="slots-blocked">Professional is unavailable on this date. Please choose another date.</p>
                  ) : slots.length > 0 ? (
                    <div className="time-slots-grid">
                      {slots.map((slot, i) => (
                        <label
                          key={i}
                          className={`time-slot ${!slot.available ? 'time-slot--booked' : ''} ${form.preferred_time === slot.start_time ? 'time-slot--selected' : ''}`}
                        >
                          <input
                            type="radio" name="preferred_time"
                            value={slot.start_time}
                            checked={form.preferred_time === slot.start_time}
                            onChange={handleChange}
                            disabled={!slot.available}
                          />
                          <span className="slot-time">{slot.start_time} — {slot.end_time}</span>
                          <span className="slot-status">{slot.available ? 'Available' : 'Booked'}</span>
                        </label>
                      ))}
                    </div>
                  ) : (
                    <p className="slots-empty">No schedule set for this day. You can still request a booking.</p>
                  )}
                </div>
              )}
            </div>
          )}

          {/* ── Step 3: WHERE ── */}
          {step === 2 && (
            <div className="wizard-body">
              <div className="form-group">
                <label><FiMapPin size={14} /> Service address</label>
                <input
                  type="text" name="service_address"
                  value={form.service_address}
                  onChange={handleChange}
                  placeholder="Where should the service be performed?"
                  autoFocus
                />
                <span className="form-hint">Leave blank if the professional will provide the location</span>
              </div>

              {!professionalId && (
                <div className="form-group">
                  <label>Professional ID (optional)</label>
                  <input
                    type="text" name="professional_id"
                    value={form.professional_id}
                    onChange={handleChange}
                    placeholder="Leave blank to find the best match"
                  />
                </div>
              )}
            </div>
          )}

          {/* ── Step 4: CONFIRM ── */}
          {step === 3 && (
            <div className="wizard-body">
              <div className="confirm-summary">
                <div className="confirm-row">
                  <span className="confirm-label"><FiTag size={14} /> Service</span>
                  <span className="confirm-value">{form.title}</span>
                </div>
                <div className="confirm-row">
                  <span className="confirm-label"><FiFileText size={14} /> Category</span>
                  <span className="confirm-value">{selectedCategory?.name || '—'}</span>
                </div>
                {form.description && (
                  <div className="confirm-row">
                    <span className="confirm-label">Details</span>
                    <span className="confirm-value">{form.description}</span>
                  </div>
                )}
                <div className="confirm-row">
                  <span className="confirm-label"><FiCalendar size={14} /> Date</span>
                  <span className="confirm-value">
                    {new Date(form.preferred_date + 'T00:00').toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })}
                  </span>
                </div>
                {form.preferred_time && (
                  <div className="confirm-row">
                    <span className="confirm-label"><FiClock size={14} /> Time</span>
                    <span className="confirm-value">{form.preferred_time}</span>
                  </div>
                )}
                {form.service_address && (
                  <div className="confirm-row">
                    <span className="confirm-label"><FiMapPin size={14} /> Location</span>
                    <span className="confirm-value">{form.service_address}</span>
                  </div>
                )}
                {professionalName && (
                  <div className="confirm-row">
                    <span className="confirm-label">Professional</span>
                    <span className="confirm-value">{professionalName}</span>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Navigation */}
          <div className="wizard-nav">
            {step > 0 && (
              <button type="button" className="btn btn-secondary wizard-prev" onClick={prevStep}>
                <FiArrowLeft /> Back
              </button>
            )}
            <div className="wizard-nav-spacer" />
            {step < STEPS.length - 1 ? (
              <button
                type="button"
                className="btn btn-primary wizard-next"
                onClick={nextStep}
                disabled={!canAdvance()}
              >
                Next <FiArrowRight />
              </button>
            ) : (
              <button
                type="button"
                className="btn btn-primary wizard-submit"
                onClick={handleSubmit}
                disabled={submitting || success}
              >
                <FiSend /> {submitting ? 'Creating...' : 'Confirm Booking'}
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
