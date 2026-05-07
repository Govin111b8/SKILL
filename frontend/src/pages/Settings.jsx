import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiUser, FiLock, FiTrash2, FiSave, FiArrowLeft, FiCheck, FiBell, FiGlobe } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { put, del } from '../api/client';
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
          </div>
        </div>
      </div>
    </div>
  );
}

export default Settings;
