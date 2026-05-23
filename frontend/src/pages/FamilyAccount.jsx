import { useState, useEffect } from 'react';
import {
  FiHome, FiUsers, FiPlus, FiEdit2, FiTrash2, FiCalendar,
  FiMapPin, FiPhone, FiMail, FiSettings, FiRepeat,
} from 'react-icons/fi';
import { get, post, put, del } from '../api/client';
import { useAuth } from '../context/AuthContext';
import SEOMeta from '../components/SEOMeta';
import './FamilyAccount.css';

function FamilyAccount() {
  const { isAuthenticated } = useAuth();
  const [households, setHouseholds] = useState([]);
  const [selectedHousehold, setSelectedHousehold] = useState(null);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [showAddMember, setShowAddMember] = useState(false);
  const [newHousehold, setNewHousehold] = useState({ name: '', address: '', city: '', property_type: 'apartment' });
  const [newMember, setNewMember] = useState({ name: '', role: 'adult', phone: '', email: '' });
  const [creatingHousehold, setCreatingHousehold] = useState(false);
  const [addingMember, setAddingMember] = useState(false);

  useEffect(() => {
    if (isAuthenticated) fetchHouseholds();
    else setLoading(false);
  }, [isAuthenticated]);

  async function fetchHouseholds() {
    try {
      const res = await get('/households');
      setHouseholds(res.data || []);
      if (res.data?.length > 0 && !selectedHousehold) {
        fetchHouseholdDetail(res.data[0].id);
      }
    } catch (err) {
      console.error('Failed to fetch households:', err);
    } finally {
      setLoading(false);
    }
  }

  async function fetchHouseholdDetail(id) {
    try {
      const res = await get(`/households/${id}`);
      setSelectedHousehold(res.data);
    } catch (err) {
      console.error('Failed to fetch household details:', err);
    }
  }

  async function handleCreateHousehold(e) {
    e.preventDefault();
    setCreatingHousehold(true);
    try {
      const res = await post('/households', newHousehold);
      setShowCreate(false);
      setNewHousehold({ name: '', address: '', city: '', property_type: 'apartment' });
      fetchHouseholds();
      if (res.data) fetchHouseholdDetail(res.data.id);
    } catch (err) {
      console.error('Failed to create household:', err);
    } finally {
      setCreatingHousehold(false);
    }
  }

  async function handleAddMember(e) {
    e.preventDefault();
    if (!selectedHousehold) return;
    setAddingMember(true);
    try {
      await post(`/households/${selectedHousehold.id}/members`, newMember);
      setShowAddMember(false);
      setNewMember({ name: '', role: 'adult', phone: '', email: '' });
      fetchHouseholdDetail(selectedHousehold.id);
    } catch (err) {
      console.error('Failed to add member:', err);
    } finally {
      setAddingMember(false);
    }
  }

  async function handleRemoveMember(memberId) {
    if (!window.confirm('Remove this member?')) return;
    try {
      await del(`/households/${selectedHousehold.id}/members/${memberId}`);
      fetchHouseholdDetail(selectedHousehold.id);
    } catch (err) {
      console.error('Failed to remove member:', err);
    }
  }

  if (!isAuthenticated) {
    return (
      <div className="family-page">
        <SEOMeta title="Family & Household — SkillConnect" />
        <div className="family-hero">
          <h1>👨‍👩‍👧‍👦 Family & Household</h1>
          <p>Manage your household, add family members, and share subscriptions. Please log in to get started.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="family-page">
      <SEOMeta title="Family & Household — SkillConnect" description="Manage your household profile and family members" />

      {/* Hero */}
      <section className="family-hero">
        <div className="family-hero-content">
          <h1>👨‍👩‍👧‍👦 Family & Household</h1>
          <p>Manage your home profile, add family members, share subscriptions, and keep your household running smoothly.</p>
        </div>
      </section>

      {/* Household Selector */}
      <section className="household-selector">
        <div className="household-tabs">
          {households.map((h) => (
            <button
              key={h.id}
              className={`household-tab ${selectedHousehold?.id === h.id ? 'active' : ''}`}
              onClick={() => fetchHouseholdDetail(h.id)}
            >
              <FiHome /> {h.name}
              {h.active_subscriptions > 0 && (
                <span className="sub-count">{h.active_subscriptions}</span>
              )}
            </button>
          ))}
          <button className="household-tab add-btn" onClick={() => setShowCreate(true)}>
            <FiPlus /> Add Home
          </button>
        </div>
      </section>

      {/* Create Household Modal */}
      {showCreate && (
        <div className="modal-overlay" onClick={() => setShowCreate(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <h2>Create Household</h2>
            <form onSubmit={handleCreateHousehold}>
              <div className="form-group">
                <label>Name</label>
                <input type="text" placeholder="e.g., My Home" value={newHousehold.name}
                  onChange={(e) => setNewHousehold({ ...newHousehold, name: e.target.value })} required />
              </div>
              <div className="form-group">
                <label>Address</label>
                <input type="text" placeholder="Full address" value={newHousehold.address}
                  onChange={(e) => setNewHousehold({ ...newHousehold, address: e.target.value })} />
              </div>
              <div className="form-row">
                <div className="form-group">
                  <label>City</label>
                  <input type="text" placeholder="City" value={newHousehold.city}
                    onChange={(e) => setNewHousehold({ ...newHousehold, city: e.target.value })} />
                </div>
                <div className="form-group">
                  <label>Property Type</label>
                  <select value={newHousehold.property_type}
                    onChange={(e) => setNewHousehold({ ...newHousehold, property_type: e.target.value })}>
                    <option value="apartment">Apartment</option>
                    <option value="house">House</option>
                    <option value="villa">Villa</option>
                    <option value="office">Office</option>
                  </select>
                </div>
              </div>
              <div className="modal-actions">
                <button type="button" className="btn-secondary" onClick={() => setShowCreate(false)}>Cancel</button>
                <button type="submit" className="btn-primary" disabled={creatingHousehold}>{creatingHousehold ? 'Creating...' : 'Create'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Household Detail */}
      {selectedHousehold && (
        <section className="household-detail">
          <div className="household-info">
            <div className="household-info-card">
              <h3><FiHome /> {selectedHousehold.name}</h3>
              {selectedHousehold.address && <p><FiMapPin size={14} /> {selectedHousehold.address}</p>}
              {selectedHousehold.city && <p>{selectedHousehold.city}, {selectedHousehold.state || ''}</p>}
              {selectedHousehold.property_type && (
                <span className="property-badge">{selectedHousehold.property_type}</span>
              )}
            </div>
          </div>

          {/* Members */}
          <div className="household-members">
            <div className="members-header">
              <h3><FiUsers /> Family Members ({selectedHousehold.members?.length || 0})</h3>
              <button className="add-member-btn" onClick={() => setShowAddMember(true)}>
                <FiPlus /> Add Member
              </button>
            </div>

            <div className="members-list">
              {selectedHousehold.members?.map((member) => (
                <div key={member.id} className="member-card">
                  <div className="member-avatar">
                    {member.name?.charAt(0).toUpperCase()}
                  </div>
                  <div className="member-info">
                    <h4>{member.name}</h4>
                    <span className="member-role">{member.role}</span>
                    {member.phone && <span className="member-contact"><FiPhone size={12} /> {member.phone}</span>}
                  </div>
                  <div className="member-perms">
                    {member.can_book && <span className="perm-badge">Can Book</span>}
                    {member.can_manage_subscriptions && <span className="perm-badge">Manage Subs</span>}
                    {member.is_emergency_contact && <span className="perm-badge emergency">Emergency</span>}
                  </div>
                  {member.role !== 'owner' && (
                    <button className="remove-member-btn" onClick={() => handleRemoveMember(member.id)}>
                      <FiTrash2 />
                    </button>
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* Household Subscriptions */}
          {selectedHousehold.subscriptions?.length > 0 && (
            <div className="household-subscriptions">
              <h3><FiRepeat /> Active Subscriptions</h3>
              <div className="household-sub-list">
                {selectedHousehold.subscriptions.map((sub) => (
                  <div key={sub.id} className="household-sub-card">
                    <h4>{sub.title}</h4>
                    <span>{sub.category_name || sub.frequency}</span>
                    <span className="sub-next">Next: {sub.next_occurrence ? new Date(sub.next_occurrence).toLocaleDateString('en-IN') : 'TBD'}</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </section>
      )}

      {/* Add Member Modal */}
      {showAddMember && (
        <div className="modal-overlay" onClick={() => setShowAddMember(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <h2>Add Family Member</h2>
            <form onSubmit={handleAddMember}>
              <div className="form-group">
                <label>Name</label>
                <input type="text" placeholder="Member name" value={newMember.name}
                  onChange={(e) => setNewMember({ ...newMember, name: e.target.value })} required />
              </div>
              <div className="form-row">
                <div className="form-group">
                  <label>Role</label>
                  <select value={newMember.role}
                    onChange={(e) => setNewMember({ ...newMember, role: e.target.value })}>
                    <option value="adult">Adult</option>
                    <option value="child">Child</option>
                    <option value="caretaker">Caretaker</option>
                  </select>
                </div>
                <div className="form-group">
                  <label>Phone</label>
                  <input type="tel" placeholder="Phone number" value={newMember.phone}
                    onChange={(e) => setNewMember({ ...newMember, phone: e.target.value })} />
                </div>
              </div>
              <div className="form-group">
                <label>Email</label>
                <input type="email" placeholder="Email (optional)" value={newMember.email}
                  onChange={(e) => setNewMember({ ...newMember, email: e.target.value })} />
              </div>
              <div className="modal-actions">
                <button type="button" className="btn-secondary" onClick={() => setShowAddMember(false)}>Cancel</button>
                <button type="submit" className="btn-primary" disabled={addingMember}>{addingMember ? 'Adding...' : 'Add Member'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* No households state */}
      {!loading && households.length === 0 && !showCreate && (
        <div className="no-households">
          <FiHome size={48} />
          <h3>Set up your first household</h3>
          <p>Create a household profile to manage family members, share subscriptions, and get personalized service recommendations.</p>
          <button className="btn-primary" onClick={() => setShowCreate(true)}>
            <FiPlus /> Create Household
          </button>
        </div>
      )}
    </div>
  );
}

export default FamilyAccount;
