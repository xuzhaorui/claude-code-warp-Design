import { useState, useEffect, useMemo } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { SplashScreen } from './components/Splash';
import LoginPage from './components/Login/LoginPage';
import AppShell from './pages/AppShell';
import ServerSetupScreen from './pages/ServerSetupScreen';
import { setAuthExpiredHandler, isAuthenticated, clearAuthSession } from './api/auth';
import { setApiBaseUrl } from './api/config';
import { getAllowedTabs, canViewCostPrice } from './utils/permissions';

export default function App() {
  const [showSplash, setShowSplash] = useState(true);

  if (showSplash) {
    return <SplashScreen onFinish={() => setShowSplash(false)} />;
  }

  return (
    <BrowserRouter>
      <Routes>
        <Route path="*" element={<AuthFlow />} />
      </Routes>
    </BrowserRouter>
  );
}

function AuthFlow() {
  const [authStep, setAuthStep] = useState(() =>
    isAuthenticated() ? 'app' : 'server'
  );
  const [user, setUser] = useState(() => {
    try { return JSON.parse(localStorage.getItem('currentUser')); } catch { return null; }
  });
  const allowedTabs = useMemo(() => getAllowedTabs(user?.profile), [user?.profile]);
  const showCostPrice = useMemo(() => canViewCostPrice(user?.profile), [user?.profile]);

  useEffect(() => {
    setAuthExpiredHandler(() => {
      clearAuthSession();
      setUser(null);
      setAuthStep('login');
    });
    const servers = JSON.parse(localStorage.getItem('servers') || '[]');
    const activeServer = servers.find(s => s.id === localStorage.getItem('activeServer'));
    if (activeServer) setApiBaseUrl(activeServer.url);
  }, []);

  const resolveActiveServer = () => {
    const servers = JSON.parse(localStorage.getItem('servers') || '[]');
    return servers.find(s => s.id === localStorage.getItem('activeServer'));
  };

  const handleServerConfirmed = () => {
    const activeServer = resolveActiveServer();
    if (activeServer) setApiBaseUrl(activeServer.url);
    setAuthStep('login');
  };

  const handleServerChanged = async () => {
    try {
      await fetch('/store/logout', { method: 'POST', credentials: 'include' });
    } catch { /* 服务器不可达时仍继续本地清理 */ }
    clearAuthSession();
    setUser(null);
    const activeServer = resolveActiveServer();
    if (activeServer) setApiBaseUrl(activeServer.url);
    setAuthStep('login');
  };

  if (authStep === 'server') return (
    <div className="h-screen">
      <ServerSetupScreen onConfirmed={handleServerConfirmed} />
    </div>
  );

  if (authStep === 'login') return (
    <div className="h-screen">
      <LoginPage
        onLogin={(u) => { setUser(u); setAuthStep('app'); }}
        onGoToServerConfig={() => setAuthStep('server')}
      />
    </div>
  );

  return (
    <AppShell
      onLogout={async () => {
        try { await fetch('/store/logout', { method: 'POST', credentials: 'include' }); } catch { }
        clearAuthSession();
        setUser(null);
        setAuthStep('login');
      }}
      onServerChanged={handleServerChanged}
      allowedTabs={allowedTabs}
      showCostPrice={showCostPrice}
    />
  );
}
