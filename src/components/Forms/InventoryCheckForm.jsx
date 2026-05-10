import { useState } from 'react';
import { motion } from 'framer-motion';
import Stepper from './Stepper';
import BumbleInput from './BumbleInput';

export default function InventoryCheckForm({ item, operatorName, onSubmit, onClose }) {
  const [actualQty, setActualQty] = useState(item.stockQty);
  const [remark, setRemark] = useState('');

  const bookQty = item.stockQty;
  const actual = actualQty;
  const difference = actual - bookQty;
  const canSubmit = true;

  const handleSubmit = () => {
    if (!canSubmit) return;
    onSubmit({
      id: 'ic-' + Date.now(),
      itemId: item.id,
      itemName: item.name,
      warehouse: item.warehouse,
      code: item.code,
      spec: item.spec,
      costPrice: item.costPrice,
      bookQty,
      actualQty: actualQty,
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
        <label className="text-xs font-semibold text-text-secondary mb-2 block">盘点真实数量</label>
        <Stepper
          value={actualQty}
          onChange={setActualQty}
          min={0}
          max={99999}
        />
      </div>

      <div className="bg-bg-secondary rounded-2xl px-4 py-3 flex justify-between items-center">
        <span className="text-sm text-text-secondary">差值</span>
        <span className={`text-lg font-bold ${difference > 0 ? 'text-green-600' : difference < 0 ? 'text-red-500' : 'text-text-primary'}`}>
          {difference > 0 ? `+${difference}` : difference}
        </span>
      </div>

      <BumbleInput
        label="盘点备注（选填）"
        value={remark}
        onChange={e => setRemark(e.target.value)}
      />

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
