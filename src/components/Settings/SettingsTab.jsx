import { useState } from 'react';
import { motion } from 'framer-motion';
import { ChevronRight } from 'lucide-react';
import ServerConfig from './ServerConfig';

export default function SettingsTab({ onLogout, onServerChanged }) {
  const [showServerConfig, setShowServerConfig] = useState(false);

  if (showServerConfig) {
    return <ServerConfig onBack={() => setShowServerConfig(false)} onServerChanged={onServerChanged} />;
  }

  return (
    <div className="h-full flex flex-col bg-bg-main">
      <div className="px-5 pt-6 pb-4">
        <h1 className="text-2xl font-bold text-text-primary">设置</h1>
      </div>

      <div className="flex-1 px-5 flex flex-col gap-2">
        <motion.button
          whileTap={{ scale: 0.98 }}
          onClick={() => setShowServerConfig(true)}
          className="w-full flex items-center justify-between bg-white rounded-2xl px-4 py-3.5 border border-gray-100 active:bg-gray-50"
        >
          <div className="text-left">
            <p className="text-base font-bold text-text-primary">服务器配置</p>
            <p className="text-sm text-text-secondary mt-0.5">管理连接的服务器地址</p>
          </div>
          <ChevronRight size={18} className="text-text-secondary flex-shrink-0" />
        </motion.button>
      </div>

      <div className="px-5 pb-5">
        <motion.button
          whileTap={{ scale: 0.96 }}
          onClick={onLogout}
          className="w-full py-3.5 bg-action-black text-white font-semibold rounded-full text-base"
        >
          退出登录
        </motion.button>
      </div>
    </div>
  );
}
