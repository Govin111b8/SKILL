import { Link, useLocation } from 'react-router-dom';
import { FiHome, FiGrid, FiSearch, FiUser, FiLogIn, FiRepeat, FiCalendar, FiDollarSign, FiMessageSquare } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import './BottomNav.css';

function BottomNav() {
  const { pathname } = useLocation();
  const { isAuthenticated, isProfessional, isAgent, isAdmin } = useAuth();

  // Role-specific navigation items
  let navItems;
  if (isAuthenticated && isProfessional()) {
    navItems = [
      { to: '/', icon: FiHome, label: 'Home' },
      { to: '/bookings', icon: FiCalendar, label: 'Bookings' },
      { to: '/earnings', icon: FiDollarSign, label: 'Earnings' },
      { to: '/messages', icon: FiMessageSquare, label: 'Messages' },
    ];
  } else if (isAuthenticated && isAgent()) {
    navItems = [
      { to: '/', icon: FiHome, label: 'Home' },
      { to: '/agent/dashboard', icon: FiGrid, label: 'Dashboard' },
      { to: '/agent/wallet', icon: FiDollarSign, label: 'Wallet' },
      { to: '/search', icon: FiSearch, label: 'Explore' },
    ];
  } else if (isAuthenticated && isAdmin()) {
    navItems = [
      { to: '/', icon: FiHome, label: 'Home' },
      { to: '/admin', icon: FiGrid, label: 'Admin' },
      { to: '/search', icon: FiSearch, label: 'Explore' },
      { to: '/messages', icon: FiMessageSquare, label: 'Messages' },
    ];
  } else {
    // Customer (default) or unauthenticated
    navItems = [
      { to: '/', icon: FiHome, label: 'Home' },
      { to: '/categories', icon: FiGrid, label: 'Services' },
      { to: '/subscriptions', icon: FiRepeat, label: 'Subscribe' },
      { to: '/search', icon: FiSearch, label: 'Explore' },
    ];
  }

  const accountItem = isAuthenticated
    ? { to: '/dashboard', icon: FiUser, label: 'Account' }
    : { to: '/login', icon: FiLogIn, label: 'Sign In' };

  const allItems = [...navItems, accountItem];

  return (
    <nav className="bottom-nav" aria-label="Main navigation">
      {allItems.map(({ to, icon: Icon, label }) => {
        const active =
          to === '/'
            ? pathname === '/'
            : pathname.startsWith(to);
        return (
          <Link
            key={to}
            to={to}
            className={`bn-item ${active ? 'bn-item--active' : ''}`}
          >
            <span className="bn-icon">
              <Icon size={22} />
            </span>
            <span className="bn-label">{label}</span>
          </Link>
        );
      })}
    </nav>
  );
}

export default BottomNav;
