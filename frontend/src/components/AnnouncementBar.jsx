import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { FiX, FiArrowRight } from 'react-icons/fi';
import './AnnouncementBar.css';

const announcements = [
  {
    id: 'launch-offer',
    text: '🎉 Launch Offer: Get ₹200 off your first booking!',
    link: '/search',
    linkText: 'Book Now',
    bg: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%)',
  },
  {
    id: 'pro-signup',
    text: '🔥 Professionals: Join free & get 10 leads/month. Limited spots!',
    link: '/register',
    linkText: 'Join Free',
    bg: 'linear-gradient(135deg, #f97316 0%, #ef4444 100%)',
  },
  {
    id: 'referral',
    text: '💰 Invite friends & earn ₹200 for each signup!',
    link: '/referrals',
    linkText: 'Start Earning',
    bg: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
  },
];

function AnnouncementBar() {
  const [dismissed, setDismissed] = useState(() => {
    try { return JSON.parse(localStorage.getItem('sc_dismissed_banners') || '[]'); }
    catch { return []; }
  });
  const [currentIndex, setCurrentIndex] = useState(0);

  const visibleAnnouncements = announcements.filter(a => !dismissed.includes(a.id));

  useEffect(() => {
    if (visibleAnnouncements.length <= 1) return;
    const timer = setInterval(() => {
      setCurrentIndex(prev => (prev + 1) % visibleAnnouncements.length);
    }, 5000);
    return () => clearInterval(timer);
  }, [visibleAnnouncements.length]);

  if (visibleAnnouncements.length === 0) return null;

  const current = visibleAnnouncements[currentIndex % visibleAnnouncements.length];

  function handleDismiss() {
    const updated = [...dismissed, current.id];
    setDismissed(updated);
    localStorage.setItem('sc_dismissed_banners', JSON.stringify(updated));
  }

  return (
    <div className="announcement-bar" style={{ background: current.bg }}>
      <div className="announcement-content">
        <span className="announcement-text">{current.text}</span>
        <Link to={current.link} className="announcement-cta">
          {current.linkText} <FiArrowRight size={14} />
        </Link>
      </div>
      <button className="announcement-close" onClick={handleDismiss} aria-label="Dismiss">
        <FiX size={16} />
      </button>
    </div>
  );
}

export default AnnouncementBar;
