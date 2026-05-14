import { useState } from 'react';
import { motion } from 'framer-motion';
import ServerConfig from '../components/Settings/ServerConfig';

export default function ServerSetupScreen({ onConfirmed }) {
  const [activeId, setActiveId] = useState(() => localStorage.getItem('activeServer') || '');

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ type: 'spring', stiffness: 200, damping: 25 }}
      className="h-full flex flex-col"
    >
      <div className="flex-1 overflow-hidden">
        <ServerConfig
          hideBackButton
          onActiveIdChange={setActiveId}
        />
      </div>

      <div className="px-5 pt-5 pb-8 bg-white border-t border-gray-100 shrink-0">
        <motion.button
          whileTap={{ scale: 0.96 }}
          onClick={onConfirmed}
          disabled={!activeId}
          className="w-full py-3.5 bg-action-black text-white font-semibold rounded-full text-sm disabled:opacity-40"
        >
          继续
        </motion.button>
      </div>
    </motion.div>
  );
}
