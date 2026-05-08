import { useState } from 'react';
import { motion } from 'framer-motion';

export default function InventoryCheckForm({ item, operatorName, onSubmit, onClose }) {
  const [actualQty, setActualQty] = useState('');
  const [remark, setRemark] = useState('');

  const bookQty = item.stockQty;
  const actual = Number(actualQty) || 0;
  const difference = actual - bookQty;
  const canSubmit = actualQty !== '';

  const handleSubmit = () => {
    if (!canSubmit) return;
    onSubmit({
      id: 'ic-' + Date.now(),
      itemId: item.id,
      itemName: item.name,
      warehouse: item.warehouse,
      code: item.code,
      spec: item.spec,
      bookQty,
      actualQty: actual,
      difference,
      remark,
      operatorId: JSON.parse(localStorage.getItem('currentUser') || '{}').id,
      operatorName,
      time: new Date().toLocaleString('zh-CN', { hour12: false }).replace(/\//g, '-'),
    });
  };

  return (
    <div className="space-y-4">
      <div className="bg-bg-secondary rounded-2xl p-4 space-y-2">
        <InfoRow label="货物名称" value={item.name} />
        <InfoRow label="仓库编号" value={item.code} />
        <InfoRow label="规格" value={item.spec} />
        <InfoRow label="账面数量" value={bookQty} />
      </div>

      <div>
        <label className="text-xs font-semibold text-text-secondary mb-1 block">盘点真实数量</label>
        <input
          type="number"
          min="0"
          value={actualQty}
          onChange={e => setActualQty(e.target.value)}
          placeholder="请输入实际盘点数量"
          className="w-full px-4 py-3 bg-bg-secondary rounded-2xl text-sm"
        />
      </div>

      {actualQty !== '' && (
        <div className="bg-bg-secondary rounded-2xl px-4 py-3 flex justify-between items-center">
          <span className="text-sm text-text-secondary">差值</span>
          <span className={`text-lg font-bold ${difference > 0 ? 'text-green-600' : difference < 0 ? 'text-red-500' : 'text-text-primary'}`}>
            {difference > 0 ? `+${difference}` : difference}
          </span>
        </div>
      )}

      <div>
        <label className="text-xs font-semibold text-text-secondary mb-1 block">盘点备注（选填）</label>
        <input
          value={remark}
          onChange={e => setRemark(e.target.value)}
          placeholder="可选填写备注"
          className="w-full px-4 py-3 bg-bg-secondary rounded-2xl text-sm"
        />
      </div>

      <motion.button
        whileTap={{ scale: 0.96 }}
        onClick={handleSubmit}
        disabled={!canSubmit}
        className="w-full py-3.5 bg-action-black text-white font-semibold rounded-full text-sm disabled:opacity-40"
      >
        提交盘点
      </motion.button>
    </div>
  );
}

function InfoRow({ label, value }) {
  return (
    <div className="flex justify-between text-sm">
      <span className="text-text-secondary">{label}</span>
      <span className="font-semibold text-text-primary">{value}</span>
    </div>
  );
}
