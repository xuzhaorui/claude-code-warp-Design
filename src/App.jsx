import { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { SplashScreen } from './components/Splash';
import LoginPage from './components/Login/LoginPage';
import AppShell from './pages/AppShell';

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

  if (!hasServer && !user) {
    return <SetupFlow onLogin={(u) => setUser(u)} />;
  }

  if (!user) {
    return (
      <div className="h-screen">
        <LoginPage onLogin={(u) => setUser(u)} />
      </div>
    );
  }

  return <AppShell onLogout={() => setUser(null)} />;
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
    <div className="px-5 space-y-4">
      <div>
        <label className="text-xs font-semibold text-text-secondary mb-1 block">服务器名称</label>
        <input
          value={name}
          onChange={e => setName(e.target.value)}
          placeholder="如：公司主服务器"
          className="w-full px-4 py-3 bg-bg-secondary rounded-2xl text-sm"
        />
      </div>
      <div>
        <label className="text-xs font-semibold text-text-secondary mb-1 block">IP 地址</label>
        <input
          value={url}
          onChange={e => setUrl(e.target.value)}
          placeholder="如：192.168.1.100"
          className="w-full px-4 py-3 bg-bg-secondary rounded-2xl text-sm"
        />
      </div>
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
