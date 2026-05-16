import { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { post, get } from '../api/client';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(localStorage.getItem('token'));
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (token) {
      loadUser();
    } else {
      setLoading(false);
    }
  }, []);

  async function loadUser() {
    try {
      const res = await get('/auth/me');
      setUser(res.data?.user || res.user || res);
    } catch (err) {
      // If 401, try refreshing the token
      if (err?.status === 401) {
        const refreshed = await refreshToken();
        if (!refreshed) {
          localStorage.removeItem('token');
          setToken(null);
        }
      } else {
        localStorage.removeItem('token');
        setToken(null);
      }
    } finally {
      setLoading(false);
    }
  }

  async function refreshToken() {
    try {
      const refreshTok = localStorage.getItem('refreshToken');
      if (!refreshTok) return false;
      const res = await post('/auth/refresh', { refreshToken: refreshTok });
      const payload = res.data || res;
      if (payload.token) {
        localStorage.setItem('token', payload.token);
        if (payload.refreshToken) localStorage.setItem('refreshToken', payload.refreshToken);
        setToken(payload.token);
        setUser(payload.user || user);
        return true;
      }
      return false;
    } catch {
      return false;
    }
  }

  async function login(email, password) {
    const res = await post('/auth/login', { email, password });
    const payload = res.data || res;
    const newToken = payload.token;
    localStorage.setItem('token', newToken);
    if (payload.refreshToken) localStorage.setItem('refreshToken', payload.refreshToken);
    setToken(newToken);
    setUser(payload.user);
    window.dispatchEvent(new Event('auth-change'));
    return payload;
  }

  async function register(formData) {
    const res = await post('/auth/register', formData);
    const payload = res.data || res;
    const newToken = payload.token;
    localStorage.setItem('token', newToken);
    if (payload.refreshToken) localStorage.setItem('refreshToken', payload.refreshToken);
    setToken(newToken);
    setUser(payload.user);
    window.dispatchEvent(new Event('auth-change'));
    return payload;
  }

  function logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('refreshToken');
    setToken(null);
    setUser(null);
    window.dispatchEvent(new Event('auth-change'));
  }

  // Role helper functions
  const isAdmin = useCallback(() => user?.is_admin === true || user?.role === 'admin', [user]);
  const isProfessional = useCallback(() => user?.role === 'professional', [user]);
  const isAgent = useCallback(() => user?.role === 'agent', [user]);
  const hasRole = useCallback((role) => user?.role === role, [user]);

  const value = {
    user,
    token,
    loading,
    login,
    register,
    logout,
    refreshToken,
    isAuthenticated: !!token,
    isAdmin,
    isProfessional,
    isAgent,
    hasRole,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

export default AuthContext;
