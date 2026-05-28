import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiUser, FiLock, FiTrash2, FiSave, FiArrowLeft, FiCheck, FiBell, FiGlobe, FiShield, FiMapPin, FiMonitor, FiPlus } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { get, put, post, del } from '../api/client';
import './Settings.css';

function Settings() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [tab, setTab] = useState('profile');
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState(null);

  const [notifPrefs, setNotifPrefs] = useState({
    security: true,
    verification: true,
    complaint: true,
    subscription: true,
    profile_activity: true,
    quote_requests: true,
    marketing: false,
  });
  const [savingNotif, setSavingNotif] = useState(false);

  const [profileForm, setProfileForm] = useState({
    name: user?.name || '',
    phone: user?.phone || '',
    location: user?.location || '',
  });

  const [passwordForm, setPasswordForm] = useState({
    current_password: '',
    new_password: '',
    confirm_password: '',
  });

  function showMessage(text, type = 'success') {
    setMessage({ text, type });
    setTimeout(() => setMessage(null), 3000);
  }

  async function handleProfileSave(e) {
    e.preventDefault();
    setSaving(true);
    try {
      await put('/users/profile', profileForm);
      showMessage('Profile updated successfully!');
    } catch (err) {
      showMessage(err.message || 'Failed to update profile', 'error');
    } finally {
      setSaving(false);
    }
  }

  async function handlePasswordChange(e) {
    e.preventDefault();
    if (passwordForm.new_password !== passwordForm.confirm_password) {
      showMessage('Passwords do not match', 'error');
      return;
    }
    setSaving(true);
    try {
      await put('/users/change-password', {
        current_password: passwordForm.current_password,
        new_password: passwordForm.new_password,
      });
      showMessage('Password changed successfully!');
      setPasswordForm({ current_password: '', new_password: '', confirm_password: '' });
    } catch (err) {
      showMessage(err.message || 'Failed to change password', 'error');
    } finally {
      setSaving(false);
    }
  }

  async function handleDeleteAccount() {
    if (!window.confirm('Are you sure you want to delete your account? This action cannot be undone.')) return;
    try {
      await del('/users/account');
      logout();
      navigate('/');
    } catch (err) {
      showMessage(err.message || 'Failed to delete account', 'error');
    }
  }

  return (
    <div className="settings-page">
      <div className="container">
        <div className="settings-header">
          <button className="btn-back" onClick={() => navigate('/dashboard')}>
            <FiArrowLeft /> Back to Dashboard
          </button>
          <h1>Settings</h1>
          <p>Manage your account settings and preferences</p>
        </div>

        {message && (
          <div className={`settings-toast settings-toast--${message.type}`}>
            {message.type === 'success' && <FiCheck />}
            {message.text}
          </div>
        )}

        <div className="settings-layout">
          <nav className="settings-nav">
            <button className={`settings-nav-btn ${tab === 'profile' ? 'active' : ''}`} onClick={() => setTab('profile')}>
              <FiUser /> Profile
            </button>
            <button className={`settings-nav-btn ${tab === 'password' ? 'active' : ''}`} onClick={() => setTab('password')}>
              <FiLock /> Password
            </button>
            <button className={`settings-nav-btn ${tab === 'notifications' ? 'active' : ''}`} onClick={() => setTab('notifications')}>
              <FiBell /> Notifications
            </button>
            <button className={`settings-nav-btn ${tab === 'addresses' ? 'active' : ''}`} onClick={() => setTab('addresses')}>
              <FiMapPin /> Addresses
            </button>
            <button className={`settings-nav-btn ${tab === 'security' ? 'active' : ''}`} onClick={() => setTab('security')}>
              <FiShield /> Security
            </button>
            <button className={`settings-nav-btn ${tab === 'sessions' ? 'active' : ''}`} onClick={() => setTab('sessions')}>
              <FiMonitor /> Sessions
            </button>
            <button className={`settings-nav-btn settings-nav-btn--danger ${tab === 'account' ? 'active' : ''}`} onClick={() => setTab('account')}>
              <FiTrash2 /> Account
            </button>
          </nav>

          <div className="settings-content">
            {tab === 'profile' && (
              <form onSubmit={handleProfileSave} className="settings-form">
                <h2>Edit Profile</h2>
                <div className="form-group">
                  <label>Full Name</label>
                  <input
                    type="text"
                    value={profileForm.name}
                    onChange={(e) => setProfileForm({ ...profileForm, name: e.target.value })}
                    required
                  />
                </div>
                <div className="form-group">
                  <label>Phone Number</label>
                  <input
                    type="tel"
                    value={profileForm.phone}
                    onChange={(e) => setProfileForm({ ...profileForm, phone: e.target.value })}
                    required
                  />
                </div>
                <div className="form-group">
                  <label>Location</label>
                  <input
                    type="text"
                    value={profileForm.location}
                    onChange={(e) => setProfileForm({ ...profileForm, location: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <label>Email</label>
                  <input type="email" value={user?.email || ''} disabled />
                  <small className="form-hint">Email cannot be changed</small>
                </div>
                <div className="form-group">
                  <label>Role</label>
                  <input type="text" value={user?.role || ''} disabled style={{ textTransform: 'capitalize' }} />
                </div>
                <button type="submit" className="btn btn-primary" disabled={saving}>
                  <FiSave /> {saving ? 'Saving...' : 'Save Changes'}
                </button>
              </form>
            )}

            {tab === 'password' && (
              <form onSubmit={handlePasswordChange} className="settings-form">
                <h2>Change Password</h2>
                <div className="form-group">
                  <label>Current Password</label>
                  <input
                    type="password"
                    value={passwordForm.current_password}
                    onChange={(e) => setPasswordForm({ ...passwordForm, current_password: e.target.value })}
                    required
                  />
                </div>
                <div className="form-group">
                  <label>New Password</label>
                  <input
                    type="password"
                    value={passwordForm.new_password}
                    onChange={(e) => setPasswordForm({ ...passwordForm, new_password: e.target.value })}
                    required
                    minLength={6}
                  />
                  <small className="form-hint">Minimum 6 characters</small>
                </div>
                <div className="form-group">
                  <label>Confirm New Password</label>
                  <input
                    type="password"
                    value={passwordForm.confirm_password}
                    onChange={(e) => setPasswordForm({ ...passwordForm, confirm_password: e.target.value })}
                    required
                  />
                </div>
                <button type="submit" className="btn btn-primary" disabled={saving}>
                  <FiLock /> {saving ? 'Changing...' : 'Change Password'}
                </button>
              </form>
            )}

            {tab === 'account' && (
              <div className="settings-form">
                <h2>Delete Account</h2>
                <div className="danger-zone">
                  <h3>Danger Zone</h3>
                  <p>Once you delete your account, there is no going back. All your data, reviews, contacts, and profile information will be permanently removed.</p>
                  <button className="btn btn-danger" onClick={handleDeleteAccount}>
                    <FiTrash2 /> Delete My Account
                  </button>
                </div>
              </div>
            )}

            {tab === 'notifications' && (
              <div className="settings-form">
                <h2>Notification Preferences</h2>
                <p style={{ color: 'var(--gray-500)', marginBottom: 24 }}>Choose which notifications you receive via email and in-app.</p>
                {Object.entries({
                  security: 'Security alerts (login, password change)',
                  verification: 'KYC verification updates',
                  complaint: 'Complaint & dispute notifications',
                  subscription: 'Subscription renewal reminders',
                  profile_activity: 'Profile views and contact requests',
                  quote_requests: 'New quote requests (professionals)',
                  marketing: 'Promotions, tips, and newsletters',
                }).map(([key, label]) => (
                  <label key={key} style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16, cursor: 'pointer' }}>
                    <input
                      type="checkbox"
                      checked={!!notifPrefs[key]}
                      onChange={e => setNotifPrefs(prev => ({ ...prev, [key]: e.target.checked }))}
                      style={{ width: 18, height: 18, cursor: 'pointer' }}
                    />
                    <span style={{ color: key === 'marketing' ? 'var(--gray-500)' : 'var(--gray-800)' }}>{label}</span>
                    {key === 'security' && <span style={{ fontSize: '0.75rem', color: 'var(--danger)', marginLeft: 'auto' }}>Required</span>}
                  </label>
                ))}
                <button
                  className="btn btn-primary"
                  disabled={savingNotif}
                  onClick={async () => {
                    setSavingNotif(true);
                    try {
                      await put('/users/profile', { notification_preferences: notifPrefs });
                      showMessage('Notification preferences saved!');
                    } catch (e) {
                      showMessage('Failed to save preferences', 'error');
                    } finally {
                      setSavingNotif(false);
                    }
                  }}
                >
                  <FiSave /> {savingNotif ? 'Saving…' : 'Save Preferences'}
                </button>
              </div>
            )}

            {/* Addresses Tab */}
            {tab === 'addresses' && <AddressesTab showMessage={showMessage} />}

            {/* Security/2FA Tab */}
            {tab === 'security' && <SecurityTab showMessage={showMessage} />}

            {/* Sessions Tab */}
            {tab === 'sessions' && <SessionsTab showMessage={showMessage} />}
          </div>
        </div>
      </div>
    </div>
  );
}

