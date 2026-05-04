import { useState, useEffect } from 'react';
import { FiAlertTriangle, FiMapPin, FiPhone, FiCheck, FiClock, FiShield } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { get, post } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './Emergency.css';

function Emergency() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [emergencies, setEmergencies] = useState([]);
  const [categories, setCategories] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ category_id: '', description: '', location_address: '' });
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState('');
  const [location, setLocation] = useState(null);

  const isPro = user?.role === 'professional';

  useEffect(() => {
    fetchData();
    // Try to get user location
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => setLocation({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
        () => {}
      );
    }
  }, []);

  async function fetchData() {
    try {
      const [emergRes, catRes] = await Promise.all([
        get('/emergency'),
        get('/categories')
      ]);
      setEmergencies((emergRes.data || emergRes).emergencies || []);
      setCategories((catRes.data || catRes).categories || catRes || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }

  async function submitEmergency(e) {
    e.preventDefault();
    setSubmitting(true);
    setMessage('');
    try {
      await post('/emergency', {
        ...form,
        category_id: form.category_id || null,
        location_lat: location?.lat,
        location_lng: location?.lng
      });
      setMessage('🚨 Emergency request sent! Nearby professionals have been notified.');
      setShowForm(false);
      setForm({ category_id: '', description: '', location_address: '' });
      fetchData();
    } catch (err) {
      setMessage('Error: ' + err.message);
    } finally {
      setSubmitting(false);
    }
  }

  async function acceptEmergency(id) {
    try {
      await post(`/emergency/${id}/accept`);
      setMessage('✅ You accepted the emergency request. Contact the customer.');
      fetchData();
    } catch (err) {
      setMessage('Error: ' + err.message);
    }
  }

  async function resolveEmergency(id) {
    try {
      await post(`/emergency/${id}/resolve`);
      setMessage('✅ Emergency marked as resolved.');
      fetchData();
    } catch (err) {
      setMessage('Error: ' + err.message);
    }
  }

  async function triggerSOS() {
    try {
      await post('/emergency/sos', {
        location_lat: location?.lat,
        location_lng: location?.lng,
        message: 'SOS - Need immediate help'
      });
      setMessage('⚠️ SOS Alert sent! Your emergency contacts have been notified.');
    } catch (err) {
      setMessage('Error sending SOS: ' + err.message);
    }
  }

  if (loading) return <LoadingSpinner />;

  return (
    <div className="emergency-page">
      <div className="container">
        <div className="page-header">
          <div>
            <h1><FiAlertTriangle /> {isPro ? 'Emergency Requests' : 'Emergency Services'}</h1>
            <p className="page-subtitle">
              {isPro ? 'Respond to urgent requests from customers nearby' : 'Get immediate help for urgent service needs'}
            </p>
          </div>
          <div className="header-actions">
            <button className="btn btn-danger btn-sos" onClick={triggerSOS} title="Send SOS to emergency contacts">
              <FiShield /> SOS
            </button>
            {!isPro && (
              <button className="btn btn-primary" onClick={() => setShowForm(!showForm)}>
                <FiAlertTriangle /> {showForm ? 'Cancel' : 'Request Emergency Help'}
              </button>
            )}
          </div>
        </div>

        {message && <div className={`alert ${message.includes('Error') ? 'alert--error' : 'alert--success'}`}>{message}</div>}

        {/* Emergency Request Form (Customer) */}
        {showForm && !isPro && (
          <div className="emergency-form-card">
            <h3>🚨 Describe Your Emergency</h3>
            <form onSubmit={submitEmergency}>
              <div className="form-group">
                <label>Service Category</label>
                <select
                  value={form.category_id}
                  onChange={e => setForm(f => ({ ...f, category_id: e.target.value }))}
                  className="form-input"
                >
                  <option value="">Select service needed</option>
                  {categories.map(c => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </div>
              <div className="form-group">
                <label>What's the emergency? *</label>
                <textarea
                  value={form.description}
                  onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                  placeholder="Describe what happened and what help you need..."
                  className="form-input"
                  rows={3}
                  required
                />
              </div>
              <div className="form-group">
                <label>Your Address</label>
                <input
                  type="text"
                  value={form.location_address}
                  onChange={e => setForm(f => ({ ...f, location_address: e.target.value }))}
                  placeholder="Where do you need help?"
                  className="form-input"
                />
              </div>
              {location && (
                <p className="location-note"><FiMapPin size={12} /> Location detected automatically</p>
              )}
              <button type="submit" className="btn btn-danger" disabled={submitting || !form.description}>
                {submitting ? 'Sending...' : '🚨 Send Emergency Request'}
              </button>
            </form>
          </div>
        )}

        {/* Emergency List */}
        <div className="emergency-list">
          {emergencies.length > 0 ? (
            emergencies.map(em => (
              <div key={em.id} className={`emergency-card emergency-card--${em.status}`}>
                <div className="emergency-header">
                  <span className={`emergency-status emergency-status--${em.status}`}>
                    {em.status === 'active' ? '🔴 Active' : em.status === 'assigned' ? '🟡 Assigned' : '✅ Resolved'}
                  </span>
                  <span className="emergency-time">
                    <FiClock size={12} /> {new Date(em.created_at).toLocaleString()}
                  </span>
                </div>
                <p className="emergency-desc">{em.description}</p>
                {em.location_address && (
                  <p className="emergency-location"><FiMapPin size={12} /> {em.location_address}</p>
                )}
                {em.customer_name && <p className="emergency-customer">Customer: {em.customer_name}</p>}
                {em.professional_name && <p className="emergency-pro">Assigned to: {em.professional_name}</p>}
                {em.distance_km && <p className="emergency-distance">{Number(em.distance_km).toFixed(1)} km away</p>}

                {isPro && em.status === 'active' && (
                  <button className="btn btn-primary btn-sm" onClick={() => acceptEmergency(em.id)}>
                    <FiCheck /> Accept & Respond
                  </button>
                )}
                {isPro && em.status === 'assigned' && (
                  <button className="btn btn-success btn-sm" onClick={() => resolveEmergency(em.id)}>
                    <FiCheck /> Mark Resolved
                  </button>
                )}
              </div>
            ))
          ) : (
            <div className="empty-state">
              <FiAlertTriangle size={40} />
              <p>{isPro ? 'No emergency requests nearby.' : 'No active emergency requests.'}</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default Emergency;
