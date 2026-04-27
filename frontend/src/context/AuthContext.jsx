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
      const data = await get('/auth/me');
      setUser(data.user || data);
    } catch {
      localStorage.removeItem('token');
      setToken(null);
    } finally {
      setLoading(false);
    }
  }

  async function login(email, password) {
    const data = await post('/auth/login', { email, password });
    const newToken = data.token;
    localStorage.setItem('token', newToken);
    setToken(newToken);
    setUser(data.user);
    return data;
  }

  async function register(formData) {
    const data = await post('/auth/register', formData);
    const newToken = data.token;
    localStorage.setItem('token', newToken);
    setToken(newToken);
    setUser(data.user);
    return data;
  }

  function logout() {
    localStorage.removeItem('token');
    setToken(null);
    setUser(null);
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
