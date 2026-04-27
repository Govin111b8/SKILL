import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiUser, FiLock, FiTrash2, FiSave, FiArrowLeft, FiCheck } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { put, del } from '../api/client';
import './Settings.css';

function Settings() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [tab, setTab] = useState('profile');
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState(null);

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
          </div>
        </div>
      </div>
    </div>
  );
}

export default Settings;
