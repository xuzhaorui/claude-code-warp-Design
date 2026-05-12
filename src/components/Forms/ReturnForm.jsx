import { useState } from 'react';
import { motion } from 'framer-motion';
import Stepper from './Stepper';
import BumbleInput from './BumbleInput';

export default function ReturnForm({ borrowRecord, operatorName, showCostPrice = true, onSubmit, onClose }) {
  const [returnQty, setReturnQty] = useState('');
  const [remark, setRemark] = useState('');

  const qty = Number(returnQty) || 0;
  const overQty = qty > borrowRecord.borrowQty;
  const canSubmit = qty > 0 && !overQty;

  const handleSubmit = () => {
    if (!canSubmit) return;
    onSubmit({
      loanId: borrowRecord.loanId,
      freightId: borrowRecord.freightId,
      storageId: borrowRecord.storageId,
      returnQty: qty,
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
        {showCostPrice && <InfoRow label="成本单价" value={borrowRecord.costPrice != null ? `¥${Number(borrowRecord.costPrice).toFixed(2)}` : '—'} />}
      </div>

      <Stepper
        value={returnQty}
        onChange={setReturnQty}
        min={1}
        max={borrowRecord.borrowQty}
        label="归还数量"
        hint={`在借：${borrowRecord.borrowQty} 件`}
        error={overQty}
        unit="件"
      />
      {overQty && (
        <p className="text-[13px] text-action-black font-semibold mt-1 pl-1">超出在借数量（在借: {borrowRecord.borrowQty}）</p>
      )}

      <BumbleInput
        label="归还备注（选填）"
        value={remark}
        onChange={e => setRemark(e.target.value)}
      />

      <motion.button
        whileTap={{ scale: 0.96 }}
        onClick={handleSubmit}
        disabled={!canSubmit}
        className="w-full py-3.5 bg-action-black text-white font-semibold rounded-full text-base disabled:opacity-40"
      >
        确认归还
      </motion.button>
    </div>
  );
}

function InfoRow({ label, value }) {
  return (
    <div className="flex justify-between text-base">
      <span className="text-text-secondary">{label}</span>
      <span className="font-semibold text-text-primary">{value}</span>
    </div>
  );
}
