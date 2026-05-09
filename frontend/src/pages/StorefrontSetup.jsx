import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { get, put, post, del } from '../api/client';
import { useAuth } from '../context/AuthContext';
import LoadingSpinner from '../components/LoadingSpinner';
import './StorefrontSetup.css';

const THEME_OPTIONS = [
  { value: 'modern', label: '🎨 Modern', desc: 'Clean and contemporary' },
  { value: 'classic', label: '📜 Classic', desc: 'Timeless and elegant' },
  { value: 'bold', label: '🔥 Bold', desc: 'Eye-catching and vibrant' },
  { value: 'minimal', label: '✨ Minimal', desc: 'Simple and focused' },
  { value: 'elegant', label: '💎 Elegant', desc: 'Sophisticated and refined' },
  { value: 'vibrant', label: '🌈 Vibrant', desc: 'Colorful and energetic' },
  { value: 'dark', label: '🌙 Dark', desc: 'Sleek dark mode' },
  { value: 'professional', label: '👔 Professional', desc: 'Business-focused' },
];

const LAYOUT_OPTIONS = [
  { value: 'centered', label: 'Centered' },
  { value: 'left', label: 'Left Aligned' },
  { value: 'split', label: 'Split View' },
  { value: 'hero', label: 'Full Hero' },
];