/* ── Addresses Management ── */
function AddressesTab({ showMessage }) {
  const [addresses, setAddresses] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ label: 'home', address_line: '', city: '', pincode: '', is_default: false });

  useEffect(() => { fetchAddresses(); }, []);

  async function fetchAddresses() {
    try {
      const res = await get('/addresses');
      setAddresses(res.data || []);
    } catch (e) { /* silent */ }
  }

  async function handleSave(e) {
    e.preventDefault();
    try {
      await post('/addresses', form);
      showMessage('Address added!');
      setShowForm(false);
      setForm({ label: 'home', address_line: '', city: '', pincode: '', is_default: false });
      fetchAddresses();
    } catch (e) {
      showMessage('Failed to save address', 'error');
    }
  }

  async function handleDelete(id) {
    try {
      await del(`/addresses/${id}`);
      fetchAddresses();
    } catch (e) { /* silent */ }
  }

  return (
    <div className="settings-section">
      <h2><FiMapPin /> Saved Addresses</h2>
      <p style={{ color: 'var(--gray-500)', fontSize: '0.85rem', marginBottom: '1rem' }}>Manage your saved addresses for quick booking</p>
      <button className="btn btn-sm btn-primary" onClick={() => setShowForm(!showForm)} style={{ marginBottom: '1rem' }}>
        <FiPlus /> Add Address
      </button>
      {showForm && (
        <form onSubmit={handleSave} style={{ padding: '1rem', background: '#f9fafb', borderRadius: '8px', marginBottom: '1rem', display: 'grid', gap: '0.75rem' }}>
          <select value={form.label} onChange={e => setForm({ ...form, label: e.target.value })}
            style={{ padding: '8px', borderRadius: '6px', border: '1px solid #d1d5db' }}>
            <option value="home">Home</option>
            <option value="office">Office</option>
            <option value="other">Other</option>
          </select>
          <input type="text" placeholder="Address line" value={form.address_line}
            onChange={e => setForm({ ...form, address_line: e.target.value })} required
            style={{ padding: '8px', borderRadius: '6px', border: '1px solid #d1d5db' }} />
          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <input type="text" placeholder="City" value={form.city}
              onChange={e => setForm({ ...form, city: e.target.value })} required
              style={{ flex: 1, padding: '8px', borderRadius: '6px', border: '1px solid #d1d5db' }} />
            <input type="text" placeholder="Pincode" value={form.pincode}
              onChange={e => setForm({ ...form, pincode: e.target.value })}
              style={{ width: '100px', padding: '8px', borderRadius: '6px', border: '1px solid #d1d5db' }} />
          </div>
          <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.85rem' }}>
            <input type="checkbox" checked={form.is_default} onChange={e => setForm({ ...form, is_default: e.target.checked })} />
            Set as default address
          </label>
          <button type="submit" className="btn btn-primary btn-sm">Save Address</button>
        </form>
      )}
      {addresses.length > 0 ? addresses.map(a => (
        <div key={a.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.75rem', border: '1px solid #e5e7eb', borderRadius: '8px', marginBottom: '0.5rem' }}>
          <div>
            <span style={{ fontWeight: 500, textTransform: 'capitalize' }}>{a.label} {a.is_default && <span style={{ fontSize: '0.7rem', background: '#dbeafe', color: '#2563eb', padding: '2px 6px', borderRadius: '4px' }}>Default</span>}</span>
            <div style={{ fontSize: '0.8rem', color: 'var(--gray-500)' }}>{a.address_line}, {a.city} {a.pincode}</div>
          </div>
          <button onClick={() => handleDelete(a.id)} style={{ background: 'none', border: 'none', color: '#ef4444', cursor: 'pointer' }}><FiTrash2 /></button>
        </div>
      )) : <p style={{ color: 'var(--gray-500)', fontSize: '0.85rem' }}>No saved addresses</p>}
    </div>
  );
}

