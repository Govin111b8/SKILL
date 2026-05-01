import { useState, useEffect } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { FiArrowLeft, FiSend, FiAlertCircle, FiCheckCircle, FiClock } from 'react-icons/fi';
import { get, post } from '../api/client';
import { useAuth } from '../context/AuthContext';
import './CreateBooking.css';

export default function CreateBooking() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { user } = useAuth();

  const professionalId = searchParams.get('professional_id') || '';
  const professionalName = searchParams.get('professional_name') || '';

  const [categories, setCategories] = useState([]);
  const [loadingCats, setLoadingCats] = useState(true);
  const [form, setForm] = useState({
    professional_id: professionalId,
    category_id: '',
    title: '',
    description: '',
    service_address: '',
    preferred_date: '',
    preferred_time: '',
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

  async function handleSubmit(e) {
    e.preventDefault();
    if (!form.title.trim()) return setError('Title is required');
    if (!form.category_id) return setError('Please select a category');
    if (!form.preferred_date) return setError('Please select a preferred date');

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
        const [startTime] = form.preferred_time.split('-');
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
      }, 1000);
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

  return (
    <div className="create-booking">
      <div className="container">
        <Link to="/bookings" className="cb-back"><FiArrowLeft /> Back to Bookings</Link>

        <div className="cb-card">
          <h1>Create Booking</h1>
          <p>Fill in the details to request a service</p>

          {professionalName && (
            <div className="cb-pro-badge">
              <div className="pro-avatar">{initials}</div>
              <div className="pro-info">
                <div className="pro-label">Professional</div>
                <div className="pro-name">{professionalName}</div>
              </div>
            </div>
          )}

          {error && (
            <div className="cb-error"><FiAlertCircle /> {error}</div>
          )}

          {success && (
            <div className="cb-success"><FiCheckCircle /> Booking created! Redirecting...</div>
          )}

          <form className="cb-form" onSubmit={handleSubmit}>
            <div className="form-group">
              <label>Title <span className="required">*</span></label>
              <input
                type="text"
                name="title"
                value={form.title}
                onChange={handleChange}
                placeholder="e.g. Fix leaking kitchen faucet"
                disabled={submitting}
              />
            </div>

            <div className="form-group">
              <label>Category <span className="required">*</span></label>
              <select
                name="category_id"
                value={form.category_id}
                onChange={handleChange}
                disabled={submitting || loadingCats}
              >
                <option value="">Select a category</option>
                {categories.map((cat) => (
                  <option key={cat.id} value={cat.id}>{cat.name}</option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label>Description</label>
              <textarea
                name="description"
                value={form.description}
                onChange={handleChange}
                placeholder="Describe what you need help with..."
                disabled={submitting}
              />
            </div>

            <div className="form-group">
              <label>Service Address</label>
              <input
                type="text"
                name="service_address"
                value={form.service_address}
                onChange={handleChange}
                placeholder="Where should the service be performed?"
                disabled={submitting}
              />
            </div>

            <div className="form-group">
              <label>Preferred Date <span className="required">*</span></label>
              <input
                type="date"
                name="preferred_date"
                value={form.preferred_date}
                onChange={handleChange}
                min={new Date().toISOString().split('T')[0]}
                disabled={submitting}
              />
            </div>

            {/* Time Slot Selection */}
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
                          type="radio"
                          name="preferred_time"
                          value={slot.start_time}
                          checked={form.preferred_time === slot.start_time}
                          onChange={handleChange}
                          disabled={!slot.available || submitting}
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

            {!professionalId && (
              <div className="form-group">
                <label>Professional ID (optional)</label>
                <input
                  type="text"
                  name="professional_id"
                  value={form.professional_id}
                  onChange={handleChange}
                  placeholder="Leave blank to find matches"
                  disabled={submitting}
                />
              </div>
            )}

            <div className="cb-submit">
              <button type="submit" className="btn btn-primary" disabled={submitting || success}>
                <FiSend /> {submitting ? 'Creating...' : 'Create Booking'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
