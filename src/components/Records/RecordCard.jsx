import { useState, useRef, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronRight, Check, X } from 'lucide-react';

const STATUS_COLORS = {
  '正常': { background: '#C8E6C9', color: '#2E7D32' },
  '已完成': { background: '#C8E6C9', color: '#2E7D32' },
  '异常': { background: '#FFCDD2', color: '#C62828' },
  '亏损': { background: '#FFCDD2', color: '#C62828' },
  '已撤销': { background: '#FFCDD2', color: '#C62828' },
  '进行中': { background: '#FFC629', color: '#1A1A1A' },
  '待处理': { background: '#E5E5E5', color: '#666666' },
};

function StatusPill({ status }) {
  const style = STATUS_COLORS[status] ?? { background: '#E5E5E5', color: '#666666' };
  return (
    <span
      className="text-[11px] font-semibold px-2 py-0.5 rounded-full shrink-0"
      style={style}
    >
      {status}
    </span>
  );
}

const SWIPE_THRESHOLD = 100;
const SPRING = { type: 'spring', stiffness: 200, damping: 25, mass: 1 };

export default function RecordCard({ icon: Icon, badge, title, subtitle, extra, status, onClick, onSwipeLeft, onSwipeRight, index = 0 }) {
  const [dismissed, setDismissed] = useState(false);
  const isDragging = useRef(false);
  const hasTriggeredHaptic = useRef({ left: false, right: false });

  const handleDrag = useCallback((_, info) => {
    if (info.offset.x > SWIPE_THRESHOLD && !hasTriggeredHaptic.current.right) {
      hasTriggeredHaptic.current.right = true;
      hasTriggeredHaptic.current.left = false;
      try { navigator.vibrate?.([50]); } catch {}
    } else if (info.offset.x < -SWIPE_THRESHOLD && !hasTriggeredHaptic.current.left) {
      hasTriggeredHaptic.current.left = true;
      hasTriggeredHaptic.current.right = false;
      try { navigator.vibrate?.([50]); } catch {}
    } else if (Math.abs(info.offset.x) < SWIPE_THRESHOLD) {
      hasTriggeredHaptic.current.left = false;
      hasTriggeredHaptic.current.right = false;
    }
  }, []);

  const handleDragEnd = useCallback((_, info) => {
    if (info.offset.x > SWIPE_THRESHOLD || info.velocity.x > 500) {
      setDismissed('right');
    } else if (info.offset.x < -SWIPE_THRESHOLD || info.velocity.x < -500) {
      setDismissed('left');
    }
    hasTriggeredHaptic.current = { left: false, right: false };
  }, []);

  const handleDragStart = useCallback(() => {
    hasTriggeredHaptic.current = { left: false, right: false };
    isDragging.current = false;
  }, []);

  const handleClick = useCallback((e) => {
    if (isDragging.current) {
      e.preventDefault();
      e.stopPropagation();
      return;
    }
    onClick?.();
  }, [onClick]);

  const handleDirectionLock = useCallback((_, info) => {
    if (Math.abs(info.offset.x) > 5 || Math.abs(info.offset.y) > 5) {
      isDragging.current = true;
    }
  }, []);

  const onDismissComplete = useCallback(() => {
    if (dismissed === 'right') onSwipeRight?.();
    if (dismissed === 'left') onSwipeLeft?.();
    setDismissed(false);
  }, [dismissed, onSwipeLeft, onSwipeRight]);

  const exitX = dismissed === 'right' ? '100%' : dismissed === 'left' ? '-100%' : 0;

  return (
    <AnimatePresence onExitComplete={onDismissComplete}>
      {!dismissed && (
        <motion.div
          layout
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ x: exitX, opacity: 0, transition: { duration: 0.25 } }}
          transition={{ delay: index * 0.05, duration: 0.25 }}
          className="relative overflow-hidden border-b border-gray-100"
        >
          {/* Right swipe underlay (confirm) */}
          <div className="absolute inset-0 bg-brand-yellow flex items-center justify-start pl-5">
            <Check size={24} className="text-action-black" strokeWidth={3} />
          </div>

          {/* Left swipe underlay (cancel/exception) */}
          <div className="absolute inset-0 bg-red-500 flex items-center justify-end pr-5">
            <X size={24} className="text-white" strokeWidth={3} />
          </div>

          {/* Draggable content */}
          <motion.div
            drag="x"
            dragConstraints={{ left: 0, right: 0 }}
            dragElastic={0.15}
            onDragStart={handleDragStart}
            onDrag={handleDrag}
            onDragEnd={handleDragEnd}
            onDirectionLock={handleDirectionLock}
            onClick={handleClick}
            whileTap={{ scale: 0.98 }}
            className="relative z-10 flex items-center gap-3 px-4 py-3 bg-white cursor-pointer"
          >
            <div className="relative shrink-0">
              <div className="w-10 h-10 rounded-lg bg-bg-secondary flex items-center justify-center">
                <Icon size={20} className="text-action-black" />
              </div>
              {badge !== undefined && badge !== null && (
                <span className="absolute -top-1.5 -right-1.5 min-w-[18px] h-[18px] flex items-center justify-center bg-brand-yellow text-action-black text-[10px] font-semibold rounded-full px-1">
                  {badge}
                </span>
              )}
            </div>

            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-text-primary truncate">{title}</p>
              <p className="text-xs text-text-secondary truncate mt-0.5">{subtitle}</p>
              {extra && <p className="text-xs text-text-secondary truncate mt-0.5">{extra}</p>}
            </div>

            {status ? <StatusPill status={status} /> : <ChevronRight size={16} className="text-text-secondary shrink-0" />}
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
