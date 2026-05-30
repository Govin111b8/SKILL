import { FiX, FiShield, FiStar, FiCheckCircle, FiRepeat, FiClock, FiAward } from 'react-icons/fi';

const TRUST_FACTORS = [
  { icon: <FiCheckCircle color="#10b981" />, label: 'Identity Verification', desc: 'Aadhaar/PAN KYC verified by our team', weight: '25%' },
  { icon: <FiStar color="#f59e0b" />, label: 'Average Rating', desc: 'Customer ratings across all bookings', weight: '20%' },
  { icon: <FiAward color="#3b82f6" />, label: 'Experience', desc: 'Years in service + completed job count', weight: '20%' },
  { icon: <FiRepeat color="#8b5cf6" />, label: 'Repeat Customers', desc: '% of customers who booked again', weight: '15%' },
  { icon: <FiClock color="#f97316" />, label: 'Response Time', desc: 'Average time to accept/respond to requests', weight: '10%' },
  { icon: <FiShield color="#6b7280" />, label: 'Reliability', desc: 'Bookings completed vs cancelled ratio', weight: '10%' },
];

const TRUST_LEVELS = [
  { level: 'Bronze', color: '#cd7f32', min: 0, max: 39, desc: 'New or unverified professional' },
  { level: 'Silver', color: '#9ca3af', min: 40, max: 59, desc: 'Verified with some experience' },
  { level: 'Gold', color: '#f59e0b', min: 60, max: 79, desc: 'Established professional with strong track record' },
  { level: 'Platinum', color: '#6366f1', min: 80, max: 100, desc: 'Top-tier professional, highly recommended' },
];

export default function TrustExplainerModal({ onClose }) {
  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 9999, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '16px' }} onClick={onClose}>
      <div style={{ background: '#fff', borderRadius: '16px', maxWidth: '480px', width: '100%', maxHeight: '80vh', overflowY: 'auto', padding: '24px' }} onClick={e => e.stopPropagation()}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
          <h2 style={{ margin: 0, fontSize: '20px', fontWeight: '700' }}>🛡️ How Trust Score Works</h2>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: '4px' }}><FiX size={22} /></button>
        </div>

        <p style={{ color: '#6b7280', marginBottom: '20px', fontSize: '14px' }}>
          SkillConnect Trust Score is calculated from 6 real factors — not paid rankings.
        </p>

        <h3 style={{ fontSize: '14px', fontWeight: '600', color: '#374151', marginBottom: '12px' }}>SCORING FACTORS</h3>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginBottom: '24px' }}>
          {TRUST_FACTORS.map(f => (
            <div key={f.label} style={{ display: 'flex', alignItems: 'flex-start', gap: '12px' }}>
              <span style={{ marginTop: '2px' }}>{f.icon}</span>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ fontWeight: '600', fontSize: '14px' }}>{f.label}</span>
                  <span style={{ fontSize: '12px', color: '#6b7280', fontWeight: '600' }}>{f.weight}</span>
                </div>
                <span style={{ fontSize: '13px', color: '#6b7280' }}>{f.desc}</span>
              </div>
            </div>
          ))}
        </div>

        <h3 style={{ fontSize: '14px', fontWeight: '600', color: '#374151', marginBottom: '12px' }}>TRUST LEVELS</h3>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
          {TRUST_LEVELS.map(t => (
            <div key={t.level} style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
              <span style={{ background: t.color, color: '#fff', padding: '4px 10px', borderRadius: '20px', fontSize: '12px', fontWeight: '700', minWidth: '70px', textAlign: 'center' }}>{t.level}</span>
              <div>
                <span style={{ fontSize: '12px', color: '#6b7280' }}>{t.min}–{t.max} pts · {t.desc}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
