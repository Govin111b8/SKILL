import { useState, useEffect } from 'react';
import { get, put, del } from '../../api/client';
import { FiStar, FiTrash2, FiPlus } from 'react-icons/fi';
import './Admin.css';

function AdminFeaturedSlots() {
  const [slots, setSlots] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAdd, setShowAdd] = useState(false);
  const [form, setForm] = useState({
    professional_id: '',
    slot_type: 'home',
    city: '',
    start_date: '',
    end_date: '',
  });

  useEffect(() => {
    get('/admin/featured-slots').then(res => {
      setSlots(res.data || []);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, []);

  async function handleAdd(e) {
    e.preventDefault();
    try {
      const res = await put('/admin/featured-slots', form);
      setSlots(prev => [res.data, ...prev].filter(Boolean));
      setShowAdd(false);
      setForm({ professional_id: '', slot_type: 'home', city: '', start_date: '', end_date: '' });
    } catch (err) {
      alert(err.message || 'Failed to add featured slot');
    }
  }

  async function handleRemove(id) {
    if (!confirm('Cancel this featured slot?')) return;
    try {
      await del(`/admin/featured-slots/${id}`);
      setSlots(prev => prev.filter(s => s.id !== id));
    } catch (err) {
      alert(err.message || 'Failed to remove slot');
    }
  }

  if (loading) return <div className="admin-loading">Loading featured slots…</div>;

  return (
    <div className="admin-page">
      <div className="admin-page-header">
        <h1><FiStar /> Featured Slots</h1>
        <button className="btn btn-primary btn-sm" onClick={() => setShowAdd(true)}>
          <FiPlus /> Add Featured Slot
        </button>
      </div>

      {showAdd && (
        <div className="admin-card" style={{ marginBottom: 24 }}>
          <h3>New Featured Slot</h3>
          <form onSubmit={handleAdd} style={{ display: 'flex', flexWrap: 'wrap', gap: 12 }}>
            <input required className="admin-input" placeholder="Professional ID" value={form.professional_id} onChange={e => setForm(f => ({ ...f, professional_id: e.target.value }))} />
            <select className="admin-input" value={form.slot_type} onChange={e => setForm(f => ({ ...f, slot_type: e.target.value }))}>
              <option value="home">Home Page</option>
              <option value="category">Category Page</option>
              <option value="search">Search Results</option>
            </select>
            <input className="admin-input" placeholder="City (optional)" value={form.city} onChange={e => setForm(f => ({ ...f, city: e.target.value }))} />
            <input required type="date" className="admin-input" value={form.start_date} onChange={e => setForm(f => ({ ...f, start_date: e.target.value }))} />
            <input required type="date" className="admin-input" value={form.end_date} onChange={e => setForm(f => ({ ...f, end_date: e.target.value }))} />
            <div style={{ display: 'flex', gap: 8 }}>
              <button type="submit" className="btn btn-primary btn-sm">Save</button>
              <button type="button" className="btn btn-outline btn-sm" onClick={() => setShowAdd(false)}>Cancel</button>
            </div>
          </form>
        </div>
      )}

      <div className="admin-table-wrap">
        <table className="admin-table">
          <thead>
            <tr>
              <th>Professional</th>
              <th>Slot Type</th>
              <th>City</th>
              <th>Start</th>
              <th>End</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {slots.map(s => (
              <tr key={s.id}>
                <td>{s.professional_name || s.professional_id?.slice(0, 8)}</td>
                <td><span className="admin-badge admin-badge-blue">{s.slot_type}</span></td>
                <td>{s.city || 'All'}</td>
                <td>{new Date(s.start_date).toLocaleDateString()}</td>
                <td>{new Date(s.end_date).toLocaleDateString()}</td>
                <td><span className={`status-badge status-${s.status}`}>{s.status}</span></td>
                <td>
                  {s.status === 'active' && (
                    <button className="btn-icon btn-danger" onClick={() => handleRemove(s.id)} title="Cancel slot">
                      <FiTrash2 size={14} />
                    </button>
                  )}
                </td>
              </tr>
            ))}
            {slots.length === 0 && (
              <tr><td colSpan={7} style={{ textAlign: 'center', color: 'var(--gray-400)', padding: '40px' }}>No featured slots configured</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default AdminFeaturedSlots;
