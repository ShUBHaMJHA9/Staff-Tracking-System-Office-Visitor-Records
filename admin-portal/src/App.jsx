// c:\Users\jha95\OneDrive\Documents\PROJECT\enterprise-oms\admin-portal\src\App.jsx
import React, { useState, useEffect } from 'react';
import AdminPortal from './components/AdminPortal';
import { Sun, Moon, Lock, Mail, ArrowRight, ShieldAlert, LogOut, Menu } from 'lucide-react';
import { API } from './utils/api';
import './App.css';

function App() {
  const [theme, setTheme] = useState('theme-light');
  const [user, setUser] = useState(() => {
    const session = localStorage.getItem('iod_active_user');
    return session ? JSON.parse(session) : null;
  });
  
  // Login input states
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  // Mobile menu sidebar toggle state for Admin Portal
  const [sidebarOpen, setSidebarOpen] = useState(false);

  // Sync theme to document body class
  useEffect(() => {
    const root = document.documentElement;
    if (theme === 'theme-dark') {
      root.classList.add('theme-dark');
    } else {
      root.classList.remove('theme-dark');
    }
  }, [theme]);

  const toggleTheme = () => {
    setTheme(prev => prev === 'theme-light' ? 'theme-dark' : 'theme-light');
  };

  const handleLogin = async (e) => {
    if (e) e.preventDefault();
    setError('');
    try {
      const loggedUser = await API.login(email, password);
      setUser(loggedUser);
    } catch (err) {
      setError(err.message || 'Invalid email or security code.');
    }
  };


  const handleLogout = () => {
    API.logout();
    setUser(null);
    setEmail('');
    setPassword('');
  };


  return (
    <div className={`app-wrapper ${theme}`}>
      {/* Theme Toggle Button (Always Available) */}
      <button className="theme-switch" onClick={toggleTheme} aria-label="Toggle dark/light theme">
        {theme === 'theme-light' ? <Moon size={20} /> : <Sun size={20} />}
      </button>

      {/* LOGIN GATE */}
      {!user ? (
        <div className="login-page-wrapper">
          <div className="login-card">
            {/* Left Brand Panel */}
            <div className="login-brand-banner">
              <div>
                <div className="login-brand-logo">IOD</div>
                <h2>INSTITUTE OF DIRECTORS</h2>
                <p>Modernizing office workflow through digital visitor passes, face recognition check-ins, and GPS out-office duty tracking.</p>
              </div>
              <div className="login-brand-footer">
                <span>© 2026 IOD Web & IT Operations. All rights reserved.</span>
              </div>
            </div>

            {/* Right Login Panel */}
            <div className="login-form-container">
              <h3>System Portal Login</h3>
              <p>Log in using your corporate credentials to access your console.</p>

              {error && (
                <div className="form-error">
                  <ShieldAlert size={18} />
                  <span>{error}</span>
                </div>
              )}

              <form onSubmit={handleLogin}>
                <div className="form-group">
                  <label>Corporate Email</label>
                  <div className="search-box w-full">
                    <Mail size={16} className="text-muted" />
                    <input 
                      type="email" 
                      required 
                      placeholder="name@iodglobal.com" 
                      value={email}
                      onChange={e => setEmail(e.target.value)}
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label>Security Code / Password</label>
                  <div className="search-box w-full">
                    <Lock size={16} className="text-muted" />
                    <input 
                      type="password" 
                      required 
                      placeholder="••••••••" 
                      value={password}
                      onChange={e => setPassword(e.target.value)}
                    />
                  </div>
                </div>

                <button type="submit" className="btn btn-primary w-full mt-4">
                  <span>Sign In</span>
                  <ArrowRight size={16} />
                </button>
              </form>

            </div>
          </div>
        </div>
      ) : (
        /* AUTHENTICATED: RENDER SYSTEM ACCORDING TO ROLE */
        <div>
          {user.role === 'Admin' ? (
            <AdminPortal onLogout={handleLogout} theme={theme} />
          ) : (
            /* NON-ADMIN MOCK PLATFORMS placeholder (Gaurd/Staff) */
            <div className="login-page-wrapper">
              <div className="login-content text-center" style={{ maxWidth: '420px', padding: '32px', backgroundColor: 'var(--bg-card)', borderRadius: '16px', border: '1px solid var(--border-main)', boxShadow: 'var(--shadow-pop)' }}>
                <ShieldAlert size={48} className="text-red" style={{ margin: '0 auto 16px' }} />
                <h3>Module Under Construction</h3>
                <p className="text-muted mt-4" style={{ fontSize: '14px', marginBottom: '24px' }}>
                  You have logged in successfully as <strong>{user.name} ({user.role})</strong>.<br/>
                  The mobile app interfaces for Security Guards and Staff are separated according to the SDLC guidelines.
                </p>
                <button className="btn btn-secondary w-full" onClick={handleLogout}>
                  Return to Login
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

export default App;
