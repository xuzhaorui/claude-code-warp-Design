import { useState, useRef, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronRight, Check, X } from 'lucide-react';

const STATUS_COLORS = {
  '正常':   { background: '#F0F0F0', color: '#888888' },
  '已完成': { background: '#F0F0F0', color: '#888888' },
  '异常':   { background: '#1A1A1A', color: '#FFFFFF' },
  '亏损':   { background: '#1A1A1A', color: '#FFFFFF' },
  '已撤销': { background: '#FFF0F0', color: '#FF4444' },
  '进行中': { background: '#F0F0F0', color: '#888888' },
  '待处理': { background: '#F0F0F0', color: '#888888' },
};

function StatusPill({ status }) {
  const style = STATUS_COLORS[status] ?? { background: '#F0F0F0', color: '#888888' };
  return (
    <span
      className="font-normal rounded-full shrink-0"
      style={{ ...style, padding: '4px 10px', fontSize: '12px' }}
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
          className="relative overflow-hidden rounded-2xl"
        >
          {/* Right swipe underlay (confirm) */}
          <div className="absolute inset-0 flex items-center justify-start pl-5" style={{ background: '#FFC629' }}>
            <Check size={24} strokeWidth={3} style={{ color: '#1A1A1A' }} />
          </div>

          {/* Left swipe underlay (cancel/exception) */}
          <div className="absolute inset-0 flex items-center justify-end pr-5" style={{ background: '#1A1A1A' }}>
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
            className="relative z-10 flex items-center bg-white cursor-pointer"
            style={{ gap: '12px', padding: '16px 16px', border: '1px solid #EEEEEE', borderRadius: '16px', boxShadow: '0 2px 8px rgba(0,0,0,0.05)' }}
          >
            <div className="shrink-0 flex items-center justify-center rounded-full" style={{ width: '44px', height: '44px', background: '#1A1A1A' }}>
              <Icon size={20} className="text-white" strokeWidth={1.5} />
            </div>

            <div className="flex-1 min-w-0" style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
              <p className="truncate" style={{ fontSize: '15px', fontWeight: 700, color: '#1A1A1A' }}>{title}</p>
              <p className="truncate" style={{ fontSize: '13px', fontWeight: 400, color: '#888888' }}>{subtitle}</p>
              {extra && <p className="truncate" style={{ fontSize: '13px', fontWeight: 400, color: '#888888' }}>{extra}</p>}
            </div>

            {status ? <StatusPill status={status} /> : <ChevronRight size={16} className="text-text-secondary shrink-0" />}
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
