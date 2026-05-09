import { useState } from 'react';
import { motion } from 'framer-motion';
import { mockLogin } from '../../data/mockData';
import BumbleInput from '../Forms/BumbleInput';

export default function LoginPage({ onLogin }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const user = await mockLogin(username, password);
      if (user) {
        localStorage.setItem('currentUser', JSON.stringify(user));
        onLogin(user);
      } else {
        setError('登录失败，请重试');
      }
    } catch {
      setError('登录失败，请重试');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="h-full flex flex-col items-center justify-center px-8 bg-bg-secondary">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
        className="w-full max-w-sm bg-white rounded-3xl p-8"
      >
        <h1 className="text-2xl font-bold text-text-primary text-center mb-8">登录</h1>

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
            <p className="text-red-500 text-xs text-center">{error}</p>
          )}

          <motion.button
            type="submit"
            disabled={loading}
            whileTap={{ scale: 0.96 }}
            className="w-full py-3.5 bg-action-black text-white font-semibold rounded-full text-sm disabled:opacity-50"
          >
            {loading ? '登录中...' : '登录'}
          </motion.button>
        </form>

        <p className="text-xs text-text-secondary text-center mt-6">
          任意账号密码均可登录
        </p>
      </motion.div>
    </div>
  );
}
