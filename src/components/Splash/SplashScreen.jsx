import { motion } from 'framer-motion';
import { Package } from 'lucide-react';
import { useEffect, useState } from 'react';

export default function SplashScreen({ onFinish }) {
  const [exiting, setExiting] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setExiting(true), 2200);
    const finishTimer = setTimeout(() => onFinish(), 2600);
    return () => { clearTimeout(timer); clearTimeout(finishTimer); };
  }, [onFinish]);

  return (
    <motion.div
      initial={{ opacity: 1 }}
      animate={{ opacity: exiting ? 0 : 1 }}
      transition={{ duration: 0.4 }}
      className="fixed inset-0 bg-brand-yellow flex flex-col items-center justify-center z-[100]"
    >
      <motion.div
        animate={{
          scale: [0.9, 1.15, 0.95, 1.1, 0.9],
        }}
        transition={{
          duration: 1.8,
          repeat: Infinity,
          ease: 'easeInOut',
        }}
        className="text-white"
      >
        <Package size={80} strokeWidth={1.5} />
      </motion.div>
      <motion.p
        animate={{ opacity: [0.5, 1, 0.5] }}
        transition={{ duration: 1.5, repeat: Infinity }}
        className="mt-6 text-white text-lg font-semibold tracking-wider"
      >
        仓库管理
      </motion.p>
    </motion.div>
  );
}