function StorefrontSetup() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [activeSection, setActiveSection] = useState('basic');
  const [professionalId, setProfessionalId] = useState(null);
  const [form, setForm] = useState({
    announcement: '',
    tagline: '',
    whatsapp_number: '',
    instagram_handle: '',
    website_url: '',
    accent_color: '#6366F1',
    show_rating: true,
    return_policy: '',
    operating_hours: '',
    operating_days: '',
    intro_video_url: '',
  });
  const [theme, setTheme] = useState({
    theme_name: 'modern',
    primary_color: '#6366F1',
    accent_color: '#8B5CF6',
    layout: 'centered',
    custom_intro: '',
  });
  const [packages, setPackages] = useState([]);
  const [newPackage, setNewPackage] = useState({ name: '', tier: 'standard', price: '', description: '', features: '' });

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
        tagline: data.tagline || '',
        whatsapp_number: data.whatsapp_number || '',
        instagram_handle: data.instagram_handle || '',
        website_url: data.website_url || '',
        accent_color: data.accent_color || '#6366F1',
        show_rating: data.show_rating !== false,
        return_policy: data.return_policy || '',
        operating_hours: data.operating_hours || '',
        operating_days: data.operating_days || '',
        intro_video_url: data.intro_video_url || '',
      });

      // Load theme
      try {
        const storefrontRes = await get(`/storefront/${data.id}`);
        const sf = storefrontRes.data || storefrontRes;
        if (sf.theme) {
          setTheme({
            theme_name: sf.theme.theme_name || 'modern',
            primary_color: sf.theme.primary_color || '#6366F1',
            accent_color: sf.theme.accent_color || '#8B5CF6',
            layout: sf.theme.layout || 'centered',
            custom_intro: sf.theme.custom_intro || '',
          });
        }
        if (sf.packages?.length) setPackages(sf.packages);
      } catch {}
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

  function handleThemeChange(e) {
    const { name, value } = e.target;
    setTheme(prev => ({ ...prev, [name]: value }));
  }

  async function handleSubmit(e) {
    e.preventDefault();
    if (!professionalId) return;
    setSaving(true);
    try {
      await put(`/storefront/${professionalId}`, form);

      // Save theme
      try {
        await put(`/storefront/${professionalId}/theme`, theme);
      } catch (themeErr) {
        alert('Storefront updated, but theme settings failed to save. Please try again.');
        setSaving(false);
        return;
      }

      alert('Storefront updated successfully!');
    } catch (err) {
      alert(err.message || 'Failed to update');
    } finally {
      setSaving(false);
    }
  }

  async function addPackageHandler() {
    if (!newPackage.name.trim() || !professionalId) return;
    try {
      const features = newPackage.features
        ? newPackage.features.split(',').map(f => f.trim()).filter(Boolean)
        : [];
      const res = await post(`/storefront/${professionalId}/packages`, {
        ...newPackage,
        price: newPackage.price ? parseFloat(newPackage.price) : undefined,
        features,
      });
      setPackages(prev => [...prev, res.data]);
      setNewPackage({ name: '', tier: 'standard', price: '', description: '', features: '' });
    } catch (err) {
      alert(err.message || 'Failed to add package');
    }
  }

  async function removePackage(packageId) {
    try {
      await del(`/storefront/${professionalId}/packages/${packageId}`);
      setPackages(prev => prev.filter(p => p.id !== packageId));
    } catch {}
  }

  if (loading) return <LoadingSpinner />;

  return (
    <div className="storefront-setup">
      <div className="setup-header">
        <div>
          <h1>🏪 Your Storefront</h1>
          <p className="setup-subtitle">Customize your professional business page</p>
        </div>
        {professionalId && (
          <button className="preview-btn" onClick={() => navigate(`/professionals/${professionalId}/storefront`)}>
            👁️ Preview
          </button>
        )}
      </div>

      {/* Section Tabs */}
      <div className="setup-tabs">
        {[
          { key: 'basic', label: '📝 Basic Info' },
          { key: 'theme', label: '🎨 Theme' },
          { key: 'packages', label: '📦 Packages' },
          { key: 'social', label: '🔗 Social' },
        ].map(tab => (
          <button
            key={tab.key}
            className={`setup-tab ${activeSection === tab.key ? 'active' : ''}`}
            onClick={() => setActiveSection(tab.key)}
          >
            {tab.label}
          </button>
        ))}
      </div>

      <form onSubmit={handleSubmit} className="setup-form">
        {/* Basic Info Section */}
        {activeSection === 'basic' && (
          <>
            <div className="form-group">
              <label>Tagline</label>
              <input type="text" name="tagline" value={form.tagline} onChange={handleChange} placeholder="e.g. Making homes beautiful since 2015" maxLength={200} />
              <span className="form-hint">Short tagline that appears on your storefront hero</span>
            </div>

            <div className="form-group">
              <label>Announcement</label>
              <input type="text" name="announcement" value={form.announcement} onChange={handleChange} placeholder="e.g. 20% off this week!" maxLength={500} />
            </div>

            <div className="form-group">
              <label>Intro Video URL</label>
              <input type="url" name="intro_video_url" value={form.intro_video_url} onChange={handleChange} placeholder="https://example.com/intro.mp4" />
              <span className="form-hint">15-30 second introduction video (auto-plays muted)</span>
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

            <div className="form-group">
              <label>Service Guarantee / Return Policy</label>
              <textarea name="return_policy" value={form.return_policy} onChange={handleChange} rows={4} maxLength={2000} placeholder="Describe your service guarantee..." />
            </div>

            <div className="form-group checkbox-group">
              <label>
                <input type="checkbox" name="show_rating" checked={form.show_rating} onChange={handleChange} />
                Show Rating on Storefront
              </label>
            </div>
          </>
        )}

        {/* Theme Section */}
        {activeSection === 'theme' && (
          <>
            <div className="form-group">
              <label>Theme Style</label>
              <div className="theme-grid">
                {THEME_OPTIONS.map(t => (
                  <label
                    key={t.value}
                    className={`theme-option ${theme.theme_name === t.value ? 'selected' : ''}`}
                  >
                    <input
                      type="radio" name="theme_name"
                      value={t.value} checked={theme.theme_name === t.value}
                      onChange={handleThemeChange}
                    />
                    <span className="theme-label">{t.label}</span>
                    <span className="theme-desc">{t.desc}</span>
                  </label>
                ))}
              </div>
            </div>

            <div className="form-row">
              <div className="form-group">
                <label>Primary Color</label>
                <div className="color-input">
                  <input type="color" name="primary_color" value={theme.primary_color} onChange={handleThemeChange} />
                  <input type="text" value={theme.primary_color} onChange={e => setTheme(prev => ({ ...prev, primary_color: e.target.value }))} pattern="^#[0-9A-Fa-f]{6}$" />
                </div>
              </div>
              <div className="form-group">
                <label>Accent Color</label>
                <div className="color-input">
                  <input type="color" name="accent_color" value={theme.accent_color} onChange={handleThemeChange} />
                  <input type="text" value={theme.accent_color} onChange={e => setTheme(prev => ({ ...prev, accent_color: e.target.value }))} pattern="^#[0-9A-Fa-f]{6}$" />
                </div>
              </div>
            </div>

            <div className="form-group">
              <label>Layout</label>
              <div className="layout-options">
                {LAYOUT_OPTIONS.map(l => (
                  <label key={l.value} className={`layout-option ${theme.layout === l.value ? 'selected' : ''}`}>
                    <input type="radio" name="layout" value={l.value} checked={theme.layout === l.value} onChange={handleThemeChange} />
                    {l.label}
                  </label>
                ))}
              </div>
            </div>

            <div className="form-group">
              <label>About My Business</label>
              <textarea
                name="custom_intro" value={theme.custom_intro} onChange={handleThemeChange}
                rows={5} maxLength={2000}
                placeholder="Tell your story — what makes your business special?"
              />
              <span className="form-hint">This appears in the Services tab of your storefront</span>
            </div>
          </>
        )}

        {/* Packages Section */}
        {activeSection === 'packages' && (
          <>
            <p className="section-desc">Create tiered service packages (Basic, Standard, Premium) to help customers choose.</p>

            {/* Existing packages */}
            {packages.map(pkg => (
              <div key={pkg.id} className="package-edit-card">
                <div className="package-edit-header">
                  <strong>{pkg.name}</strong>
                  <span className="package-edit-tier">{pkg.tier}</span>
                  {pkg.price && <span className="package-edit-price">₹{Number(pkg.price).toLocaleString()}</span>}
                  <button type="button" className="package-remove" onClick={() => removePackage(pkg.id)}>✕</button>
                </div>
                {pkg.description && <p className="package-edit-desc">{pkg.description}</p>}
              </div>
            ))}

            {/* Add new package */}
            <div className="add-package-form">
              <h4>Add Package</h4>
              <div className="form-row">
                <div className="form-group">
                  <label>Name</label>
                  <input type="text" value={newPackage.name} onChange={e => setNewPackage(p => ({ ...p, name: e.target.value }))} placeholder="e.g. Deep Home Cleaning" />
                </div>
                <div className="form-group">
                  <label>Tier</label>
                  <select value={newPackage.tier} onChange={e => setNewPackage(p => ({ ...p, tier: e.target.value }))}>
                    <option value="basic">Basic</option>
                    <option value="standard">Standard</option>
                    <option value="premium">Premium</option>
                  </select>
                </div>
              </div>
              <div className="form-row">
                <div className="form-group">
                  <label>Price (₹)</label>
                  <input type="number" min="0" value={newPackage.price} onChange={e => setNewPackage(p => ({ ...p, price: e.target.value }))} placeholder="e.g. 2500" />
                </div>
              </div>
              <div className="form-group">
                <label>Description</label>
                <textarea value={newPackage.description} onChange={e => setNewPackage(p => ({ ...p, description: e.target.value }))} rows={2} placeholder="What's included?" />
              </div>
              <div className="form-group">
                <label>Features (comma-separated)</label>
                <input type="text" value={newPackage.features} onChange={e => setNewPackage(p => ({ ...p, features: e.target.value }))} placeholder="e.g. 3 rooms, Deep scrub, Disinfection" />
              </div>
              <button type="button" className="add-package-btn" onClick={addPackageHandler}>+ Add Package</button>
            </div>
          </>
        )}

        {/* Social Section */}
        {activeSection === 'social' && (
          <>
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
          </>
        )}

        <button type="submit" className="save-btn" disabled={saving}>
          {saving ? 'Saving...' : '💾 Save Storefront'}
        </button>
      </form>
    </div>
  );
}

export default StorefrontSetup;
