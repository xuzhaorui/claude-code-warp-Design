import { motion } from 'framer-motion';
import { ChevronRight } from 'lucide-react';

const STATUS_COLORS = {
  '正常':   { background: '#F0F0F0', color: '#888888' },
  '已完成': { background: '#F0F0F0', color: '#888888' },
  '异常':   { background: '#60A5FA', color: '#FFFFFF' },
  '亏损':   { background: '#60A5FA', color: '#FFFFFF' },
  '已撤销': { background: '#FFF0F0', color: '#FF4444' },
  '进行中': { background: '#F0F0F0', color: '#888888' },
  '待处理': { background: '#F0F0F0', color: '#888888' },
};

export default function RecordCard({ title, detail, status, onClick, index = 0 }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.05, duration: 0.25 }}
      className="flex items-center bg-white"
      style={{ gap: '12px', padding: '16px 16px', border: '1px solid #EEEEEE', borderRadius: '16px', boxShadow: '0 2px 8px rgba(0,0,0,0.05)' }}
    >
      <div className="flex-1 min-w-0" style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
        <div className="flex items-center gap-2">
          <p className="truncate" style={{ fontSize: '16px', fontWeight: 700, color: '#60A5FA' }}>{title}</p>
          {status && (
            <span
              className="shrink-0 rounded-full"
              style={{ ...STATUS_COLORS[status], padding: '3px 8px', fontSize: '12px' }}
            >
              {status}
            </span>
          )}
        </div>
        <p className="truncate" style={{ fontSize: '15px', fontWeight: 600, color: '#60A5FA' }}>{detail}</p>
      </div>
      <motion.div
        onTap={onClick}
        whileTap={{ scale: 0.9 }}
        className="shrink-0 flex items-center justify-center rounded-full cursor-pointer"
        style={{ width: '36px', height: '36px', background: '#60A5FA' }}
      >
        <ChevronRight size={18} style={{ color: '#60A5FA' }} />
      </motion.div>
    </motion.div>
  );
}
