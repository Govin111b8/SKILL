import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { FiPlus, FiTrash2, FiBookmark, FiLock, FiGlobe, FiStar, FiMapPin } from 'react-icons/fi';
import { get, post, del } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './Collections.css';

export default function Collections() {
  const [collections, setCollections] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [newName, setNewName] = useState('');
  const [isPublic, setIsPublic] = useState(false);
  const [creating, setCreating] = useState(false);
  const [expanded, setExpanded] = useState(null);
  const [expandedItems, setExpandedItems] = useState([]);

  useEffect(() => {
    loadCollections();
  }, []);

  async function loadCollections() {
    try {
      const res = await get('/collections');
      setCollections(res.data || []);
    } catch {
      setCollections([]);
    } finally {
      setLoading(false);
    }
  }

  async function handleCreate(e) {
    e.preventDefault();
    if (!newName.trim()) return;
    setCreating(true);
    try {
      await post('/collections', { name: newName.trim(), is_public: isPublic });
      setNewName('');
      setIsPublic(false);
      setShowCreate(false);
      await loadCollections();
    } catch {}
    setCreating(false);
  }

  async function handleDelete(id) {
    if (!confirm('Delete this collection?')) return;
    try {
      await del(`/collections/${id}`);
      setCollections(prev => prev.filter(c => c.id !== id));
      if (expanded === id) setExpanded(null);
    } catch {}
  }

  async function toggleExpand(id) {
    if (expanded === id) {
      setExpanded(null);
      return;
    }
    setExpanded(id);
    try {
      const res = await get(`/collections/${id}`);
      setExpandedItems(res.data?.items || []);
    } catch {
      setExpandedItems([]);
    }
  }

  async function removeItem(collectionId, itemId) {
    try {
      await del(`/collections/${collectionId}/items/${itemId}`);
      setExpandedItems(prev => prev.filter(i => i.id !== itemId));
      setCollections(prev =>
        prev.map(c => c.id === collectionId ? { ...c, item_count: Math.max(0, c.item_count - 1) } : c)
      );
    } catch {}
  }

  if (loading) return <LoadingSpinner />;

  return (
    <div className="collections-page">
      <div className="collections-header">
        <div>
          <h1><FiBookmark /> My Collections</h1>
          <p className="collections-subtitle">Save and organize your favorite professionals</p>
        </div>
        <button className="create-btn" onClick={() => setShowCreate(!showCreate)}>
          <FiPlus /> New Collection
        </button>
      </div>

      {showCreate && (
        <form className="create-form" onSubmit={handleCreate}>
          <input
            type="text" value={newName}
            onChange={e => setNewName(e.target.value)}
            placeholder="Collection name (e.g. Wedding Vendors)"
            maxLength={100} autoFocus
          />
          <label className="public-toggle">
            <input type="checkbox" checked={isPublic} onChange={e => setIsPublic(e.target.checked)} />
            {isPublic ? <><FiGlobe size={14} /> Public</> : <><FiLock size={14} /> Private</>}
          </label>
          <button type="submit" disabled={creating || !newName.trim()}>
            {creating ? 'Creating...' : 'Create'}
          </button>
        </form>
      )}

      {collections.length === 0 ? (
        <div className="empty-collections">
          <FiBookmark size={48} />
          <h3>No collections yet</h3>
          <p>Create a collection to save your favorite professionals, services, and posts.</p>
        </div>
      ) : (
        <div className="collections-list">
          {collections.map(c => (
            <div key={c.id} className="collection-card">
              <div className="collection-header" onClick={() => toggleExpand(c.id)}>
                <div className="collection-info">
                  <h3>{c.name}</h3>
                  <span className="collection-meta">
                    {c.item_count} item{c.item_count !== 1 ? 's' : ''} ·{' '}
                    {c.is_public ? <><FiGlobe size={12} /> Public</> : <><FiLock size={12} /> Private</>}
                  </span>
                </div>
                <button className="delete-btn" onClick={(e) => { e.stopPropagation(); handleDelete(c.id); }}>
                  <FiTrash2 size={16} />
                </button>
              </div>

              {expanded === c.id && (
                <div className="collection-items">
                  {expandedItems.length === 0 ? (
                    <p className="empty-items">No items in this collection yet.</p>
                  ) : (
                    expandedItems.map(item => (
                      <div key={item.id} className="collection-item">
                        {item.item_type === 'professional' && item.professional_name ? (
                          <Link to={`/professionals/${item.item_id}/storefront`} className="item-link">
                            <div className="item-avatar">
                              {item.avatar_url
                                ? <img src={item.avatar_url} alt={item.professional_name} />
                                : <span>{item.professional_name?.[0]}</span>
                              }
                            </div>
                            <div className="item-info">
                              <strong>{item.professional_name}</strong>
                              <span>{item.headline || item.location || ''}</span>
                              {item.average_rating > 0 && (
                                <span className="item-rating"><FiStar size={12} /> {item.average_rating.toFixed(1)}</span>
                              )}
                            </div>
                          </Link>
                        ) : (
                          <div className="item-generic">
                            <span className="item-type-label">{item.item_type}</span>
                            <span>{item.item_id}</span>
                          </div>
                        )}
                        <button className="item-remove" onClick={() => removeItem(c.id, item.id)}>
                          <FiTrash2 size={14} />
                        </button>
                      </div>
                    ))
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
