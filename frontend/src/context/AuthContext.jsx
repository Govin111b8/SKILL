import { createContext, useContext, useState, useEffect } from 'react';
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
    } catch {
      localStorage.removeItem('token');
      setToken(null);
    } finally {
      setLoading(false);
    }
  }

  async function login(email, password) {
    const res = await post('/auth/login', { email, password });
    const payload = res.data || res;
    const newToken = payload.token;
    localStorage.setItem('token', newToken);
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
    setToken(newToken);
    setUser(payload.user);
    window.dispatchEvent(new Event('auth-change'));
    return payload;
  }

  function logout() {
    localStorage.removeItem('token');
    setToken(null);
    setUser(null);
    window.dispatchEvent(new Event('auth-change'));
  }

  const value = {
    user,
    token,
    loading,
    login,
    register,
    logout,
    isAuthenticated: !!token,
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
