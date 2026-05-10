import { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { SplashScreen } from './components/Splash';
import LoginPage from './components/Login/LoginPage';
import AppShell from './pages/AppShell';
import BumbleInput from './components/Forms/BumbleInput';
import { setAuthExpiredHandler, handleAuthExpired, isAuthenticated, clearAuthSession } from './api/auth';
import { setApiBaseUrl } from './api/config';

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
  const [user, setUser] = useState(() => {
    try { return JSON.parse(localStorage.getItem('currentUser')); } catch { return null; }
  });

  const hasServer = (() => {
    try {
      const servers = JSON.parse(localStorage.getItem('servers') || '[]');
      return servers.length > 0;
    } catch { return false; }
  })();

  useEffect(() => {
    const handleSessionExpired = () => {
      clearAuthSession();
      setUser(null);
    };

    const servers = JSON.parse(localStorage.getItem('servers') || '[]');
    if (servers.length > 0) {
      const activeServerId = localStorage.getItem('activeServer');
      const activeServer = servers.find(s => s.id === activeServerId);
      if (activeServer) {
        setApiBaseUrl(activeServer.url);
      }
    }

    setAuthExpiredHandler(handleSessionExpired);

    if (!isAuthenticated()) {
      return;
    }

    if (!hasServer && !user) {
      return <SetupFlow onLogin={(u) => setUser(u)} />;
    }

    if (!user) {
      return (
        <div className="h-screen">
          <LoginPage onLogin={(u) => setUser(u)} onSessionExpired={handleAuthExpired} />
        </div>
      );
    }

    return <AppShell onLogout={() => { handleAuthExpired(); setUser(null); }} />;
  }, []);

  if (!isAuthenticated()) {
    return (
      <div className="h-screen">
        <LoginPage onLogin={(u) => setUser(u)} onSessionExpired={handleAuthExpired} />
      </div>
    );
  }

  return <AppShell onLogout={() => { handleAuthExpired(); setUser(null); }} />;
}

function SetupFlow({ onLogin }) {
  const [step, setStep] = useState('settings');

  if (step === 'settings') {
    return (
      <div className="h-screen">
        <div className="h-full flex flex-col">
          <div className="px-5 pt-6 pb-4">
            <h1 className="text-2xl font-bold text-text-primary">欢迎使用</h1>
            <p className="text-sm text-text-secondary mt-1">请先配置服务器地址</p>
          </div>
          <div className="flex-1">
            <ServerSetupForm onFinish={() => setStep('login')} />
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="h-screen">
      <LoginPage onLogin={onLogin} />
    </div>
  );
}

function ServerSetupForm({ onFinish }) {
  const [name, setName] = useState('');
  const [url, setUrl] = useState('');

  const handleAdd = () => {
    if (!name.trim() || !url.trim()) return;
    const newServer = { id: 'srv-' + Date.now(), name: name.trim(), url: url.trim() };
    localStorage.setItem('servers', JSON.stringify([newServer]));
    localStorage.setItem('activeServer', newServer.id);
    setTimeout(() => onFinish(), 300);
  };

  return (
    <div className="px-5 pt-2">
      <BumbleInput
        label="服务器名称"
        value={name}
        onChange={e => setName(e.target.value)}
      />
      <BumbleInput
        label="IP 地址"
        value={url}
        onChange={e => setUrl(e.target.value)}
      />
      <button
        onClick={handleAdd}
        disabled={!name.trim() || !url.trim()}
        className="w-full py-3 bg-action-black text-white font-semibold rounded-full text-sm disabled:opacity-40"
      >
        保存并继续
      </button>
    </div>
  );
}
