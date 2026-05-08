import { useState } from 'react';
import { motion } from 'framer-motion';
import { ChevronRight, LogOut, Server } from 'lucide-react';
import ServerConfig from './ServerConfig';

export default function SettingsTab({ onLogout }) {
  const [showServerConfig, setShowServerConfig] = useState(false);

  if (showServerConfig) {
    return <ServerConfig onBack={() => setShowServerConfig(false)} />;
  }

  return (
    <div className="h-full flex flex-col bg-bg-main">
      <div className="px-5 pt-6 pb-4">
        <h1 className="text-2xl font-bold text-text-primary">设置</h1>
      </div>

      <div className="flex-1">
        <motion.button
          whileTap={{ scale: 0.96 }}
          onClick={() => setShowServerConfig(true)}
          className="w-full flex items-center gap-3 px-5 py-4 border-b border-gray-100 active:bg-gray-50"
        >
          <div className="w-10 h-10 rounded-lg bg-bg-secondary flex items-center justify-center">
            <Server size={20} className="text-action-black" />
          </div>
          <div className="flex-1 text-left">
            <p className="text-sm font-bold text-text-primary">服务器配置</p>
            <p className="text-xs text-text-secondary">管理连接的服务器地址</p>
          </div>
          <ChevronRight size={18} className="text-text-secondary" />
        </motion.button>
      </div>

      <div className="p-5">
        <motion.button
          whileTap={{ scale: 0.96 }}
          onClick={onLogout}
          className="w-full py-3.5 border border-red-200 text-red-500 font-semibold rounded-full text-sm"
        >
          退出登录
        </motion.button>
      </div>
    </div>
  );
}
