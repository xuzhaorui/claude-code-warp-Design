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
    <div className="flex" style={{ minHeight: '320px' }}>
      {/* Left: Item Info */}
      <div className="w-[135px] bg-white border-r border-gray-100 p-3 flex flex-col gap-2.5 overflow-y-auto shrink-0">
        <BadgeField label="在借数量" value={borrowRecord.borrowQty} />
        <InfoField label="货物名称" value={borrowRecord.itemName} />
        <InfoField label="外借人" value={borrowRecord.borrower} />
        <InfoField label="仓库" value={borrowRecord.warehouse} />
      </div>

      {/* Right: Form */}
      <div className="flex-1 p-3 flex flex-col gap-3 overflow-y-auto min-w-0">
        {showCostPrice && <CostBadge value={borrowRecord.costPrice != null ? `¥${Number(borrowRecord.costPrice).toFixed(2)}` : '—'} />}

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
          className="w-full py-3.5 bg-action-black text-white font-semibold rounded-full text-base disabled:opacity-40 mt-auto"
        >
          确认归还
        </motion.button>
      </div>
    </div>
  );
}

function InfoField({ label, value }) {
  return (
    <div>
      <div className="text-[15px] font-semibold text-text-secondary tracking-wide">{label}</div>
      <div className="text-[17px] font-bold text-text-primary mt-0.5">{value}</div>
    </div>
  );
}

function BadgeField({ label, value }) {
  return (
    <div>
      <div className="text-[15px] font-semibold text-text-secondary tracking-wide">{label}</div>
      <div className="mt-1" style={{ transform: 'rotate(-1deg)' }}>
        <div className="rounded-[14px] p-1.5 inline-block" style={{ background: '#E8986E' }}>
          <div className="rounded-[10px] py-1.5 px-3 text-center inline-block" style={{ background: '#EDE2D5', transform: 'skewX(-5deg)' }}>
            <span
              className="inline-block"
              style={{
                fontSize: '18px',
                fontWeight: 900,
                fontStyle: 'italic',
                color: '#E8986E',
                letterSpacing: '-0.5px',
                transform: 'skewX(8deg)',
              }}
            >
              {value}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}

function CostBadge({ value }) {
  return (
    <div>
      <div className="text-[15px] font-semibold text-text-secondary tracking-wide">成本单价</div>
      <div className="mt-1" style={{ transform: 'rotate(-1deg)' }}>
        <div className="rounded-[14px] p-1.5 inline-block" style={{ background: '#E8986E' }}>
          <div className="rounded-[10px] py-1.5 px-3 text-center inline-block" style={{ background: '#EDE2D5', transform: 'skewX(-5deg)' }}>
            <span
              className="inline-block"
              style={{
                fontSize: '18px',
                fontWeight: 900,
                fontStyle: 'italic',
                color: '#E8986E',
                letterSpacing: '-0.5px',
                transform: 'skewX(8deg)',
              }}
            >
              {value}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
