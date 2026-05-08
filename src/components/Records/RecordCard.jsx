import { motion } from 'framer-motion';
import { ChevronRight } from 'lucide-react';

export default function RecordCard({ icon: Icon, badge, title, subtitle, extra, onClick, index = 0 }) {
  return (
    <motion.button
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.05, duration: 0.25 }}
      whileTap={{ scale: 0.96 }}
      onClick={onClick}
      className="w-full flex items-center gap-3 px-4 py-3 bg-white active:bg-gray-50 border-b border-gray-100 text-left"
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

      <ChevronRight size={16} className="text-text-secondary shrink-0" />
    </motion.button>
  );
}
