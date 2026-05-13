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
      inventoryId: item.id,
      actualQty: actualQty,
      remark,
    });
  };

  return (
    <div className="flex" style={{ minHeight: '320px' }}>
      {/* Left: Item Info */}
      <div className="w-[135px] bg-white border-r border-gray-100 p-3 flex flex-col gap-2.5 overflow-y-auto shrink-0">
        <BadgeField label="账面数量" value={bookQty} />
        <InfoField label="货物名称" value={item.itemName} />
        <InfoField label="编号" value={item.code} />
        <InfoField label="规格" value={item.spec} />
      </div>

      {/* Right: Form */}
      <div className="flex-1 p-3 flex flex-col gap-3 overflow-y-auto">
        <Stepper
          value={actualQty}
          onChange={setActualQty}
          min={0}
          max={99999}
          label="盘点真实数量"
          hint={`账面：${bookQty} 件`}
          unit="件"
        />

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
          className="w-full py-3.5 bg-action-black text-white font-semibold rounded-full text-sm disabled:opacity-40 mt-auto"
        >
          提交盘点
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
        <div className="rounded-[14px] p-1.5" style={{ background: '#E8986E' }}>
          <div className="rounded-[10px] py-1.5 px-3 text-center" style={{ background: '#EDE2D5', transform: 'skewX(-5deg)' }}>
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
