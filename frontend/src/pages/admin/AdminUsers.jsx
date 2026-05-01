import { useState, useEffect } from 'react';
import api from '../../api/client';
import './Admin.css';

export default function AdminUsers() {
  const [users, setUsers] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchUsers();
  }, [page, roleFilter]);

  async function fetchUsers() {
    setLoading(true);
    try {
      const params = new URLSearchParams({ page, limit: 25 });
      if (roleFilter) params.set('role', roleFilter);
      if (search) params.set('search', search);
      const res = await api.get(`/admin/users?${params}`);
      setUsers(res.data.users);
      setTotal(res.data.total);
    } catch (err) {
      console.error(err);
    }
    setLoading(false);
  }

  async function handleBan(userId) {
    if (!confirm('Ban this user?')) return;
    await api.post(`/admin/users/${userId}/ban`, { reason: 'Admin action' });
    fetchUsers();
  }

  async function handleUnban(userId) {
    await api.post(`/admin/users/${userId}/unban`);
    fetchUsers();
  }

  return (
    <div className="admin-page">
      <h1>User Management</h1>

      <div className="admin-filters">
        <input
          type="text"
          placeholder="Search by name or email..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && fetchUsers()}
        />
        <select value={roleFilter} onChange={e => setRoleFilter(e.target.value)}>
          <option value="">All Roles</option>
          <option value="customer">Customer</option>
          <option value="professional">Professional</option>
        </select>
        <button onClick={fetchUsers}>Search</button>
      </div>

      {loading ? <p>Loading...</p> : (
        <>
          <p className="admin-count">{total} users found</p>
          <table className="admin-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Role</th>
                <th>Verified</th>
                <th>Joined</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {users.map(user => (
                <tr key={user.id}>
                  <td>{user.name}</td>
                  <td>{user.email}</td>
                  <td><span className={`badge badge-${user.role}`}>{user.role}</span></td>
                  <td>{user.email_verified ? '✅' : '❌'}</td>
                  <td>{new Date(user.created_at).toLocaleDateString()}</td>
                  <td>
                    <button className="btn-sm btn-danger" onClick={() => handleBan(user.id)}>Ban</button>
                    <button className="btn-sm btn-success" onClick={() => handleUnban(user.id)}>Unban</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          <div className="admin-pagination">
            <button disabled={page <= 1} onClick={() => setPage(p => p - 1)}>← Prev</button>
            <span>Page {page} of {Math.ceil(total / 25)}</span>
            <button disabled={page >= Math.ceil(total / 25)} onClick={() => setPage(p => p + 1)}>Next →</button>
          </div>
        </>
      )}
    </div>
  );
}
