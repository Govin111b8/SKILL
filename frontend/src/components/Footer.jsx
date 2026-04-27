import { Link } from 'react-router-dom';
import { FiMail, FiPhone, FiMapPin } from 'react-icons/fi';
import './Footer.css';

function Footer() {
  return (
    <footer className="footer">
      <div className="footer-container">
        <div className="footer-section">
          <h3 className="footer-logo">SkillConnect</h3>
          <p className="footer-desc">
            Connecting you with trusted professionals in your area. Quality service, guaranteed.
          </p>
        </div>

        <div className="footer-section">
          <h4>Quick Links</h4>
          <ul>
            <li><Link to="/">Home</Link></li>
            <li><Link to="/categories">Categories</Link></li>
            <li><Link to="/search">Search</Link></li>
            <li><Link to="/register">Join as Professional</Link></li>
          </ul>
        </div>

        <div className="footer-section">
          <h4>Categories</h4>
          <ul>
            <li><Link to="/search?category=plumbing">Plumbing</Link></li>
            <li><Link to="/search?category=electrical">Electrical</Link></li>
            <li><Link to="/search?category=cleaning">Cleaning</Link></li>
            <li><Link to="/search?category=tutoring">Tutoring</Link></li>
          </ul>
        </div>

        <div className="footer-section">
          <h4>Contact</h4>
          <ul className="footer-contact">
            <li><FiMail /> support@skillconnect.com</li>
            <li><FiPhone /> +1 (555) 123-4567</li>
            <li><FiMapPin /> Available Nationwide</li>
          </ul>
        </div>
      </div>

      <div className="footer-bottom">
        <p>&copy; {new Date().getFullYear()} SkillConnect. All rights reserved.</p>
      </div>
    </footer>
  );
}

export default Footer;
