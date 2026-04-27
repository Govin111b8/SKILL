import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { FiMenu, FiX, FiSearch, FiGrid, FiHome, FiUser, FiLogOut } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import './Navbar.css';

function Navbar() {
  const [menuOpen, setMenuOpen] = useState(false);
  const { user, isAuthenticated, logout } = useAuth();
  const navigate = useNavigate();

  function handleLogout() {
    logout();
    navigate('/');
    setMenuOpen(false);
  }

  return (
    <nav className="navbar">
      <div className="navbar-container">
        <Link to="/" className="navbar-logo">
          SkillConnect
        </Link>

        <button
          className="navbar-toggle"
          onClick={() => setMenuOpen(!menuOpen)}
          aria-label="Toggle menu"
        >
          {menuOpen ? <FiX size={24} /> : <FiMenu size={24} />}
        </button>

        <div className={`navbar-menu ${menuOpen ? 'active' : ''}`}>
          <div className="navbar-links">
            <Link to="/" onClick={() => setMenuOpen(false)}>
              <FiHome /> Home
            </Link>
            <Link to="/categories" onClick={() => setMenuOpen(false)}>
              <FiGrid /> Categories
            </Link>
            <Link to="/search" onClick={() => setMenuOpen(false)}>
              <FiSearch /> Search
            </Link>
          </div>

          <div className="navbar-auth">
            {isAuthenticated ? (
              <>
                <Link to="/dashboard" className="navbar-user" onClick={() => setMenuOpen(false)}>
                  <FiUser /> {user?.name || 'Dashboard'}
                </Link>
                <button className="btn btn-outline navbar-logout" onClick={handleLogout}>
                  <FiLogOut /> Logout
                </button>
              </>
            ) : (
              <>
                <Link to="/login" className="btn btn-outline" onClick={() => setMenuOpen(false)}>
                  Login
                </Link>
                <Link to="/register" className="btn btn-primary" onClick={() => setMenuOpen(false)}>
                  Register
                </Link>
              </>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
}

export default Navbar;
