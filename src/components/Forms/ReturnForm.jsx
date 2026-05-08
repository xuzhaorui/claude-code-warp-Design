import { useState } from 'react';
import { motion } from 'framer-motion';

export default function ReturnForm({ borrowRecord, operatorName, onSubmit, onClose }) {
  const [returnQty, setReturnQty] = useState('');
  const [remark, setRemark] = useState('');

  const qty = Number(returnQty) || 0;
  const overQty = qty > borrowRecord.borrowQty;
  const canSubmit = qty > 0 && !overQty;

  const handleSubmit = () => {
    if (!canSubmit) return;
    onSubmit({
      id: 'rt-' + Date.now(),
      borrowRecordId: borrowRecord.id,
      itemId: borrowRecord.itemId,
      itemName: borrowRecord.itemName,
      warehouse: borrowRecord.warehouse,
      code: borrowRecord.code,
      spec: borrowRecord.spec,
      costPrice: borrowRecord.costPrice,
      returnQty: qty,
      borrower: borrowRecord.borrower,
      operatorId: JSON.parse(localStorage.getItem('currentUser') || '{}').id,
      operatorName,
      time: new Date().toLocaleString('zh-CN', { hour12: false }).replace(/\//g, '-'),
      remark,
    });
  };

  return (
    <div className="space-y-4">
      <div className="bg-bg-secondary rounded-2xl p-4 space-y-2">
        <InfoRow label="货物名称" value={borrowRecord.itemName} />
        <InfoRow label="外借人" value={borrowRecord.borrower} />
        <InfoRow label="仓库名称" value={borrowRecord.warehouse} />
        <InfoRow label="在借数量" value={borrowRecord.borrowQty} />
        <InfoRow label="成本单价" value={`¥${borrowRecord.costPrice.toFixed(2)}`} />
      </div>

      <div>
        <label className="text-xs font-semibold text-text-secondary mb-1 block">归还数量</label>
        <input
          type="number"
          min="1"
          max={borrowRecord.borrowQty}
          value={returnQty}
          onChange={e => setReturnQty(e.target.value)}
          placeholder="请输入归还数量"
          className="w-full px-4 py-3 bg-bg-secondary rounded-2xl text-sm"
        />
        {overQty && (
          <p className="text-red-500 text-xs mt-1">归还数量超过在借数量（在借: {borrowRecord.borrowQty}）</p>
        )}
      </div>

      <div>
        <label className="text-xs font-semibold text-text-secondary mb-1 block">归还备注（选填）</label>
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
        确认归还
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
