import { useState } from 'react';
import { Link } from 'react-router-dom';
import { FiMail, FiPhone, FiMapPin, FiArrowRight } from 'react-icons/fi';
import './Footer.css';

const links = {
  platform: [
    { label: 'Home', to: '/' },
    { label: 'Browse Categories', to: '/categories' },
    { label: 'Search Professionals', to: '/search' },
    { label: 'Join as Professional', to: '/register' },
    { label: 'Dashboard', to: '/dashboard' },
  ],
  services: [
    { label: 'Plumbing', to: '/search?category=plumbing' },
    { label: 'Electrical', to: '/search?category=electrical' },
    { label: 'Cleaning', to: '/search?category=cleaning' },
    { label: 'Tutoring', to: '/search?category=tutoring' },
    { label: 'Photography', to: '/search?category=photography' },
  ],
};

function Footer() {
  const [email, setEmail] = useState('');
  const [subscribed, setSubscribed] = useState(false);

  function handleSubscribe(e) {
    e.preventDefault();
    if (email) { setSubscribed(true); setEmail(''); }
  }

  return (
    <footer className="footer">
      <div className="footer-main">
        <div className="container">
          <div className="footer-grid">
            {/* Brand */}
            <div className="footer-brand">
              <div className="footer-logo">&#9889; Skill<em>Connect</em></div>
              <p className="footer-desc">
                Connecting you with trusted, verified professionals in your area.
                Quality service, guaranteed satisfaction.
              </p>
              <div className="footer-contact-list">
                <span><FiMail size={14} /> support@skillconnect.com</span>
                <span><FiPhone size={14} /> +1 (555) 123-4567</span>
                <span><FiMapPin size={14} /> Available Nationwide</span>
              </div>
            </div>

            {/* Platform Links */}
            <div className="footer-col">
              <h4>Platform</h4>
              <ul>
                {links.platform.map(l => (
                  <li key={l.to}><Link to={l.to}>{l.label}</Link></li>
                ))}
              </ul>
            </div>

            {/* Service Links */}
            <div className="footer-col">
              <h4>Top Services</h4>
              <ul>
                {links.services.map(l => (
                  <li key={l.to}><Link to={l.to}>{l.label}</Link></li>
                ))}
              </ul>
            </div>

            {/* Newsletter */}
            <div className="footer-col">
              <h4>Stay Updated</h4>
              <p className="footer-newsletter-desc">Get the latest deals and new professionals in your area.</p>
              {subscribed ? (
                <div className="footer-subscribed">✓ Thanks for subscribing!</div>
              ) : (
                <form className="footer-newsletter" onSubmit={handleSubscribe}>
                  <input
                    type="email"
                    placeholder="Enter your email"
                    value={email}
                    onChange={e => setEmail(e.target.value)}
                    required
                  />
                  <button type="submit"><FiArrowRight size={18} /></button>
                </form>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="footer-bottom">
        <div className="container">
          <p>&copy; {new Date().getFullYear()} SkillConnect. All rights reserved.</p>
          <div className="footer-legal">
            <a href="#">Privacy Policy</a>
            <a href="#">Terms of Service</a>
            <a href="#">Cookie Policy</a>
          </div>
        </div>
      </div>
    </footer>
  );
}

export default Footer;
