import { useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X } from 'lucide-react';

const springConfig = { type: 'spring', stiffness: 200, damping: 25, mass: 1 };

export default function DetailSheet({ isOpen, onClose, title, children }) {
  const heightRef = useRef(null);

  useEffect(() => {
    if (isOpen && !heightRef.current) {
      heightRef.current = window.innerHeight * 0.9;
    }
    if (!isOpen) {
      heightRef.current = null;
    }
  }, [isOpen]);

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 0.5 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 bg-black z-40"
            onClick={onClose}
          />
          <motion.div
            initial={{ y: '-100%' }}
            animate={{ y: 0 }}
            exit={{ y: '-100%' }}
            transition={springConfig}
            drag="y"
            dragConstraints={{ bottom: 0 }}
            dragElastic={0.15}
            onDragEnd={(_, info) => {
              if (info.offset.y < -150 || info.velocity.y < -500) onClose();
            }}
            className="fixed top-0 left-0 right-0 bg-white rounded-b-3xl z-50 flex flex-col"
            style={{ maxHeight: heightRef.current ? `${heightRef.current}px` : '90vh' }}
          >
            <div className="flex flex-col items-center pt-3 pb-2 border-b border-gray-100 shrink-0">
              <div className="w-10 h-1 rounded-full bg-gray-300 mb-3" />
              <div className="flex items-center justify-between w-full px-5">
                <h2 className="text-lg font-bold text-text-primary">{title}</h2>
                <button onClick={onClose} className="p-1 -mr-1 active:bg-gray-100 rounded-full">
                  <X size={20} className="text-text-secondary" />
                </button>
              </div>
            </div>
            <div className="overflow-y-auto hide-scrollbar px-5 py-4">
              {children}
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
