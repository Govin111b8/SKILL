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
];

function Payment() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [booking, setBooking] = useState(null);
  const [loading, setLoading] = useState(true);
  const [method, setMethod] = useState('upi');
  const [paying, setPaying] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState(null);

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
      await post(`/bookings/${id}/transition`, { to: 'accepted' });
      setSuccess(true);
      setTimeout(() => navigate(`/bookings/${id}`), 2500);
    } catch {
      setError('Payment failed. Please try again.');
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
  const total = serviceFee + platformFee;

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
              <div className="payment-line total">
                <span>Total</span>
                <span>₹{total.toFixed(2)}</span>
              </div>
            </div>

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
