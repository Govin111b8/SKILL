import { useState, useEffect } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { FiArrowLeft, FiSend, FiAlertCircle, FiCheckCircle } from 'react-icons/fi';
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
  });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    get('/categories')
      .then((res) => setCategories(res.data || res || []))
      .catch(() => setCategories([]))
      .finally(() => setLoadingCats(false));
  }, []);

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
      const bookingId = res.data?.id || res.id;
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
