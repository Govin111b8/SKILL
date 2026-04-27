import { useState, useEffect, useRef } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { FiMenu, FiX, FiSearch, FiGrid, FiHome, FiUser, FiLogOut, FiChevronDown, FiBell } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import './Navbar.css';

function Navbar() {
  const [menuOpen, setMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const searchRef = useRef(null);
  const { user, isAuthenticated, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 20);
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  useEffect(() => { setMenuOpen(false); }, [location.pathname]);

  useEffect(() => {
    if (searchOpen && searchRef.current) searchRef.current.focus();
  }, [searchOpen]);

  function handleLogout() {
    logout();
    navigate('/');
  }

  function handleSearch(e) {
    e.preventDefault();
    if (searchQuery.trim()) {
      navigate(`/search?q=${encodeURIComponent(searchQuery.trim())}`);
      setSearchQuery('');
      setSearchOpen(false);
    }
  }

  const initials = user?.name?.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);

  return (
    <>
      <nav className={`navbar ${scrolled ? 'navbar--scrolled' : ''}`}>
        <div className="navbar-container">
          {/* Logo */}
          <Link to="/" className="navbar-logo">
            <span className="navbar-logo-icon">⚡</span>
            <span>Skill<em>Connect</em></span>
          </Link>

          {/* Center Nav */}
          <div className="navbar-center">
            <Link to="/" className={`nav-link ${location.pathname === '/' ? 'active' : ''}`}>
              <FiHome size={16} /> Home
            </Link>
            <Link to="/categories" className={`nav-link ${location.pathname === '/categories' ? 'active' : ''}`}>
              <FiGrid size={16} /> Categories
            </Link>
            <Link to="/search" className={`nav-link ${location.pathname === '/search' ? 'active' : ''}`}>
              <FiSearch size={16} /> Explore
            </Link>
          </div>

          {/* Right actions */}
          <div className="navbar-actions">
            <button className="navbar-search-btn" onClick={() => setSearchOpen(true)} aria-label="Search">
              <FiSearch size={18} />
            </button>

            {isAuthenticated ? (
              <div className="navbar-user-menu">
                <Link to="/dashboard" className="navbar-avatar" title={user?.name}>
                  {initials || <FiUser size={16} />}
                </Link>
                <button className="navbar-logout-btn" onClick={handleLogout} title="Logout">
                  <FiLogOut size={16} />
                </button>
              </div>
            ) : (
              <div className="navbar-auth-btns">
                <Link to="/login" className="btn btn-outline btn-sm">Login</Link>
                <Link to="/register" className="btn btn-primary btn-sm">Get Started</Link>
              </div>
            )}

            <button className="navbar-toggle" onClick={() => setMenuOpen(!menuOpen)} aria-label="Menu">
              {menuOpen ? <FiX size={22} /> : <FiMenu size={22} />}
            </button>
          </div>
        </div>
      </nav>

      {/* Fullscreen Search Overlay */}
      {searchOpen && (
        <div className="search-overlay" onClick={() => setSearchOpen(false)}>
          <div className="search-overlay-inner" onClick={e => e.stopPropagation()}>
            <form onSubmit={handleSearch}>
              <div className="search-overlay-field">
                <FiSearch size={24} className="search-overlay-icon" />
                <input
                  ref={searchRef}
                  type="text"
                  placeholder="Search for a service or professional..."
                  value={searchQuery}
                  onChange={e => setSearchQuery(e.target.value)}
                />
                <button type="button" className="search-overlay-close" onClick={() => setSearchOpen(false)}>
                  <FiX size={20} />
                </button>
              </div>
            </form>
            <div className="search-overlay-hints">
              <span>Popular:</span>
              {['Plumbing', 'Electrical', 'Cleaning', 'Tutoring', 'Photography'].map(t => (
                <button key={t} onClick={() => { navigate(`/search?q=${t}`); setSearchOpen(false); }}>{t}</button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Mobile Drawer */}
      <div className={`navbar-drawer ${menuOpen ? 'open' : ''}`}>
        <div className="drawer-links">
          <Link to="/"><FiHome /> Home</Link>
          <Link to="/categories"><FiGrid /> Categories</Link>
          <Link to="/search"><FiSearch /> Explore</Link>
          {isAuthenticated ? (
            <>
              <Link to="/dashboard"><FiUser /> Dashboard</Link>
              <button onClick={handleLogout} className="drawer-logout"><FiLogOut /> Logout</button>
            </>
          ) : (
            <>
              <Link to="/login" className="btn btn-outline" style={{justifyContent:'center'}}>Login</Link>
              <Link to="/register" className="btn btn-primary" style={{justifyContent:'center'}}>Get Started</Link>
            </>
          )}
        </div>
      </div>
      {menuOpen && <div className="drawer-backdrop" onClick={() => setMenuOpen(false)} />}
    </>
  );
}

export default Navbar;
