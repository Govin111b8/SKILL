import { useState, useEffect } from 'react';
import { FiGlobe, FiSettings, FiCheck, FiClock, FiAlertCircle, FiPlus, FiEdit2 } from 'react-icons/fi';
import { get, post, put } from '../../api/client';
import SEOMeta from '../../components/SEOMeta';

const statusConfig = {
  active: { label: 'Active', color: '#10b981', icon: FiCheck },
  onboarding: { label: 'Onboarding', color: '#f59e0b', icon: FiClock },
  planned: { label: 'Planned', color: '#6b7280', icon: FiClock },
  suspended: { label: 'Suspended', color: '#ef4444', icon: FiAlertCircle },
};

const tenantTypes = {
  company_operated: 'Company Operated',
  franchise: 'Franchise',
  partner: 'Country Partner',
};

function AdminCountries() {
  const [countries, setCountries] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAdd, setShowAdd] = useState(false);
  const [editingCountry, setEditingCountry] = useState(null);
  const [form, setForm] = useState({
    country_code: '', country_name: '', tenant_type: 'partner',
    default_language: 'en', currency_code: '', currency_symbol: '',
    timezone: '', commission_rate: 15, tax_rate: 18, tax_name: 'VAT',
    status: 'planned',
  });

  useEffect(() => { fetchCountries(); }, []);

  async function fetchCountries() {
    try {
      const res = await get('/countries/admin/all');
      setCountries(res.data || []);
    } catch (err) {
      console.error('Failed to fetch countries:', err);
    } finally {
      setLoading(false);
    }
  }

  async function handleSubmit(e) {
    e.preventDefault();
    try {
      if (editingCountry) {
        await put(`/countries/${editingCountry}`, form);
      } else {
        await post('/countries', form);
      }
      setShowAdd(false);
      setEditingCountry(null);
      setForm({ country_code: '', country_name: '', tenant_type: 'partner', default_language: 'en', currency_code: '', currency_symbol: '', timezone: '', commission_rate: 15, tax_rate: 18, tax_name: 'VAT', status: 'planned' });
      fetchCountries();
    } catch (err) {
      console.error('Failed to save country:', err);
      alert(err.message || 'Failed to save');
    }
  }

  function startEdit(country) {
    setEditingCountry(country.country_code);
    setForm({
      country_code: country.country_code,
      country_name: country.country_name,
      tenant_type: country.tenant_type,
      default_language: country.default_language,
      currency_code: country.currency_code,
      currency_symbol: country.currency_symbol,
      timezone: country.timezone,
      commission_rate: country.commission_rate,
      tax_rate: country.tax_rate,
      tax_name: country.tax_name,
      status: country.status,
    });
    setShowAdd(true);
  }

  const activeCount = countries.filter(c => c.status === 'active').length;
  const totalCities = countries.reduce((sum, c) => sum + (c.operational_cities?.length || 0), 0);

  return (
    <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '2rem 1rem' }}>
      <SEOMeta title="Country Management — Admin" />

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <div>
          <h1 style={{ fontSize: '1.75rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <FiGlobe /> Country Management
          </h1>
          <p style={{ color: '#6b7280', marginTop: '0.25rem' }}>
            Multi-tenant global architecture — {countries.length} countries, {activeCount} active, {totalCities} cities
          </p>
        </div>
        <button
          onClick={() => { setShowAdd(true); setEditingCountry(null); }}
          style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', padding: '0.6rem 1.2rem', background: '#6366f1', color: '#fff', border: 'none', borderRadius: '8px', cursor: 'pointer', fontSize: '0.9rem' }}
        >
          <FiPlus /> Add Country
        </button>
      </div>

      {/* Stats */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '1rem', marginBottom: '2rem' }}>
        {Object.entries(statusConfig).map(([key, cfg]) => {
          const count = countries.filter(c => c.status === key).length;
          const StatusIcon = cfg.icon;
          return (
            <div key={key} style={{ background: '#fff', border: '1px solid #e5e7eb', borderRadius: '12px', padding: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: `${cfg.color}15`, color: cfg.color, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <StatusIcon size={20} />
              </div>
              <div>
                <div style={{ fontSize: '1.25rem', fontWeight: 700 }}>{count}</div>
                <div style={{ fontSize: '0.8rem', color: '#6b7280' }}>{cfg.label}</div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Country list */}
      {loading ? (
        <p style={{ textAlign: 'center', padding: '2rem', color: '#6b7280' }}>Loading countries...</p>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          {countries.map(country => {
            const statusCfg = statusConfig[country.status] || statusConfig.planned;
            return (
              <div key={country.country_code} style={{ background: '#fff', border: '1px solid #e5e7eb', borderRadius: '12px', padding: '1.25rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '0.75rem' }}>
                  <div>
                    <h3 style={{ fontSize: '1.05rem', display: 'flex', alignItems: 'center', gap: '0.5rem', margin: 0 }}>
                      {country.country_name}
                      <span style={{ fontSize: '0.8rem', fontWeight: 400, color: '#9ca3af' }}>{country.country_code}</span>
                    </h3>
                    <span style={{ fontSize: '0.8rem', color: '#6b7280' }}>{tenantTypes[country.tenant_type] || country.tenant_type}</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <span style={{ padding: '0.2rem 0.6rem', borderRadius: '12px', fontSize: '0.75rem', fontWeight: 500, color: statusCfg.color, background: `${statusCfg.color}15` }}>
                      {statusCfg.label}
                    </span>
                    <button onClick={() => startEdit(country)} style={{ background: 'none', border: 'none', color: '#6b7280', cursor: 'pointer', padding: '0.3rem' }}>
                      <FiEdit2 size={16} />
                    </button>
                  </div>
                </div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '1rem', fontSize: '0.85rem', color: '#6b7280' }}>
                  <span>💰 {country.currency_symbol} {country.currency_code}</span>
                  <span>📊 {country.commission_rate}% commission</span>
                  <span>🏛️ {country.tax_rate}% {country.tax_name}</span>
                  <span>🗣️ {country.supported_languages?.join(', ')}</span>
                  <span>💳 {country.payment_gateways?.join(', ')}</span>
                  {country.operational_cities?.length > 0 && (
                    <span>🏙️ {country.operational_cities.join(', ')}</span>
                  )}
                  {country.enabled_engines?.length > 0 && (
                    <span>⚙️ {country.enabled_engines.join(', ')}</span>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Add/Edit Modal */}
      {showAdd && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: '1rem' }} onClick={() => setShowAdd(false)}>
          <div style={{ background: '#fff', borderRadius: '16px', padding: '2rem', maxWidth: '500px', width: '100%', maxHeight: '90vh', overflowY: 'auto' }} onClick={e => e.stopPropagation()}>
            <h2 style={{ marginBottom: '1.5rem' }}>{editingCountry ? 'Edit Country' : 'Add Country'}</h2>
            <form onSubmit={handleSubmit}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 500, marginBottom: '0.3rem' }}>Country Code</label>
                  <input type="text" value={form.country_code} onChange={e => setForm({...form, country_code: e.target.value.toUpperCase()})}
                    maxLength={3} required disabled={!!editingCountry}
                    style={{ width: '100%', padding: '0.5rem', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 500, marginBottom: '0.3rem' }}>Country Name</label>
                  <input type="text" value={form.country_name} onChange={e => setForm({...form, country_name: e.target.value})}
                    required style={{ width: '100%', padding: '0.5rem', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 500, marginBottom: '0.3rem' }}>Tenant Type</label>
                  <select value={form.tenant_type} onChange={e => setForm({...form, tenant_type: e.target.value})}
                    style={{ width: '100%', padding: '0.5rem', border: '1px solid #e5e7eb', borderRadius: '8px' }}>
                    <option value="company_operated">Company Operated</option>
                    <option value="franchise">Franchise</option>
                    <option value="partner">Country Partner</option>
                  </select>
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 500, marginBottom: '0.3rem' }}>Status</label>
                  <select value={form.status} onChange={e => setForm({...form, status: e.target.value})}
                    style={{ width: '100%', padding: '0.5rem', border: '1px solid #e5e7eb', borderRadius: '8px' }}>
                    <option value="planned">Planned</option>
                    <option value="onboarding">Onboarding</option>
                    <option value="active">Active</option>
                    <option value="suspended">Suspended</option>
                  </select>
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 500, marginBottom: '0.3rem' }}>Currency Code</label>
                  <input type="text" value={form.currency_code} onChange={e => setForm({...form, currency_code: e.target.value.toUpperCase()})}
                    maxLength={3} style={{ width: '100%', padding: '0.5rem', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 500, marginBottom: '0.3rem' }}>Currency Symbol</label>
                  <input type="text" value={form.currency_symbol} onChange={e => setForm({...form, currency_symbol: e.target.value})}
                    maxLength={5} style={{ width: '100%', padding: '0.5rem', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 500, marginBottom: '0.3rem' }}>Commission %</label>
                  <input type="number" value={form.commission_rate} onChange={e => setForm({...form, commission_rate: parseFloat(e.target.value)})}
                    min={0} max={50} step={0.5} style={{ width: '100%', padding: '0.5rem', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 500, marginBottom: '0.3rem' }}>Tax Rate %</label>
                  <input type="number" value={form.tax_rate} onChange={e => setForm({...form, tax_rate: parseFloat(e.target.value)})}
                    min={0} max={50} step={0.5} style={{ width: '100%', padding: '0.5rem', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 500, marginBottom: '0.3rem' }}>Tax Name</label>
                  <input type="text" value={form.tax_name} onChange={e => setForm({...form, tax_name: e.target.value})}
                    style={{ width: '100%', padding: '0.5rem', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 500, marginBottom: '0.3rem' }}>Timezone</label>
                  <input type="text" value={form.timezone} onChange={e => setForm({...form, timezone: e.target.value})}
                    placeholder="e.g. Asia/Dubai" style={{ width: '100%', padding: '0.5rem', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
                </div>
              </div>
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '1.5rem' }}>
                <button type="button" onClick={() => setShowAdd(false)} style={{ padding: '0.6rem 1.2rem', background: '#f3f4f6', border: 'none', borderRadius: '8px', cursor: 'pointer' }}>Cancel</button>
                <button type="submit" style={{ padding: '0.6rem 1.2rem', background: '#6366f1', color: '#fff', border: 'none', borderRadius: '8px', cursor: 'pointer' }}>
                  {editingCountry ? 'Update' : 'Create'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default AdminCountries;
