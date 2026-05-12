import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { login, setAuthSession, getAuthSession } from '../../api/auth';
import BumbleInput from '../Forms/BumbleInput';

function ActiveServerBar({ onGoToServerConfig }) {
  const activeServer = (() => {
    try {
      const servers = JSON.parse(localStorage.getItem('servers') || '[]');
      return servers.find(s => s.id === localStorage.getItem('activeServer')) || null;
    } catch { return null; }
  })();

  return (
    <div className="flex items-center justify-between mb-6 px-1">
      <div className="min-w-0">
        <p className="text-sm text-text-secondary">当前服务器</p>
        {activeServer ? (
          <>
            <p className="text-base font-semibold text-text-primary truncate">{activeServer.name}</p>
            <p className="text-sm text-text-secondary truncate">{activeServer.url}</p>
          </>
        ) : (
          <p className="text-sm text-text-secondary">未配置</p>
        )}
      </div>
      <motion.button
        type="button"
        whileTap={{ scale: 0.96 }}
        onClick={onGoToServerConfig}
        className="ml-3 text-sm font-semibold text-text-secondary shrink-0 px-3 py-1.5 bg-gray-100 rounded-full"
      >
        更换服务器
      </motion.button>
    </div>
  );
}

export default function LoginPage({ onLogin, onGoToServerConfig }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const result = await login(username, password);
      if (result && result.success) {
        const userData = result.data || {};
        setAuthSession({ username, profile: userData });
        onLogin({ id: username, username, profile: userData });
      } else {
        setError('用户名或密码错误');
      }
    } catch (err) {
      setError(err.message || '登录失败，请重试');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const session = getAuthSession();
    if (session) {
      onLogin({ id: session.username, username: session.username, profile: session.profile });
    }
  }, []);

  return (
    <div className="h-full flex flex-col items-center justify-center px-8 bg-brand-yellow">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
        className="w-full max-w-sm bg-white rounded-3xl p-8"
      >
        <h1 className="text-3xl font-bold text-text-primary text-center mb-6">登录</h1>

        <ActiveServerBar onGoToServerConfig={onGoToServerConfig} />

        <form onSubmit={handleSubmit} className="space-y-2">
          <BumbleInput
            label="用户名"
            type="text"
            value={username}
            onChange={e => setUsername(e.target.value)}
          />
          <BumbleInput
            label="密码"
            type="password"
            value={password}
            onChange={e => setPassword(e.target.value)}
          />

          {error && (
            <p className="text-action-black text-sm text-center font-semibold">{error}</p>
          )}

          <motion.button
            type="submit"
            disabled={loading}
            whileTap={{ scale: 0.96 }}
            className="w-full py-3.5 bg-action-black text-white font-semibold rounded-full text-base disabled:opacity-50"
          >
            {loading ? '登录中...' : '登录'}
          </motion.button>
        </form>
      </motion.div>
    </div>
  );
}
