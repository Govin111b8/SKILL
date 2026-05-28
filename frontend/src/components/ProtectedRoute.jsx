import PropTypes from 'prop-types';
import { Navigate } from 'react-router-dom';
import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import LoadingSpinner from './LoadingSpinner';

const AUTH_TIMEOUT_MS = 10000; // 10 seconds

function ProtectedRoute({ children, allowedRoles }) {
  const { isAuthenticated, loading, user } = useAuth();
  const [isTimedOut, setIsTimedOut] = useState(false);

  // Timeout detection for auth loading state
  useEffect(() => {
    if (!loading) {
      setIsTimedOut(false);
      return;
    }

    const timer = setTimeout(() => setIsTimedOut(true), AUTH_TIMEOUT_MS);
    return () => clearTimeout(timer);
  }, [loading]);

  if (loading) {
    if (isTimedOut) {
      return (
        <div style={{ padding: '2rem', textAlign: 'center' }}>
          <p style={{ color: 'var(--text-secondary, #666)', marginBottom: '1rem' }}>
            Authentication is taking longer than expected.
          </p>
          <button
            onClick={() => window.location.reload()}
            style={{
              padding: '0.5rem 1.5rem',
              background: 'var(--primary, #6C63FF)',
              color: 'white',
              border: 'none',
              borderRadius: '6px',
              cursor: 'pointer',
            }}
          >
            Reload Page
          </button>
          <button
            onClick={() => window.location.href = '/login'}
            style={{
              padding: '0.5rem 1.5rem',
              background: 'transparent',
              color: 'var(--primary, #6C63FF)',
              border: '1px solid var(--primary, #6C63FF)',
              borderRadius: '6px',
              cursor: 'pointer',
              marginLeft: '0.5rem',
            }}
          >
            Go to Login
          </button>
        </div>
      );
    }
    return <LoadingSpinner />;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  // Role-based access control
  if (allowedRoles && allowedRoles.length > 0) {
    const userRole = user?.role || 'customer';
    const isAdmin = user?.is_admin === true;
    if (!allowedRoles.includes(userRole) && !(allowedRoles.includes('admin') && isAdmin)) {
      return <Navigate to="/" replace />;
    }
  }

  return children;
}

ProtectedRoute.propTypes = {
  children: PropTypes.node.isRequired,
  allowedRoles: PropTypes.arrayOf(PropTypes.string),
};

export default ProtectedRoute;
