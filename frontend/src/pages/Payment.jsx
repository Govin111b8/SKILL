import { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { FiCheck, FiShield, FiLock, FiArrowLeft, FiCreditCard } from 'react-icons/fi';
import { get, post } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './Payment.css';

const PAYMENT_METHODS = [
  { id: 'upi', label: 'UPI', desc: 'Google Pay, PhonePe, Paytm' },
  { id: 'card', label: 'Credit / Debit Card', desc: 'Visa, Mastercard, RuPay' },
  { id: 'netbanking', label: 'Net Banking', desc: 'All major banks' },
  { id: 'cod', label: 'Cash on Delivery', desc: 'Pay after service completion' },
];

const EMI_DURATIONS = [3, 6, 9, 12];

function Payment() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [booking, setBooking] = useState(null);
  const [loading, setLoading] = useState(true);
  const [method, setMethod] = useState('upi');
  const [paying, setPaying] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState(null);
  const [couponCode, setCouponCode] = useState('');
  const [couponDiscount, setCouponDiscount] = useState(0);
  const [couponApplied, setCouponApplied] = useState(null);
  const [couponError, setCouponError] = useState('');
  const [showEMI, setShowEMI] = useState(false);
  const [selectedEMI, setSelectedEMI] = useState(null);

  useEffect(() => {
    async function fetchBooking() {
      try {
        const res = await get(`/bookings/${id}`);
        setBooking(res.data || res);
      } catch {
        setError('Could not load booking details.');
      } finally {
        setLoading(false);
      }
    }
    fetchBooking();
  }, [id]);

  async function handlePay() {
    setPaying(true);
    setError(null);
    try {
      // Create escrow payment via the payments API
      await post('/payments', { booking_id: id, method });
      setSuccess(true);
      setTimeout(() => navigate(`/bookings/${id}`), 2500);
    } catch (err) {
      setError(err?.data?.error || err?.message || 'Payment failed. Please try again.');
    } finally {
      setPaying(false);
    }
  }

  if (loading) {
    return (
      <div className="payment-page">
        <div className="payment-loading"><LoadingSpinner /></div>
      </div>
    );
  }

  if (!booking && error) {
    return (
      <div className="payment-page">
        <div className="payment-card">
          <div className="payment-error">
            <p>{error}</p>
            <Link to="/bookings" className="btn btn-primary">Back to Bookings</Link>
          </div>
        </div>
      </div>
    );
  }

  const amount = parseFloat(booking?.quoted_amount || booking?.amount || 0);
  const serviceFee = amount;
  const platformFee = Math.round(amount * 0.05 * 100) / 100;
  const discount = couponDiscount;
  const total = Math.max(0, serviceFee + platformFee - discount);
  const emiEligible = total >= 3000;

  async function handleApplyCoupon() {
    if (!couponCode.trim()) return;
    setCouponError('');
    try {
      const res = await post('/coupons/validate', { code: couponCode, amount: serviceFee + platformFee });
      setCouponDiscount(res.data.discount_amount);
      setCouponApplied(res.data);
    } catch (err) {
      setCouponError(err?.data?.message || err?.message || 'Invalid coupon');
      setCouponDiscount(0);
      setCouponApplied(null);
    }
  }

  return (
    <div className="payment-page">
      <Link to={`/bookings/${id}`} style={{ display: 'inline-flex', alignItems: 'center', gap: 6, marginBottom: '1rem', color: 'var(--gray-600)', textDecoration: 'none' }}>
        <FiArrowLeft size={16} /> Back to booking
      </Link>

      <div className="payment-card">
        {success ? (
          <div className="payment-success">
            <div className="payment-success-icon"><FiCheck size={32} /></div>
            <h3>Payment Successful!</h3>
            <p>Your booking has been confirmed. Redirecting&hellip;</p>
          </div>
        ) : (
          <>
            <div className="payment-header">
              <h2>Confirm Payment</h2>
              <p>{booking?.title || 'Service Booking'}</p>
            </div>

            <div className="payment-summary">
              <h3>Booking Summary</h3>
              {booking?.professional_name && (
                <div className="payment-line">
                  <span>Professional</span>
                  <span>{booking.professional_name}</span>
                </div>
              )}
              <div className="payment-line">
                <span>Service Fee</span>
                <span>₹{serviceFee.toFixed(2)}</span>
              </div>
              <div className="payment-line">
                <span>Platform Fee (5%)</span>
                <span>₹{platformFee.toFixed(2)}</span>
              </div>
              {discount > 0 && (
                <div className="payment-line" style={{ color: '#10b981' }}>
                  <span>Coupon Discount</span>
                  <span>-₹{discount.toFixed(2)}</span>
                </div>
              )}
              <div className="payment-line total">
                <span>Total</span>
                <span>₹{total.toFixed(2)}</span>
              </div>

              {/* Coupon Code */}
              <div style={{ marginTop: '1rem', padding: '0.75rem', background: '#f9fafb', borderRadius: '8px' }}>
                <label style={{ fontSize: '0.8rem', fontWeight: 500, display: 'block', marginBottom: '0.5rem' }}>Have a coupon?</label>
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <input type="text" value={couponCode}
                    onChange={e => setCouponCode(e.target.value.toUpperCase())}
                    placeholder="Enter code" disabled={!!couponApplied}
                    style={{ flex: 1, padding: '6px 10px', border: '1px solid #d1d5db', borderRadius: '6px', fontSize: '0.85rem' }} />
                  {couponApplied ? (
                    <button onClick={() => { setCouponApplied(null); setCouponDiscount(0); setCouponCode(''); }}
                      style={{ padding: '6px 12px', background: '#fee2e2', color: '#dc2626', border: 'none', borderRadius: '6px', cursor: 'pointer', fontSize: '0.8rem' }}>
                      Remove
                    </button>
                  ) : (
                    <button onClick={handleApplyCoupon}
                      style={{ padding: '6px 12px', background: '#6366f1', color: '#fff', border: 'none', borderRadius: '6px', cursor: 'pointer', fontSize: '0.8rem' }}>
                      Apply
                    </button>
                  )}
                </div>
                {couponError && <p style={{ color: '#ef4444', fontSize: '0.75rem', marginTop: '4px' }}>{couponError}</p>}
                {couponApplied && <p style={{ color: '#10b981', fontSize: '0.75rem', marginTop: '4px' }}>✅ {couponApplied.description || `Saved ₹${discount.toFixed(0)}`}</p>}
              </div>
            </div>

            {/* EMI Options for high-value services */}
            {emiEligible && (
              <div style={{ padding: '0 1.5rem', marginBottom: '1rem' }}>
                <button onClick={() => setShowEMI(!showEMI)}
                  style={{ background: 'none', border: '1px solid #6366f1', color: '#6366f1', padding: '8px 16px', borderRadius: '8px', cursor: 'pointer', fontSize: '0.85rem', width: '100%' }}>
                  {showEMI ? '✕ Hide EMI Options' : '💳 View EMI Options (No-Cost EMI available)'}
                </button>
                {showEMI && (
                  <div style={{ marginTop: '0.75rem', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))', gap: '0.5rem' }}>
                    {EMI_DURATIONS.map(months => {
                      const emi = Math.round(total / months);
                      return (
                        <button key={months} onClick={() => setSelectedEMI(months)}
                          style={{
                            padding: '0.75rem', border: `2px solid ${selectedEMI === months ? '#6366f1' : '#e5e7eb'}`,
                            borderRadius: '8px', background: selectedEMI === months ? '#eef2ff' : '#fff',
                            cursor: 'pointer', textAlign: 'center'
                          }}>
                          <div style={{ fontWeight: 700, fontSize: '1rem' }}>₹{emi}/mo</div>
                          <div style={{ fontSize: '0.75rem', color: '#6b7280' }}>{months} months</div>
                          <div style={{ fontSize: '0.7rem', color: '#10b981' }}>No-cost EMI</div>
                        </button>
                      );
                    })}
                  </div>
                )}
              </div>
            )}

            <div className="payment-methods">
              <h3>Payment Method</h3>
              <div className="payment-method-options">
                {PAYMENT_METHODS.map(pm => (
                  <label
                    key={pm.id}
                    className={`payment-method-option ${method === pm.id ? 'selected' : ''}`}
                  >
                    <input
                      type="radio"
                      name="paymentMethod"
                      value={pm.id}
                      checked={method === pm.id}
                      onChange={() => setMethod(pm.id)}
                    />
                    <div>
                      <strong>{pm.label}</strong>
                      <br />
                      <small style={{ color: 'var(--gray-500)' }}>{pm.desc}</small>
                    </div>
                  </label>
                ))}
              </div>
            </div>

            {error && (
              <p style={{ color: '#ef4444', textAlign: 'center', padding: '0 1.5rem', margin: 0 }}>{error}</p>
            )}

            <div className="payment-actions">
              <button className="btn btn-primary" onClick={handlePay} disabled={paying}>
                <FiCreditCard size={16} />
                {paying ? 'Processing…' : `Confirm & Pay ₹${total.toFixed(2)}`}
              </button>
            </div>

            <div className="payment-trust">
              <span><FiShield size={14} /> Secure Payment</span>
              <span><FiLock size={14} /> 256-bit Encrypted</span>
              <span><FiCheck size={14} /> Money-back Guarantee</span>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

export default Payment;
