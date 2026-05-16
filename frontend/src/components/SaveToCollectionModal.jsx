import { useState, useEffect } from 'react';
import { FiX, FiPlus, FiBookmark } from 'react-icons/fi';
import { get, post } from '../api/client';
import './SaveToCollectionModal.css';

export default function SaveToCollectionModal({ itemType, itemId, onClose }) {
  const [collections, setCollections] = useState([]);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [newName, setNewName] = useState('');
  const [saving, setSaving] = useState(null);
  const [saved, setSaved] = useState(null);

  useEffect(() => {
    get('/collections')
      .then(res => setCollections(res.data || []))
      .catch((err) => console.error('Failed to load collections:', err.message))
      .finally(() => setLoading(false));
  }, []);

  async function handleSave(collectionId) {
    setSaving(collectionId);
    try {
      await post(`/collections/${collectionId}/items`, { item_type: itemType, item_id: itemId });
      setSaved(collectionId);
    } catch {}
    setSaving(null);
  }

  async function handleCreate(e) {
    e.preventDefault();
    if (!newName.trim()) return;
    setCreating(true);
    try {
      const res = await post('/collections', { name: newName.trim() });
      const newCol = res.data;
      setCollections(prev => [newCol, ...prev]);
      setNewName('');
      // Auto-save to new collection
      if (newCol?.id) await handleSave(newCol.id);
    } catch {}
    setCreating(false);
  }

  return (
    <div className="save-modal-overlay" onClick={onClose}>
      <div className="save-modal" onClick={e => e.stopPropagation()}>
        <div className="save-modal-header">
          <h3><FiBookmark size={18} /> Save to Collection</h3>
          <button onClick={onClose} aria-label="Close"><FiX size={20} /></button>
        </div>

        <form className="save-modal-create" onSubmit={handleCreate}>
          <input
            type="text" value={newName}
            onChange={e => setNewName(e.target.value)}
            placeholder="New collection name..."
            maxLength={100}
          />
          <button type="submit" disabled={creating || !newName.trim()}>
            <FiPlus size={16} /> Create
          </button>
        </form>

        <div className="save-modal-list">
          {loading ? (
            <p className="save-loading">Loading collections...</p>
          ) : collections.length === 0 ? (
            <p className="save-empty">No collections yet. Create one above!</p>
          ) : (
            collections.map(c => (
              <button
                key={c.id}
                className={`save-item ${saved === c.id ? 'saved' : ''}`}
                onClick={() => handleSave(c.id)}
                disabled={saving === c.id || saved === c.id}
              >
                <span>{c.name}</span>
                <span className="save-item-count">{c.item_count ?? 0} items</span>
                {saved === c.id && <span className="save-check">✓ Saved</span>}
              </button>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
