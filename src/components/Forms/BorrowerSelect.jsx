import { motion } from 'framer-motion';

export default function BorrowerSelect({ borrowers, onSelect }) {
  if (borrowers.length === 0) {
    return (
      <div className="text-center py-8">
        <p className="text-sm text-text-secondary">该货物暂无外借记录</p>
      </div>
    );
  }

  return (
    <div className="space-y-2">
      <p className="text-xs text-text-secondary mb-2">选择需要归还的外借记录：</p>
      {borrowers.map((b, idx) => (
        <motion.button
          key={b.id}
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: idx * 0.05 }}
          whileTap={{ scale: 0.96 }}
          onPointerDown={() => onSelect(b)}
          className="w-full bg-bg-secondary rounded-2xl p-4 text-left active:bg-gray-100"
        >
          <div className="flex justify-between items-center mb-1">
            <span className="text-sm font-bold text-text-primary">{b.itemName}</span>
            <span className="text-xs bg-brand-yellow/20 text-action-black px-2 py-0.5 rounded-full font-semibold">
              借 {b.borrowQty} 个
            </span>
          </div>
          <p className="text-xs text-text-secondary">外借人：{b.borrower}</p>
          <p className="text-xs text-text-secondary">仓库：{b.warehouse}</p>
          <p className="text-xs text-text-secondary">借出时间：{b.borrowTime}</p>
        </motion.button>
      ))}
    </div>
  );
}
