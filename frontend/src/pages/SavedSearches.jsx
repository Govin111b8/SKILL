import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { FiSearch, FiBell, FiBellOff, FiTrash2, FiEdit2, FiClock } from 'react-icons/fi';
import { get, post, put, del } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './SavedSearches.css';

export default function SavedSearches() {
  const [searches, setSearches] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [newSearch, setNewSearch] = useState({ name: '', query: '', alert_enabled: true, alert_frequency: 'daily' });

  useEffect(() => { fetchSearches(); }, []);

  async function fetchSearches() {
    try {
      const res = await get('/saved-searches');
      setSearches(res.data || []);
    } catch (err) {
      console.error('Failed to load saved searches:', err);
    } finally {
      setLoading(false);
    }
  }

  async function handleCreate() {
    if (!newSearch.name && !newSearch.query) return;
    try {
      await post('/saved-searches', newSearch);
      setShowCreate(false);
      setNewSearch({ name: '', query: '', alert_enabled: true, alert_frequency: 'daily' });
      fetchSearches();
    } catch (err) {
      console.error('Failed to create saved search:', err);
    }
  }

  async function toggleAlert(search) {
    try {
      await put(`/saved-searches/${search.id}`, { alert_enabled: !search.alert_enabled });
      setSearches(searches.map(s => s.id === search.id ? { ...s, alert_enabled: !s.alert_enabled } : s));
    } catch (err) {
      console.error('Failed to toggle alert:', err);
    }
  }

  async function handleDelete(id) {
    if (!window.confirm('Delete this saved search?')) return;
    try {
      await del(`/saved-searches/${id}`);
      setSearches(searches.filter(s => s.id !== id));
    } catch (err) {
      console.error('Failed to delete:', err);
    }
  }

  function formatDate(d) {
    return new Date(d).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
  }

  if (loading) return <div className="saved-searches-page"><LoadingSpinner /></div>;

  return (
    <div className="saved-searches-page">
      <div className="ss-header">
        <div>
          <h1>Saved Searches</h1>
          <p>Get notified when new professionals match your criteria</p>
        </div>
        <button className="btn btn-primary btn-sm" onClick={() => setShowCreate(!showCreate)}>
          + New Alert
        </button>
      </div>

      {showCreate && (
        <div className="ss-create-form">
          <input
            type="text" placeholder="Search name (e.g., 'Plumber near me')"
            value={newSearch.name}
            onChange={e => setNewSearch({ ...newSearch, name: e.target.value })}
          />
          <input
            type="text" placeholder="Search query (e.g., 'electrician Bangalore')"
            value={newSearch.query}
            onChange={e => setNewSearch({ ...newSearch, query: e.target.value })}
          />
          <div className="ss-create-options">
            <label>
              <input type="checkbox" checked={newSearch.alert_enabled}
                onChange={e => setNewSearch({ ...newSearch, alert_enabled: e.target.checked })} />
              Enable alerts
            </label>
            <select value={newSearch.alert_frequency}
              onChange={e => setNewSearch({ ...newSearch, alert_frequency: e.target.value })}>
              <option value="instant">Instant</option>
              <option value="daily">Daily digest</option>
              <option value="weekly">Weekly digest</option>
            </select>
          </div>
          <div className="ss-create-actions">
            <button className="btn btn-primary btn-sm" onClick={handleCreate}>Save</button>
            <button className="btn btn-outline btn-sm" onClick={() => setShowCreate(false)}>Cancel</button>
          </div>
        </div>
      )}

      {searches.length === 0 ? (
        <div className="ss-empty">
          <FiSearch size={48} />
          <h3>No saved searches</h3>
          <p>Save a search to get notified when new professionals match your criteria</p>
          <Link to="/search" className="btn btn-primary">Start Searching</Link>
        </div>
      ) : (
        <div className="ss-list">
          {searches.map(search => (
            <div key={search.id} className="ss-item">
              <div className="ss-item-left">
                <FiSearch className="ss-item-icon" />
                <div>
                  <span className="ss-item-name">{search.name || search.query}</span>
                  <span className="ss-item-meta">
                    {search.filters && Object.keys(JSON.parse(typeof search.filters === 'string' ? search.filters : JSON.stringify(search.filters))).length > 0 && (
                      <span className="ss-filter-badge">
                        {Object.keys(JSON.parse(typeof search.filters === 'string' ? search.filters : JSON.stringify(search.filters))).length} filters
                      </span>
                    )}
                    <FiClock size={12} /> Created {formatDate(search.created_at)}
                  </span>
                </div>
              </div>
              <div className="ss-item-actions">
                <button
                  className={`ss-alert-btn ${search.alert_enabled ? 'active' : ''}`}
                  onClick={() => toggleAlert(search)}
                  title={search.alert_enabled ? 'Alerts ON' : 'Alerts OFF'}>
                  {search.alert_enabled ? <FiBell /> : <FiBellOff />}
                  <span>{search.alert_frequency}</span>
                </button>
                <Link to={`/search?q=${encodeURIComponent(search.query || '')}`} className="btn btn-outline btn-xs">
                  Run
                </Link>
                <button className="btn btn-ghost btn-xs" onClick={() => handleDelete(search.id)}>
                  <FiTrash2 />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
