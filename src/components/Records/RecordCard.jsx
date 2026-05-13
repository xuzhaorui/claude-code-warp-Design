import { motion } from 'framer-motion';
import { ChevronRight } from 'lucide-react';

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

export default function RecordCard({ icon: Icon, title, subtitle, extra, status, onClick, index = 0 }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.05, duration: 0.25 }}
      className="bg-white"
      style={{ border: '1px solid #EEEEEE', borderRadius: '16px', boxShadow: '0 2px 8px rgba(0,0,0,0.05)', overflow: 'hidden' }}
    >
      <div className="flex items-center" style={{ gap: '12px', padding: '16px 16px' }}>
        <div className="shrink-0 flex items-center justify-center rounded-full" style={{ width: '44px', height: '44px', background: '#1A1A1A' }}>
          <Icon size={20} className="text-white" strokeWidth={1.5} />
        </div>
        <div className="flex-1 min-w-0" style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
          <p className="truncate" style={{ fontSize: '15px', fontWeight: 700, color: '#1A1A1A' }}>{title}</p>
          <p className="truncate" style={{ fontSize: '13px', fontWeight: 400, color: '#888888' }}>{subtitle}</p>
          {extra && <p className="truncate" style={{ fontSize: '13px', fontWeight: 400, color: '#888888' }}>{extra}</p>}
        </div>
        {status && <StatusPill status={status} />}
      </div>
      <motion.div
        onTap={onClick}
        whileTap={{ scale: 0.98, opacity: 0.7 }}
        className="flex items-center justify-center cursor-pointer"
        style={{ borderTop: '1px solid #F0F0F0', padding: '10px 0', color: '#888888', fontSize: '13px' }}
      >
        <span>查看详情</span>
        <ChevronRight size={14} style={{ marginLeft: '4px' }} />
      </motion.div>
    </motion.div>
  );
}
