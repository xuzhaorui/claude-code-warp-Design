import { useState, useRef, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { RotateCw, ChevronUp } from 'lucide-react';

export default function PullToRefresh({ onRefresh, isRefreshing, children, className }) {
  const [pullDistance, setPullDistance] = useState(0);
  const [isPulling, setIsPulling] = useState(false);
  const startY = useRef(0);
  const threshold = 80;

  const handleTouchStart = (e) => {
    const el = e.currentTarget;
    if (el.scrollTop > 0) return;
    const touch = e.touches[0];
    startY.current = touch.clientY;
    setIsPulling(true);
  };

  const handleTouchMove = (e) => {
    if (!isPulling || isRefreshing) return;

    const touch = e.touches[0];
    const currentY = touch.clientY;
    const distance = currentY - startY.current;

    if (distance > 0) {
      const dampedDistance = distance * 0.4;
      const clampedDistance = Math.min(dampedDistance, threshold + 20);
      setPullDistance(clampedDistance);
    }
  };

  const handleTouchEnd = useCallback(() => {
    setIsPulling(false);

    if (pullDistance >= threshold && !isRefreshing) {
      onRefresh();
    }

    setPullDistance(0);
  }, [pullDistance, threshold, isRefreshing, onRefresh]);

  return (
    <div
      className={`relative overflow-hidden ${className || ''}`}
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onTouchEnd={handleTouchEnd}
    >
      <AnimatePresence>
        {(pullDistance > 0 || isRefreshing) && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="absolute left-0 right-0 flex items-center justify-center gap-2"
            style={{
              top: `${Math.min(pullDistance, threshold + 10)}px`,
              opacity: Math.min(pullDistance / threshold, 1),
            }}
          >
            {isRefreshing ? (
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ repeat: Infinity, duration: 0.8, ease: 'linear' }}
              >
                <RotateCw size={20} className="text-brand-yellow" />
              </motion.div>
            ) : (
              <motion.div
                animate={{ rotate: pullDistance >= threshold ? 180 : 0 }}
                transition={{ duration: 0.2 }}
              >
                <ChevronUp size={20} className="text-brand-yellow" />
              </motion.div>
            )}
            <span className="text-sm font-semibold text-text-secondary">
              {isRefreshing ? '刷新中...' : pullDistance >= threshold ? '释放刷新' : '下拉刷新'}
            </span>
          </motion.div>
        )}
      </AnimatePresence>

      <motion.div
        animate={{ y: pullDistance }}
        transition={{ duration: 0.1 }}
        className="w-full"
      >
        {children}
      </motion.div>
    </div>
  );
}