/* ── Security / 2FA Tab ── */
function SecurityTab({ showMessage }) {
  const [twoFAEnabled, setTwoFAEnabled] = useState(false);
  const [setting, setSetting] = useState(false);

  async function handleToggle2FA() {
    setSetting(true);
    try {
      await put('/users/profile', { two_factor_enabled: !twoFAEnabled });
      setTwoFAEnabled(!twoFAEnabled);
      showMessage(twoFAEnabled ? '2FA disabled' : '2FA enabled! You will receive OTP on login.');
    } catch (e) {
      showMessage('Failed to update 2FA', 'error');
    } finally {
      setSetting(false);
    }
  }

  return (
    <div className="settings-section">
      <h2><FiShield /> Two-Factor Authentication</h2>
      <p style={{ color: 'var(--gray-500)', fontSize: '0.85rem', marginBottom: '1rem' }}>
        Add an extra layer of security to your account with SMS-based 2FA
      </p>
      <div style={{ padding: '1rem', background: '#f9fafb', borderRadius: '10px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <div style={{ fontWeight: 500 }}>SMS-Based 2FA</div>
          <div style={{ fontSize: '0.8rem', color: 'var(--gray-500)' }}>Receive a verification code via SMS on each login</div>
        </div>
        <button onClick={handleToggle2FA} disabled={setting}
          className={`btn btn-sm ${twoFAEnabled ? 'btn-danger' : 'btn-primary'}`}>
          {twoFAEnabled ? 'Disable' : 'Enable'}
        </button>
      </div>
    </div>
  );
}

/* ── Active Sessions Tab ── */
function SessionsTab({ showMessage }) {
  const [sessions, setSessions] = useState([]);

  useEffect(() => {
    async function fetchSessions() {
      try {
        const res = await get('/users/sessions');
        setSessions(res.data || []);
      } catch (e) { /* silent */ }
    }
    fetchSessions();
  }, []);

  async function handleLogoutSession(sessionId) {
    try {
      await del(`/users/sessions/${sessionId}`);
      setSessions(sessions.filter(s => s.id !== sessionId));
      showMessage('Session terminated');
    } catch (e) {
      showMessage('Failed to terminate session', 'error');
    }
  }

  return (
    <div className="settings-section">
      <h2><FiMonitor /> Active Sessions</h2>
      <p style={{ color: 'var(--gray-500)', fontSize: '0.85rem', marginBottom: '1rem' }}>Manage your active login sessions</p>
      {sessions.length > 0 ? sessions.map(s => (
        <div key={s.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.75rem', border: '1px solid #e5e7eb', borderRadius: '8px', marginBottom: '0.5rem' }}>
          <div>
            <div style={{ fontWeight: 500, fontSize: '0.85rem' }}>{s.device_info || 'Unknown device'}</div>
            <div style={{ fontSize: '0.75rem', color: 'var(--gray-500)' }}>
              {s.ip_address || ''} • Last active: {s.last_active ? new Date(s.last_active).toLocaleDateString() : 'Unknown'}
            </div>
          </div>
          {!s.is_current && (
            <button onClick={() => handleLogoutSession(s.id)}
              style={{ background: 'none', border: '1px solid #ef4444', color: '#ef4444', padding: '4px 10px', borderRadius: '6px', cursor: 'pointer', fontSize: '0.75rem' }}>
              Logout
            </button>
          )}
          {s.is_current && <span style={{ fontSize: '0.7rem', background: '#dcfce7', color: '#16a34a', padding: '3px 8px', borderRadius: '4px' }}>Current</span>}
        </div>
      )) : <p style={{ color: 'var(--gray-500)', fontSize: '0.85rem' }}>No session data available</p>}
    </div>
  );
}

export default Settings;
