import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { get, put } from '../api/client';
import { useAuth } from '../context/AuthContext';
import LoadingSpinner from '../components/LoadingSpinner';
import './StorefrontSetup.css';

function StorefrontSetup() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [professionalId, setProfessionalId] = useState(null);
  const [form, setForm] = useState({
    announcement: '',
    whatsapp_number: '',
    instagram_handle: '',
    website_url: '',
    accent_color: '#6366F1',
    show_rating: true,
    return_policy: '',
    operating_hours: '',
    operating_days: '',
  });

  useEffect(() => {
    loadProfile();
  }, []);

  async function loadProfile() {
    try {
      const res = await get('/professionals/me');
      const data = res.data || res;
      setProfessionalId(data.id);
      setForm({
        announcement: data.announcement || '',
        whatsapp_number: data.whatsapp_number || '',
        instagram_handle: data.instagram_handle || '',
        website_url: data.website_url || '',
        accent_color: data.accent_color || '#6366F1',
        show_rating: data.show_rating !== false,
        return_policy: data.return_policy || '',
        operating_hours: data.operating_hours || '',
        operating_days: data.operating_days || '',
      });
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }

  function handleChange(e) {
    const { name, value, type, checked } = e.target;
    setForm(prev => ({ ...prev, [name]: type === 'checkbox' ? checked : value }));
  }

  async function handleSubmit(e) {
    e.preventDefault();
    if (!professionalId) return;
    setSaving(true);
    try {
      await put(`/storefront/${professionalId}`, form);
      alert('Storefront updated successfully!');
    } catch (err) {
      alert(err.message || 'Failed to update');
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <LoadingSpinner />;

  return (
    <div className="storefront-setup">
      <div className="setup-header">
        <h1>Setup Your Storefront</h1>
        {professionalId && (
          <button className="preview-btn" onClick={() => navigate(`/professionals/${professionalId}/storefront`)}>
            Preview
          </button>
        )}
      </div>

      <form onSubmit={handleSubmit} className="setup-form">
        <div className="form-group">
          <label>Announcement</label>
          <input type="text" name="announcement" value={form.announcement} onChange={handleChange} placeholder="e.g. 20% off this week!" maxLength={500} />
        </div>

        <div className="form-row">
          <div className="form-group">
            <label>Operating Hours</label>
            <input type="text" name="operating_hours" value={form.operating_hours} onChange={handleChange} placeholder="e.g. 9 AM - 6 PM" />
          </div>
          <div className="form-group">
            <label>Operating Days</label>
            <input type="text" name="operating_days" value={form.operating_days} onChange={handleChange} placeholder="e.g. Mon - Sat" />
          </div>
        </div>

        <div className="form-row">
          <div className="form-group">
            <label>WhatsApp Number</label>
            <input type="tel" name="whatsapp_number" value={form.whatsapp_number} onChange={handleChange} placeholder="+91XXXXXXXXXX" />
          </div>
          <div className="form-group">
            <label>Instagram Handle</label>
            <input type="text" name="instagram_handle" value={form.instagram_handle} onChange={handleChange} placeholder="yourhandle" />
          </div>
        </div>

        <div className="form-group">
          <label>Website URL</label>
          <input type="url" name="website_url" value={form.website_url} onChange={handleChange} placeholder="https://example.com" />
        </div>

        <div className="form-row">
          <div className="form-group">
            <label>Accent Color</label>
            <div className="color-input">
              <input type="color" name="accent_color" value={form.accent_color} onChange={handleChange} />
              <input type="text" value={form.accent_color} onChange={e => setForm(prev => ({ ...prev, accent_color: e.target.value }))} pattern="^#[0-9A-Fa-f]{6}$" />
            </div>
          </div>
          <div className="form-group checkbox-group">
            <label>
              <input type="checkbox" name="show_rating" checked={form.show_rating} onChange={handleChange} />
              Show Rating on Storefront
            </label>
          </div>
        </div>

        <div className="form-group">
          <label>Service Guarantee / Return Policy</label>
          <textarea name="return_policy" value={form.return_policy} onChange={handleChange} rows={4} maxLength={2000} placeholder="Describe your service guarantee..." />
        </div>

        <button type="submit" className="save-btn" disabled={saving}>
          {saving ? 'Saving...' : 'Save Storefront'}
        </button>
      </form>
    </div>
  );
}

export default StorefrontSetup;
