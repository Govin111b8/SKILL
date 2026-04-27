import { useState, useEffect } from 'react';
import { FiEdit, FiTrash2, FiPlus, FiBarChart2 } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { get, put, post, del } from '../api/client';
import StarRating from '../components/StarRating';
import LoadingSpinner from '../components/LoadingSpinner';
import './Dashboard.css';

function Dashboard() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [dashData, setDashData] = useState(null);
  const [editMode, setEditMode] = useState(false);
  const [profileForm, setProfileForm] = useState({});

  useEffect(() => {
    fetchDashboard();
  }, []);

  async function fetchDashboard() {
    try {
      const data = await get('/dashboard');
      setDashData(data);
      if (user?.role === 'professional') {
        setProfileForm(data.profile || {});
      }
    } catch {
      setDashData(null);
    } finally {
      setLoading(false);
    }
  }

  async function handleProfileSave(e) {
    e.preventDefault();
    try {
      await put('/professionals/profile', profileForm);
      setEditMode(false);
      fetchDashboard();
    } catch {
      // handle error silently
    }
  }

  function handleProfileChange(e) {
    setProfileForm({ ...profileForm, [e.target.name]: e.target.value });
  }

  if (loading) return <LoadingSpinner />;

  const isProfessional = user?.role === 'professional';

  return (
    <div className="dashboard-page">
      <div className="container">
        <div className="dashboard-header">
          <h1>Dashboard</h1>
          <p>Welcome back, {user?.name || 'User'}!</p>
        </div>

        {isProfessional ? (
          <ProfessionalDashboard
            data={dashData}
            editMode={editMode}
            setEditMode={setEditMode}
            profileForm={profileForm}
            handleProfileChange={handleProfileChange}
            handleProfileSave={handleProfileSave}
          />
        ) : (
          <CustomerDashboard data={dashData} />
        )}
      </div>
    </div>
  );
}

function CustomerDashboard({ data }) {
  const contacts = data?.recentContacts || [];
  const reviews = data?.reviewsGiven || [];

  return (
    <div className="dashboard-grid">
      <div className="dashboard-card">
        <h2>Recent Contacts</h2>
        {contacts.length > 0 ? (
          <ul className="dashboard-list">
            {contacts.map((contact, i) => (
              <li key={i} className="dashboard-list-item">
                <div>
                  <strong>{contact.professional_name}</strong>
                  <span className="list-meta">{contact.category}</span>
                </div>
                <span className="list-date">
                  {new Date(contact.date).toLocaleDateString()}
                </span>
              </li>
            ))}
          </ul>
        ) : (
          <p className="empty-state">No recent contacts</p>
        )}
      </div>

      <div className="dashboard-card">
        <h2>Reviews Given</h2>
        {reviews.length > 0 ? (
          <ul className="dashboard-list">
            {reviews.map((review, i) => (
              <li key={i} className="dashboard-list-item">
                <div>
                  <strong>{review.professional_name}</strong>
                  <StarRating rating={review.rating} readonly size={12} />
                </div>
                <p className="review-snippet">{review.comment}</p>
              </li>
            ))}
          </ul>
        ) : (
          <p className="empty-state">No reviews yet</p>
        )}
      </div>
    </div>
  );
}

function ProfessionalDashboard({ data, editMode, setEditMode, profileForm, handleProfileChange, handleProfileSave }) {
  const stats = data?.stats || {};
  const contacts = data?.recentRequests || [];
  const portfolio = data?.portfolio || [];

  return (
    <div className="dashboard-content">
      <div className="stats-row">
        <div className="stat-box">
          <FiBarChart2 />
          <div>
            <span className="stat-value">{stats.views || 0}</span>
            <span className="stat-label">Profile Views</span>
          </div>
        </div>
        <div className="stat-box">
          <FiBarChart2 />
          <div>
            <span className="stat-value">{stats.contacts || 0}</span>
            <span className="stat-label">Contact Requests</span>
          </div>
        </div>
        <div className="stat-box">
          <FiBarChart2 />
          <div>
            <span className="stat-value">{stats.rating || '0.0'}</span>
            <span className="stat-label">Average Rating</span>
          </div>
        </div>
        <div className="stat-box">
          <FiBarChart2 />
          <div>
            <span className="stat-value">{stats.reviews || 0}</span>
            <span className="stat-label">Total Reviews</span>
          </div>
        </div>
      </div>

      <div className="dashboard-grid">
        <div className="dashboard-card">
          <div className="card-header">
            <h2>Profile</h2>
            <button className="btn btn-outline btn-sm" onClick={() => setEditMode(!editMode)}>
              <FiEdit /> {editMode ? 'Cancel' : 'Edit'}
            </button>
          </div>

          {editMode ? (
            <form onSubmit={handleProfileSave} className="profile-edit-form">
              <div className="form-group">
                <label>Headline</label>
                <input
                  name="headline"
                  value={profileForm.headline || ''}
                  onChange={handleProfileChange}
                />
              </div>
              <div className="form-group">
                <label>Bio</label>
                <textarea
                  name="bio"
                  value={profileForm.bio || ''}
                  onChange={handleProfileChange}
                  rows={4}
                />
              </div>
              <div className="form-group">
                <label>Pricing</label>
                <input
                  name="pricing"
                  value={profileForm.pricing || ''}
                  onChange={handleProfileChange}
                  placeholder="e.g., $50/hr"
                />
              </div>
              <div className="form-group">
                <label>Location</label>
                <input
                  name="location"
                  value={profileForm.location || ''}
                  onChange={handleProfileChange}
                />
              </div>
              <button type="submit" className="btn btn-primary">Save Changes</button>
            </form>
          ) : (
            <div className="profile-display">
              <p><strong>Headline:</strong> {profileForm.headline || 'Not set'}</p>
              <p><strong>Bio:</strong> {profileForm.bio || 'Not set'}</p>
              <p><strong>Pricing:</strong> {profileForm.pricing || 'Not set'}</p>
              <p><strong>Location:</strong> {profileForm.location || 'Not set'}</p>
            </div>
          )}
        </div>

        <div className="dashboard-card">
          <div className="card-header">
            <h2>Recent Requests</h2>
          </div>
          {contacts.length > 0 ? (
            <ul className="dashboard-list">
              {contacts.map((req, i) => (
                <li key={i} className="dashboard-list-item">
                  <div>
                    <strong>{req.customer_name}</strong>
                    <span className="list-meta">{req.service}</span>
                  </div>
                  <span className="list-date">
                    {new Date(req.date).toLocaleDateString()}
                  </span>
                </li>
              ))}
            </ul>
          ) : (
            <p className="empty-state">No contact requests yet</p>
          )}
        </div>

        <div className="dashboard-card full-width">
          <div className="card-header">
            <h2>Portfolio</h2>
            <button className="btn btn-outline btn-sm">
              <FiPlus /> Add Item
            </button>
          </div>
          {portfolio.length > 0 ? (
            <div className="portfolio-manage-grid">
              {portfolio.map((item, i) => (
                <div key={i} className="portfolio-manage-item">
                  <img src={item.image || item} alt={`Portfolio ${i + 1}`} />
                  <button className="portfolio-delete">
                    <FiTrash2 />
                  </button>
                </div>
              ))}
            </div>
          ) : (
            <p className="empty-state">Add portfolio items to showcase your work</p>
          )}
        </div>
      </div>
    </div>
  );
}

export default Dashboard;
