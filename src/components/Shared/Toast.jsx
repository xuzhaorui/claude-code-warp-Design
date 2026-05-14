import { useState, useEffect, useCallback, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { CheckCircle } from 'lucide-react';

let showFn = null;

export function showToast(message) {
  showFn?.(message);
}

export default function Toast() {
  const [visible, setVisible] = useState(false);
  const [message, setMessage] = useState('');
  const timerRef = useRef(null);

  useEffect(() => {
    showFn = (msg) => {
      clearTimeout(timerRef.current);
      setMessage(msg);
      setVisible(true);
      timerRef.current = setTimeout(() => setVisible(false), 2000);
    };
    return () => { showFn = null; clearTimeout(timerRef.current); };
  }, []);

  return (
    <AnimatePresence>
      {visible && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: 20 }}
          transition={{ duration: 0.2 }}
          className="fixed bottom-24 left-1/2 -translate-x-1/2 z-[100] flex items-center gap-2 bg-action-black text-white px-5 py-3 rounded-full shadow-lg"
        >
          <CheckCircle size={20} />
          <span className="text-base font-semibold">{message}</span>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
