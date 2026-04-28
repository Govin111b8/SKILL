import { Link, useLocation } from 'react-router-dom';
import { FiHome, FiGrid, FiSearch, FiUser, FiLogIn } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import './BottomNav.css';

const navItems = [
  { to: '/', icon: FiHome, label: 'Home' },
  { to: '/categories', icon: FiGrid, label: 'Services' },
  { to: '/search', icon: FiSearch, label: 'Explore' },
];

function BottomNav() {
  const { pathname } = useLocation();
  const { isAuthenticated } = useAuth();

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
