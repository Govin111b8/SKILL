import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiCheck, FiAlertCircle, FiX, FiEye, FiSave, FiPlus } from 'react-icons/fi';
import { get, put, post, del } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { Skeleton } from '../components/Skeleton';
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
  { value: 'centered', label: 'Centered', icon: '⬛' },
  { value: 'left', label: 'Left Aligned', icon: '◀️' },
  { value: 'split', label: 'Split View', icon: '⏸️' },
  { value: 'hero', label: 'Full Hero', icon: '🖼️' },
];

function StorefrontSetup() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [activeSection, setActiveSection] = useState('basic');
  const [professionalId, setProfessionalId] = useState(null);
  const [toast, setToast] = useState(null);
  const [errors, setErrors] = useState({});
  const [dirty, setDirty] = useState(false);
  const toastTimer = useRef(null);

  const [form, setForm] = useState({
    announcement: '', tagline: '', whatsapp_number: '', instagram_handle: '',
    website_url: '', accent_color: '#6366F1', show_rating: true,
    return_policy: '', operating_hours: '', operating_days: '', intro_video_url: '',
  });
  const [theme, setTheme] = useState({
    theme_name: 'modern', primary_color: '#6366F1', accent_color: '#8B5CF6',
    layout: 'centered', custom_intro: '',
  });
  const [packages, setPackages] = useState([]);
  const [newPackage, setNewPackage] = useState({ name: '', tier: 'standard', price: '', description: '', features: '' });
  const [services, setServices] = useState([]);
  const [newService, setNewService] = useState({ name: '', description: '', price_min: '', price_max: '', duration_minutes: '', category_id: '' });
  const [serviceCategories, setServiceCategories] = useState([]);

  useEffect(() => { loadProfile(); }, []);

  useEffect(() => {
    if (toast) {
      clearTimeout(toastTimer.current);
      toastTimer.current = setTimeout(() => setToast(null), 4000);
    }
    return () => clearTimeout(toastTimer.current);
  }, [toast]);

  useEffect(() => {
    function handleBeforeUnload(e) {
      if (dirty) { e.preventDefault(); e.returnValue = ''; }
    }
    window.addEventListener('beforeunload', handleBeforeUnload);
    return () => window.removeEventListener('beforeunload', handleBeforeUnload);
  }, [dirty]);

  function showToast(type, text) { setToast({ type, text }); }

  async function loadProfile() {
    try {
      const res = await get('/professionals/me');
      const data = res.data || res;
      setProfessionalId(data.id);
      setForm({
        announcement: data.announcement || '', tagline: data.tagline || '',
        whatsapp_number: data.whatsapp_number || '', instagram_handle: data.instagram_handle || '',
        website_url: data.website_url || '', accent_color: data.accent_color || '#6366F1',
        show_rating: data.show_rating !== false, return_policy: data.return_policy || '',
        operating_hours: data.operating_hours || '', operating_days: data.operating_days || '',
        intro_video_url: data.intro_video_url || '',
      });
      try {
        const storefrontRes = await get(`/storefront/${data.id}`);
        const sf = storefrontRes.data || storefrontRes;
        if (sf.theme) {
          setTheme({
            theme_name: sf.theme.theme_name || 'modern', primary_color: sf.theme.primary_color || '#6366F1',
            accent_color: sf.theme.accent_color || '#8B5CF6', layout: sf.theme.layout || 'centered',
            custom_intro: sf.theme.custom_intro || '',
          });
        }
        if (sf.packages?.length) setPackages(sf.packages);
      } catch {}
      // Load services
      try {
        const svcRes = await get(`/services/${data.id}`);
        setServices((svcRes.data || svcRes) || []);
      } catch {}
      // Load categories for service dropdown
      try {
        const catRes = await get('/categories');
        const cats = catRes.data || catRes || [];
        const flat = [];
        cats.forEach(c => {
          flat.push({ id: c.id, name: c.name });
          if (c.children) c.children.forEach(ch => flat.push({ id: ch.id, name: `${c.name} > ${ch.name}` }));
        });
        setServiceCategories(flat);
      } catch {}
    } catch { showToast('error', 'Failed to load profile data'); }
    finally { setLoading(false); }
  }

  function validateForm() {
    const newErrors = {};
    if (form.whatsapp_number && !/^\+?[0-9]{10,15}$/.test(form.whatsapp_number.replace(/\s/g, '')))
      newErrors.whatsapp_number = 'Enter a valid phone number';
    if (form.website_url && !/^https?:\/\/.+/.test(form.website_url))
      newErrors.website_url = 'Enter a valid URL starting with http://';
    if (form.intro_video_url && !/^https?:\/\/.+/.test(form.intro_video_url))
      newErrors.intro_video_url = 'Enter a valid URL starting with http://';
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }

  function handleChange(e) {
    const { name, value, type, checked } = e.target;
    setForm(prev => ({ ...prev, [name]: type === 'checkbox' ? checked : value }));
    setDirty(true);
    if (errors[name]) setErrors(prev => ({ ...prev, [name]: undefined }));
  }

  function handleThemeChange(e) {
    const { name, value } = e.target;
    setTheme(prev => ({ ...prev, [name]: value }));
    setDirty(true);
  }

  async function handleSubmit(e) {
    e.preventDefault();
    if (!professionalId) return;
    if (!validateForm()) { showToast('error', 'Please fix the errors before saving'); return; }
    setSaving(true);
    try {
      await put(`/storefront/${professionalId}`, form);
      try { await put(`/storefront/${professionalId}/theme`, theme); }
      catch { showToast('warning', 'Storefront updated, but theme failed'); setSaving(false); return; }
      setSaved(true); setDirty(false);
      setTimeout(() => setSaved(false), 2500);
      showToast('success', 'Storefront updated successfully! ✨');
    } catch (err) { showToast('error', err.message || 'Failed to update'); }
    finally { setSaving(false); }
  }

  async function addPackageHandler() {
    if (!newPackage.name.trim() || !professionalId) return;
    try {
      const features = newPackage.features ? newPackage.features.split(',').map(f => f.trim()).filter(Boolean) : [];
      const res = await post(`/storefront/${professionalId}/packages`, { ...newPackage, price: newPackage.price ? parseFloat(newPackage.price) : undefined, features });
      setPackages(prev => [...prev, res.data]);
      setNewPackage({ name: '', tier: 'standard', price: '', description: '', features: '' });
      showToast('success', 'Package added! 📦');
    } catch (err) { showToast('error', err.message || 'Failed to add package'); }
  }

  async function removePackage(packageId) {
    try {
      await del(`/storefront/${professionalId}/packages/${packageId}`);
      setPackages(prev => prev.filter(p => p.id !== packageId));
      showToast('success', 'Package removed');
    } catch { showToast('error', 'Failed to remove package'); }
  }

  async function addServiceHandler() {
    if (!newService.name.trim() || !professionalId) return;
    try {
      const body = {
        name: newService.name.trim(),
        description: newService.description.trim() || undefined,
        price_min: newService.price_min ? parseFloat(newService.price_min) : undefined,
        price_max: newService.price_max ? parseFloat(newService.price_max) : undefined,
        duration_minutes: newService.duration_minutes ? parseInt(newService.duration_minutes) : undefined,
        category_id: newService.category_id ? parseInt(newService.category_id) : undefined,
      };
      const res = await post(`/services/${professionalId}`, body);
      setServices(prev => [...prev, res.data || res]);
      setNewService({ name: '', description: '', price_min: '', price_max: '', duration_minutes: '', category_id: '' });
      showToast('success', 'Service added! 🛠️');
    } catch (err) { showToast('error', err.message || 'Failed to add service'); }
  }

  async function removeService(serviceId) {
    try {
      await del(`/services/item/${serviceId}`);
      setServices(prev => prev.filter(s => s.id !== serviceId));
      showToast('success', 'Service removed');
    } catch { showToast('error', 'Failed to remove service'); }
  }

  const tabs = [
    { key: 'basic', label: '📝 Basic Info' },
    { key: 'services', label: '🛠️ Services' },
    { key: 'theme', label: '🎨 Theme' },
    { key: 'packages', label: '📦 Packages' },
    { key: 'social', label: '🔗 Social' },
  ];

  if (loading) return (
    <div className="storefront-setup">
      <Skeleton width="200px" height="1.75rem" />
      <div style={{ marginTop: '0.5rem' }}><Skeleton width="300px" height="1rem" /></div>
      <div style={{ display: 'flex', gap: '0.5rem', marginTop: '1.5rem' }}>
        <Skeleton width="100px" height="36px" borderRadius="20px" />
        <Skeleton width="100px" height="36px" borderRadius="20px" />
        <Skeleton width="100px" height="36px" borderRadius="20px" />
      </div>
      <div style={{ marginTop: '1.5rem' }}><Skeleton count={6} height="48px" borderRadius="10px" /></div>
    </div>
  );

  return (
    <div className="storefront-setup">
      {toast && (
        <div className={`setup-toast setup-toast--${toast.type}`} role="alert">
          {toast.type === 'success' && <FiCheck size={16} />}
          {toast.type === 'error' && <FiAlertCircle size={16} />}
          {toast.type === 'warning' && <FiAlertCircle size={16} />}
          <span>{toast.text}</span>
          <button onClick={() => setToast(null)} className="setup-toast__close" aria-label="Dismiss"><FiX size={14} /></button>
        </div>
      )}

      <div className="setup-header">
        <div>
          <h1>🏪 Your Storefront</h1>
          <p className="setup-subtitle">Customize your professional business page</p>
        </div>
        <div className="setup-header__actions">
          {dirty && <span className="setup-dirty-badge"><span className="setup-dirty-dot" /> Unsaved changes</span>}
          {professionalId && (
            <button className="preview-btn" onClick={() => navigate(`/professionals/${professionalId}/storefront`)} aria-label="Preview storefront">
              <FiEye size={16} /> Preview
            </button>
          )}
        </div>
      </div>

      <div className="setup-tabs" role="tablist" aria-label="Storefront sections">
        {tabs.map(tab => (
          <button key={tab.key} className={`setup-tab ${activeSection === tab.key ? 'active' : ''}`}
            onClick={() => setActiveSection(tab.key)} role="tab" aria-selected={activeSection === tab.key}>{tab.label}</button>
        ))}
      </div>

      <form onSubmit={handleSubmit} className="setup-form">
        {activeSection === 'basic' && (
          <div role="tabpanel" className="setup-panel">
            <div className="form-group">
              <label htmlFor="tagline">Tagline</label>
              <input id="tagline" type="text" name="tagline" value={form.tagline} onChange={handleChange} placeholder="e.g. Making homes beautiful since 2015" maxLength={200} />
              <span className="form-hint">Short tagline for your storefront hero ({form.tagline.length}/200)</span>
            </div>
            <div className="form-group">
              <label htmlFor="announcement">Announcement</label>
              <input id="announcement" type="text" name="announcement" value={form.announcement} onChange={handleChange} placeholder="e.g. 20% off this week!" maxLength={500} />
              <span className="form-hint">Banner on your storefront ({form.announcement.length}/500)</span>
            </div>
            <div className="form-group">
              <label htmlFor="intro_video_url">Intro Video URL</label>
              <input id="intro_video_url" type="url" name="intro_video_url" value={form.intro_video_url} onChange={handleChange}
                placeholder="https://example.com/intro.mp4" className={errors.intro_video_url ? 'input-error' : ''} aria-invalid={!!errors.intro_video_url} />
              {errors.intro_video_url && <span className="form-error" role="alert">{errors.intro_video_url}</span>}
              <span className="form-hint">15-30 second introduction video (auto-plays muted)</span>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label htmlFor="operating_hours">Operating Hours</label>
                <input id="operating_hours" type="text" name="operating_hours" value={form.operating_hours} onChange={handleChange} placeholder="e.g. 9 AM - 6 PM" />
              </div>
              <div className="form-group">
                <label htmlFor="operating_days">Operating Days</label>
                <input id="operating_days" type="text" name="operating_days" value={form.operating_days} onChange={handleChange} placeholder="e.g. Mon - Sat" />
              </div>
            </div>
            <div className="form-group">
              <label htmlFor="return_policy">Service Guarantee / Return Policy</label>
              <textarea id="return_policy" name="return_policy" value={form.return_policy} onChange={handleChange} rows={4} maxLength={2000} placeholder="Describe your service guarantee..." />
              <span className="form-hint">{form.return_policy.length}/2000 characters</span>
            </div>
            <div className="form-group checkbox-group">
              <label><input type="checkbox" name="show_rating" checked={form.show_rating} onChange={handleChange} /><span className="checkbox-label">Show Rating on Storefront</span></label>
            </div>
          </div>
        )}

        {activeSection === 'services' && (
          <div role="tabpanel" className="setup-panel">
            <h3 style={{ marginBottom: '0.5rem' }}>Your Services</h3>
            <p className="form-hint" style={{ marginBottom: '1rem' }}>Add specific services you offer with pricing and estimated duration. Customers will see these on your storefront and can book directly.</p>

            {services.length > 0 && (
              <div className="packages-list" style={{ marginBottom: '1.5rem' }}>
                {services.map(svc => (
                  <div key={svc.id} className="package-card">
                    <div className="package-header">
                      <h4>{svc.name}</h4>
                      <button type="button" onClick={() => removeService(svc.id)} className="btn btn-sm btn-outline" aria-label={`Remove ${svc.name}`}>
                        <FiX size={14} />
                      </button>
                    </div>
                    {svc.description && <p className="form-hint">{svc.description}</p>}
                    <div style={{ display: 'flex', gap: '1rem', marginTop: '0.5rem', fontSize: '0.875rem', color: 'var(--text-secondary, #666)' }}>
                      {(svc.price_min || svc.price_max) && (
                        <span>💰 ₹{svc.price_min || '—'} – ₹{svc.price_max || '—'}</span>
                      )}
                      {svc.duration_minutes && <span>⏱️ {svc.duration_minutes} min</span>}
                      {svc.category_name && <span>📂 {svc.category_name}</span>}
                    </div>
                  </div>
                ))}
              </div>
            )}

            <div className="new-package-form" style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
              <div className="form-group">
                <label htmlFor="svc_name">Service Name *</label>
                <input id="svc_name" type="text" value={newService.name} onChange={e => setNewService(p => ({ ...p, name: e.target.value }))} placeholder="e.g. AC Repair, Full Home Cleaning" maxLength={200} />
              </div>
              <div className="form-group">
                <label htmlFor="svc_desc">Description</label>
                <input id="svc_desc" type="text" value={newService.description} onChange={e => setNewService(p => ({ ...p, description: e.target.value }))} placeholder="Brief description of what's included" maxLength={500} />
              </div>
              <div className="form-row">
                <div className="form-group">
                  <label htmlFor="svc_price_min">Min Price (₹)</label>
                  <input id="svc_price_min" type="number" min="0" step="0.01" value={newService.price_min} onChange={e => setNewService(p => ({ ...p, price_min: e.target.value }))} placeholder="e.g. 200" />
                </div>
                <div className="form-group">
                  <label htmlFor="svc_price_max">Max Price (₹)</label>
                  <input id="svc_price_max" type="number" min="0" step="0.01" value={newService.price_max} onChange={e => setNewService(p => ({ ...p, price_max: e.target.value }))} placeholder="e.g. 500" />
                </div>
              </div>
              <div className="form-row">
                <div className="form-group">
                  <label htmlFor="svc_duration">Duration (minutes)</label>
                  <input id="svc_duration" type="number" min="1" value={newService.duration_minutes} onChange={e => setNewService(p => ({ ...p, duration_minutes: e.target.value }))} placeholder="e.g. 60" />
                </div>
                <div className="form-group">
                  <label htmlFor="svc_category">Category</label>
                  <select id="svc_category" value={newService.category_id} onChange={e => setNewService(p => ({ ...p, category_id: e.target.value }))}>
                    <option value="">Select category</option>
                    {serviceCategories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                  </select>
                </div>
              </div>
              <button type="button" className="btn btn-primary" onClick={addServiceHandler} disabled={!newService.name.trim()}>
                <FiPlus size={16} /> Add Service
              </button>
            </div>
          </div>
        )}

        {activeSection === 'theme' && (
          <div role="tabpanel" className="setup-panel">
            <div className="form-group">
              <label>Theme Style</label>
              <div className="theme-grid">
                {THEME_OPTIONS.map(t => (
                  <label key={t.value} className={`theme-option ${theme.theme_name === t.value ? 'selected' : ''}`}>
                    <input type="radio" name="theme_name" value={t.value} checked={theme.theme_name === t.value} onChange={handleThemeChange} aria-label={`${t.label} theme`} />
                    <span className="theme-label">{t.label}</span>
                    <span className="theme-desc">{t.desc}</span>
                    {theme.theme_name === t.value && <FiCheck className="theme-check" size={16} />}
                  </label>
                ))}
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label htmlFor="primary_color">Primary Color</label>
                <div className="color-input">
                  <input id="primary_color" type="color" name="primary_color" value={theme.primary_color} onChange={handleThemeChange} />
                  <input type="text" value={theme.primary_color} onChange={e => { setTheme(prev => ({ ...prev, primary_color: e.target.value })); setDirty(true); }} pattern="^#[0-9A-Fa-f]{6}$" aria-label="Primary color hex" />
                  <span className="color-preview" style={{ background: theme.primary_color }} aria-hidden="true" />
                </div>
              </div>
              <div className="form-group">
                <label htmlFor="accent_color_theme">Accent Color</label>
                <div className="color-input">
                  <input id="accent_color_theme" type="color" name="accent_color" value={theme.accent_color} onChange={handleThemeChange} />
                  <input type="text" value={theme.accent_color} onChange={e => { setTheme(prev => ({ ...prev, accent_color: e.target.value })); setDirty(true); }} pattern="^#[0-9A-Fa-f]{6}$" aria-label="Accent color hex" />
                  <span className="color-preview" style={{ background: theme.accent_color }} aria-hidden="true" />
                </div>
              </div>
            </div>
            <div className="form-group">
              <label>Layout</label>
              <div className="layout-options">
                {LAYOUT_OPTIONS.map(l => (
                  <label key={l.value} className={`layout-option ${theme.layout === l.value ? 'selected' : ''}`}>
                    <input type="radio" name="layout" value={l.value} checked={theme.layout === l.value} onChange={handleThemeChange} aria-label={`${l.label} layout`} />
                    <span className="layout-icon">{l.icon}</span><span>{l.label}</span>
                    {theme.layout === l.value && <FiCheck className="layout-check" size={14} />}
                  </label>
                ))}
              </div>
            </div>
            <div className="form-group">
              <label htmlFor="custom_intro">About My Business</label>
              <textarea id="custom_intro" name="custom_intro" value={theme.custom_intro} onChange={handleThemeChange} rows={5} maxLength={2000} placeholder="Tell your story — what makes your business special?" />
              <span className="form-hint">{theme.custom_intro.length}/2000 — Appears in the Services tab</span>
            </div>
          </div>
        )}

        {activeSection === 'packages' && (
          <div role="tabpanel" className="setup-panel">
            <p className="section-desc">Create tiered service packages to help customers choose the right option.</p>
            {packages.length === 0 && (
              <div className="packages-empty"><span className="packages-empty__icon">📦</span><p>No packages yet</p><span>Add your first service package below</span></div>
            )}
            {packages.map(pkg => (
              <div key={pkg.id} className="package-edit-card">
                <div className="package-edit-header">
                  <strong>{pkg.name}</strong>
                  <span className="package-edit-tier">{pkg.tier}</span>
                  {pkg.price && <span className="package-edit-price">₹{Number(pkg.price).toLocaleString()}</span>}
                  <button type="button" className="package-remove" onClick={() => removePackage(pkg.id)} aria-label={`Remove ${pkg.name}`}><FiX size={14} /></button>
                </div>
                {pkg.description && <p className="package-edit-desc">{pkg.description}</p>}
                {pkg.features?.length > 0 && (
                  <div className="package-edit-features">
                    {(Array.isArray(pkg.features) ? pkg.features : []).map((f, i) => <span key={i} className="package-feature-tag">✓ {f}</span>)}
                  </div>
                )}
              </div>
            ))}
            <div className="add-package-form">
              <h4>➕ Add Package</h4>
              <div className="form-row">
                <div className="form-group"><label htmlFor="pkg-name">Name</label><input id="pkg-name" type="text" value={newPackage.name} onChange={e => setNewPackage(p => ({ ...p, name: e.target.value }))} placeholder="e.g. Deep Home Cleaning" /></div>
                <div className="form-group"><label htmlFor="pkg-tier">Tier</label><select id="pkg-tier" value={newPackage.tier} onChange={e => setNewPackage(p => ({ ...p, tier: e.target.value }))}><option value="basic">🥉 Basic</option><option value="standard">🥈 Standard</option><option value="premium">🥇 Premium</option></select></div>
              </div>
              <div className="form-group"><label htmlFor="pkg-price">Price (₹)</label><input id="pkg-price" type="number" min="0" value={newPackage.price} onChange={e => setNewPackage(p => ({ ...p, price: e.target.value }))} placeholder="e.g. 2500" /></div>
              <div className="form-group"><label htmlFor="pkg-desc">Description</label><textarea id="pkg-desc" value={newPackage.description} onChange={e => setNewPackage(p => ({ ...p, description: e.target.value }))} rows={2} placeholder="What's included?" /></div>
              <div className="form-group"><label htmlFor="pkg-features">Features (comma-separated)</label><input id="pkg-features" type="text" value={newPackage.features} onChange={e => setNewPackage(p => ({ ...p, features: e.target.value }))} placeholder="e.g. 3 rooms, Deep scrub, Disinfection" /></div>
              <button type="button" className="add-package-btn" onClick={addPackageHandler} disabled={!newPackage.name.trim()}><FiPlus size={14} /> Add Package</button>
            </div>
          </div>
        )}

        {activeSection === 'social' && (
          <div role="tabpanel" className="setup-panel">
            <div className="form-row">
              <div className="form-group">
                <label htmlFor="whatsapp_number">WhatsApp Number</label>
                <input id="whatsapp_number" type="tel" name="whatsapp_number" value={form.whatsapp_number} onChange={handleChange} placeholder="+91XXXXXXXXXX"
                  className={errors.whatsapp_number ? 'input-error' : ''} aria-invalid={!!errors.whatsapp_number} />
                {errors.whatsapp_number && <span className="form-error" role="alert">{errors.whatsapp_number}</span>}
              </div>
              <div className="form-group"><label htmlFor="instagram_handle">Instagram Handle</label><input id="instagram_handle" type="text" name="instagram_handle" value={form.instagram_handle} onChange={handleChange} placeholder="yourhandle" /></div>
            </div>
            <div className="form-group">
              <label htmlFor="website_url">Website URL</label>
              <input id="website_url" type="url" name="website_url" value={form.website_url} onChange={handleChange} placeholder="https://example.com"
                className={errors.website_url ? 'input-error' : ''} aria-invalid={!!errors.website_url} />
              {errors.website_url && <span className="form-error" role="alert">{errors.website_url}</span>}
            </div>
          </div>
        )}

        <button type="submit" className={`save-btn ${saved ? 'save-btn--saved' : ''}`} disabled={saving}>
          {saving ? <><span className="save-btn__spinner" /> Saving...</> : saved ? <><FiCheck size={18} /> Saved!</> : <><FiSave size={18} /> Save Storefront</>}
        </button>
      </form>
    </div>
  );
}

export default StorefrontSetup;
