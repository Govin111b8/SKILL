import { useState, useEffect } from 'react';
import { FiHome, FiPlus, FiEdit2, FiTrash2, FiCheck, FiAlertCircle } from 'react-icons/fi';
import { get, post, put, del } from '../api/client';
import { useAuth } from '../context/AuthContext';
import SEOMeta from '../components/SEOMeta';
import LoadingSpinner from '../components/LoadingSpinner';
import './HomeProfile.css';

const BHK_OPTIONS = ['1 RK', '1 BHK', '2 BHK', '3 BHK', '4 BHK', '5+ BHK', 'Independent House', 'Villa', 'Commercial'];
const APPLIANCE_TYPES = ['AC', 'Water Purifier / RO', 'Geyser', 'Washing Machine', 'Refrigerator', 'Microwave', 'TV', 'Inverter', 'Other'];

function ApplianceRow({ appliance, index, onChange, onRemove }) {
  const set = (k, v) => onChange(index, { ...appliance, [k]: v });
  return (
    <div className="appliance-row">
      <select value={appliance.type || ''} onChange={(e) => set('type', e.target.value)}>
        <option value="">Type</option>
        {APPLIANCE_TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
      </select>
      <input placeholder="Brand (e.g. Daikin)" value={appliance.brand || ''} onChange={(e) => set('brand', e.target.value)} />
      <input placeholder="Model / Capacity" value={appliance.model || ''} onChange={(e) => set('model', e.target.value)} />
      <input type="number" placeholder="Year" min="2000" max={new Date().getFullYear()} value={appliance.year || ''} onChange={(e) => set('year', e.target.value)} />
      <button type="button" className="appliance-remove-btn" onClick={() => onRemove(index)} title="Remove">✕</button>
    </div>
  );
}

function HomeProfileForm({ initial, onSave, onCancel, saving }) {
  const [form, setForm] = useState(initial || {
    nickname: 'My Home', bhk_type: '', area_sqft: '', floor_number: '',
    building_name: '', address_line1: '', address_line2: '',
    locality: '', city: '', pincode: '', state: '',
    appliances: [], notes: '', is_default: false,
  });
  const [appliances, setAppliances] = useState(initial?.appliances || []);

  const set = (k, v) => setForm((f) => ({ ...f, [k]: v }));

  const addAppliance = () => setAppliances((a) => [...a, { type: '', brand: '', model: '', year: '' }]);
  const changeAppliance = (i, val) => setAppliances((a) => a.map((x, idx) => idx === i ? val : x));
  const removeAppliance = (i) => setAppliances((a) => a.filter((_, idx) => idx !== i));

  const handleSubmit = (e) => {
    e.preventDefault();
    onSave({ ...form, appliances: appliances.filter((a) => a.type) });
  };

  return (
    <form className="hp-form" onSubmit={handleSubmit}>
      <div className="hp-form-row">
        <div className="hp-form-group">
          <label>Profile Nickname</label>
          <input value={form.nickname} onChange={(e) => set('nickname', e.target.value)} placeholder="My Home, Office, Parents' Home..." />
        </div>
        <div className="hp-form-group">
          <label>Property Type</label>
          <select value={form.bhk_type} onChange={(e) => set('bhk_type', e.target.value)}>
            <option value="">Select type</option>
            {BHK_OPTIONS.map((b) => <option key={b} value={b}>{b}</option>)}
          </select>
        </div>
      </div>

      <div className="hp-form-row">
        <div className="hp-form-group">
          <label>Area (sq ft)</label>
          <input type="number" min="0" placeholder="e.g. 1200" value={form.area_sqft} onChange={(e) => set('area_sqft', e.target.value)} />
        </div>
        <div className="hp-form-group">
          <label>Floor Number</label>
          <input type="number" placeholder="e.g. 3" value={form.floor_number} onChange={(e) => set('floor_number', e.target.value)} />
        </div>
      </div>

      <div className="hp-form-group">
        <label>Building / Society Name</label>
        <input placeholder="e.g. Prestige Lakeside Habitat" value={form.building_name} onChange={(e) => set('building_name', e.target.value)} />
      </div>

      <div className="hp-form-group">
        <label>Address Line 1 *</label>
        <input required placeholder="Door / Flat number, Street" value={form.address_line1} onChange={(e) => set('address_line1', e.target.value)} />
      </div>

      <div className="hp-form-group">
        <label>Address Line 2</label>
        <input placeholder="Landmark, Colony" value={form.address_line2} onChange={(e) => set('address_line2', e.target.value)} />
      </div>

      <div className="hp-form-row">
        <div className="hp-form-group">
          <label>Locality / Area</label>
          <input placeholder="e.g. Koramangala" value={form.locality} onChange={(e) => set('locality', e.target.value)} />
        </div>
        <div className="hp-form-group">
          <label>City</label>
          <input placeholder="e.g. Bangalore" value={form.city} onChange={(e) => set('city', e.target.value)} />
        </div>
      </div>

      <div className="hp-form-row">
        <div className="hp-form-group">
          <label>Pincode *</label>
          <input required maxLength={6} pattern="\d{6}" placeholder="560001" value={form.pincode} onChange={(e) => set('pincode', e.target.value)} />
        </div>
        <div className="hp-form-group">
          <label>State</label>
          <input placeholder="e.g. Karnataka" value={form.state} onChange={(e) => set('state', e.target.value)} />
        </div>
      </div>

      {/* Appliances */}
      <div className="hp-appliances-section">
        <div className="hp-appliances-header">
          <h4>🔧 Your Appliances</h4>
          <button type="button" className="hp-add-appliance-btn" onClick={addAppliance}>
            <FiPlus size={14} /> Add Appliance
          </button>
        </div>
        <p className="hp-appliances-hint">
          Add your appliances so professionals can come prepared with the right parts and tools.
        </p>
        {appliances.map((a, i) => (
          <ApplianceRow key={i} appliance={a} index={i} onChange={changeAppliance} onRemove={removeAppliance} />
        ))}
      </div>

      <div className="hp-form-group">
        <label>Additional Notes</label>
        <textarea placeholder="Access instructions, parking info, entry code, pets at home..." rows={3} value={form.notes} onChange={(e) => set('notes', e.target.value)} />
      </div>

      <label className="hp-default-check">
        <input type="checkbox" checked={form.is_default} onChange={(e) => set('is_default', e.target.checked)} />
        Set as default home (used for quick bookings)
      </label>

      <div className="hp-form-actions">
        <button type="button" className="hp-cancel-btn" onClick={onCancel}>Cancel</button>
        <button type="submit" className="hp-save-btn" disabled={saving}>
          {saving ? 'Saving...' : <><FiCheck size={15} /> Save Profile</>}
        </button>
      </div>
    </form>
  );
}

function HomeProfileCard({ profile, onEdit, onDelete, onSetDefault }) {
  return (
    <div className={`hp-card ${profile.is_default ? 'hp-card--default' : ''}`}>
      <div className="hp-card-header">
        <div className="hp-card-icon"><FiHome size={20} /></div>
        <div className="hp-card-title">
          <h3>{profile.nickname}</h3>
          {profile.is_default && <span className="hp-default-badge">Default</span>}
        </div>
        <div className="hp-card-actions">
          <button onClick={() => onEdit(profile)} title="Edit"><FiEdit2 size={16} /></button>
          <button onClick={() => onDelete(profile.id)} title="Delete" className="hp-delete-btn"><FiTrash2 size={16} /></button>
        </div>
      </div>

      <div className="hp-card-body">
        {profile.bhk_type && <span className="hp-tag">{profile.bhk_type}</span>}
        {profile.area_sqft && <span className="hp-tag">{profile.area_sqft} sq ft</span>}
        {profile.locality && <span className="hp-tag">📍 {profile.locality}</span>}
        {profile.city && <span className="hp-tag">{profile.city}</span>}
        {profile.pincode && <span className="hp-tag">{profile.pincode}</span>}
      </div>

      {profile.address_line1 && (
        <p className="hp-address">
          {profile.address_line1}{profile.building_name ? `, ${profile.building_name}` : ''}
          {profile.locality ? `, ${profile.locality}` : ''}
          {profile.city ? `, ${profile.city}` : ''}
        </p>
      )}

      {profile.appliances && profile.appliances.length > 0 && (
        <div className="hp-appliances-list">
          {profile.appliances.filter((a) => a.type).slice(0, 4).map((a, i) => (
            <span key={i} className="hp-appliance-tag">
              {a.type}{a.brand ? ` · ${a.brand}` : ''}{a.model ? ` ${a.model}` : ''}
            </span>
          ))}
          {profile.appliances.length > 4 && <span className="hp-appliance-tag">+{profile.appliances.length - 4} more</span>}
        </div>
      )}

      {!profile.is_default && (
        <button className="hp-set-default-btn" onClick={() => onSetDefault(profile.id)}>
          Set as Default
        </button>
      )}
    </div>
  );
}

export default function HomeProfile() {
  const { isAuthenticated } = useAuth();
  const [profiles, setProfiles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editProfile, setEditProfile] = useState(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (isAuthenticated) fetchProfiles();
    else setLoading(false);
  }, [isAuthenticated]);

  async function fetchProfiles() {
    try {
      const res = await get('/home-profiles');
      setProfiles(res.data || []);
    } catch (err) {
      console.error('Failed to fetch home profiles:', err);
    } finally {
      setLoading(false);
    }
  }

  async function handleSave(formData) {
    setSaving(true);
    setError('');
    try {
      if (editProfile) {
        await put(`/home-profiles/${editProfile.id}`, formData);
      } else {
        await post('/home-profiles', formData);
      }
      await fetchProfiles();
      setShowForm(false);
      setEditProfile(null);
    } catch (err) {
      setError(err.message || 'Failed to save home profile.');
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete(id) {
    if (!window.confirm('Delete this home profile?')) return;
    try {
      await del(`/home-profiles/${id}`);
      setProfiles((p) => p.filter((x) => x.id !== id));
    } catch (err) {
      console.error('Delete failed:', err);
    }
  }

  async function handleSetDefault(id) {
    try {
      await post(`/home-profiles/${id}/set-default`);
      setProfiles((p) => p.map((x) => ({ ...x, is_default: x.id === id })));
    } catch (err) {
      console.error('Set default failed:', err);
    }
  }

  const handleEdit = (profile) => {
    setEditProfile(profile);
    setShowForm(true);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  if (loading) return <LoadingSpinner />;

  return (
    <div className="home-profile-page">
      <SEOMeta
        title="My Homes — SkillConnect"
        description="Save your home details for faster bookings and better service"
      />

      <div className="hp-header">
        <div>
          <h1>🏠 My Homes</h1>
          <p>Save your home details so professionals come prepared with the right tools and spare parts.</p>
        </div>
        {!showForm && (
          <button className="hp-add-btn" onClick={() => { setEditProfile(null); setShowForm(true); }}>
            <FiPlus size={16} /> Add Home
          </button>
        )}
      </div>

      {error && (
        <div className="hp-error">
          <FiAlertCircle size={16} /> {error}
        </div>
      )}

      {showForm ? (
        <div className="hp-form-card">
          <h2>{editProfile ? 'Edit Home Profile' : 'Add New Home'}</h2>
          <HomeProfileForm
            initial={editProfile}
            onSave={handleSave}
            onCancel={() => { setShowForm(false); setEditProfile(null); }}
            saving={saving}
          />
        </div>
      ) : profiles.length === 0 ? (
        <div className="hp-empty">
          <FiHome size={48} />
          <h3>No home profiles yet</h3>
          <p>Add your home details to get faster bookings and better-prepared professionals.</p>
          <button className="hp-add-btn" onClick={() => setShowForm(true)}>
            <FiPlus size={16} /> Add Your First Home
          </button>
        </div>
      ) : (
        <div className="hp-cards-grid">
          {profiles.map((p) => (
            <HomeProfileCard
              key={p.id}
              profile={p}
              onEdit={handleEdit}
              onDelete={handleDelete}
              onSetDefault={handleSetDefault}
            />
          ))}
        </div>
      )}

      <div className="hp-benefits">
        <h3>Why save your home profile?</h3>
        <div className="hp-benefits-grid">
          <div className="hp-benefit">⚡ <strong>Faster Bookings</strong> — No need to re-enter address each time</div>
          <div className="hp-benefit">🔧 <strong>Better Prepared Pros</strong> — They come with the right tools & spares</div>
          <div className="hp-benefit">💰 <strong>Accurate Quotes</strong> — Correct pricing based on your home's details</div>
          <div className="hp-benefit">📋 <strong>Service History</strong> — Track all services done in your home</div>
        </div>
      </div>
    </div>
  );
}
