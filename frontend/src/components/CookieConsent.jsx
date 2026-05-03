import { useState, useEffect } from 'react';
import { FiShield } from 'react-icons/fi';
import './CookieConsent.css';

function CookieConsent() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const consent = localStorage.getItem('sc_cookie_consent');
    if (!consent) {
      // Delay showing to not interrupt initial UX
      const timer = setTimeout(() => setVisible(true), 2000);
      return () => clearTimeout(timer);
    }
  }, []);

  function handleAccept() {
    localStorage.setItem('sc_cookie_consent', 'accepted');
    setVisible(false);
  }

  function handleDecline() {
    localStorage.setItem('sc_cookie_consent', 'declined');
    setVisible(false);
  }

  if (!visible) return null;

  return (
    <div className="cookie-banner">
      <div className="cookie-content">
        <div className="cookie-icon"><FiShield size={20} /></div>
        <div className="cookie-text">
          <p>
            We use cookies to enhance your experience, analyze traffic, and personalize content.
            By continuing, you agree to our{' '}
            <a href="/privacy" target="_blank" rel="noopener noreferrer">Privacy Policy</a>.
          </p>
        </div>
        <div className="cookie-actions">
          <button className="cookie-btn cookie-btn--accept" onClick={handleAccept}>Accept All</button>
          <button className="cookie-btn cookie-btn--decline" onClick={handleDecline}>Necessary Only</button>
        </div>
      </div>
    </div>
  );
}

export default CookieConsent;
