import { useState } from 'react';
import { motion } from 'framer-motion';
import Stepper from './Stepper';
import BumbleInput from './BumbleInput';

export default function CheckoutForm({ item, operatorName, showCostPrice = true, onSubmit, onClose }) {
  const [quantity, setQuantity] = useState('');
  const [method, setMethod] = useState('外销');
  const [saleTotalPrice, setSaleTotalPrice] = useState('');
  const [remark, setRemark] = useState('');
  const [confirmLoss, setConfirmLoss] = useState(false);

  const qty = Number(quantity) || 0;
  const saleTotal = Number(saleTotalPrice) || 0;
  const saleUnitPrice = qty > 0 ? (saleTotal / qty).toFixed(2) : '0.00';
  const overStock = qty > item.stockQty;
  const isLoss = showCostPrice && method === '外销' && qty > 0 && saleTotal > 0 && (saleTotal / qty) < item.costPrice;
  const canSubmit = qty > 0 && !overStock && (method === '外借' || saleTotal > 0) && (!isLoss || confirmLoss);

  const handleSubmit = () => {
    if (!canSubmit) return;
    onSubmit({
      inventoryId: item.id,
      quantity: qty,
      type: method === '外销' ? 1 : 2,
      totalPrice: method === '外销' ? saleTotal : undefined,
      costUnitPrice: method === '外销' ? item.costPrice : undefined,
      outDescription: method === '外借' ? remark : undefined,
    });
  };

  return (
    <div className="flex" style={{ minHeight: '320px' }}>
      {/* Left: Item Info */}
      <div className="w-[135px] bg-white border-r border-gray-100 p-3 flex flex-col gap-2.5 overflow-y-auto shrink-0">
        <BadgeField label="库存" value={item.stockQty} />
        <InfoField label="货物名称" value={item.itemName} />
        <InfoField label="仓库" value={item.warehouse} />
        <InfoField label="编号" value={item.code} />
        <InfoField label="规格" value={item.spec} />
      </div>

      {/* Right: Form */}
      <div className="flex-1 p-3 flex flex-col gap-3 overflow-y-auto min-w-0">
        {showCostPrice && <CostBadge value={`¥${item.costPrice.toFixed(2)}`} />}

        {/* Method selector */}
        <div className="relative bg-bg-secondary rounded-full p-[3px] flex">
          {['外销', '外借'].map(m => (
            <button
              key={m}
              onClick={() => { setMethod(m); setConfirmLoss(false); }}
              className="relative flex-1 py-2 text-base font-semibold z-10 rounded-full text-center"
              style={{ color: method === m ? '#fff' : '#757575' }}
            >
              {method === m && (
                <motion.div
                  layoutId="method-seg-pill"
                  className="absolute inset-0 bg-action-black rounded-full"
                  transition={{ type: 'spring', stiffness: 300, damping: 28 }}
                />
              )}
              <span className="relative z-10">{m}</span>
            </button>
          ))}
        </div>

        <Stepper
          value={quantity}
          onChange={(updater) => { setQuantity(updater); setConfirmLoss(false); }}
          min={1}
          max={item.stockQty}
          label="出库数量"
          hint={`库存：${item.stockQty} 件`}
          error={overStock}
        />
        {overStock && (
          <p className="text-[13px] text-action-black font-semibold mt-1 pl-1">超出库存数量（库存: {item.stockQty}）</p>
        )}

        {method === '外销' && (
          <>
            <div>
              <BumbleInput
                label="销售总价"
                type="number"
                value={saleTotalPrice}
                onChange={e => { setSaleTotalPrice(e.target.value); setConfirmLoss(false); }}
              />
            </div>
            <div className="bg-bg-secondary rounded-2xl px-4 py-3">
              <span className="text-sm text-text-secondary">销售单价：</span>
              <span className="text-base font-semibold text-text-primary">¥{saleUnitPrice}</span>
            </div>
            {isLoss && !confirmLoss && (
              <div className="bg-red-50 rounded-2xl p-3">
                <p className="text-sm text-red-600 mb-2">销售单价低于成本单价（¥{item.costPrice.toFixed(2)}），存在亏损风险</p>
                <button
                  onClick={() => setConfirmLoss(true)}
                  className="text-sm font-semibold text-red-600 underline"
                >
                  确认继续
                </button>
              </div>
            )}
            {isLoss && confirmLoss && (
              <p className="text-sm text-text-secondary">已确认亏损操作</p>
            )}
          </>
        )}

        {method === '外借' && (
          <BumbleInput
            label="出库备注（选填）"
            value={remark}
            onChange={e => setRemark(e.target.value)}
          />
        )}

        <motion.button
          whileTap={{ scale: 0.96 }}
          onClick={handleSubmit}
          disabled={!canSubmit}
          className="w-full py-3.5 bg-action-black text-white font-semibold rounded-full text-base disabled:opacity-40 mt-auto"
        >
          提交
        </motion.button>
      </div>
    </div>
  );
}

function InfoField({ label, value }) {
  return (
    <div>
      <div className="text-[10px] font-semibold text-text-secondary tracking-wide">{label}</div>
      <div className="text-sm font-bold text-text-primary mt-0.5">{value}</div>
    </div>
  );
}

function BadgeField({ label, value }) {
  return (
    <div>
      <div className="text-[10px] font-semibold text-text-secondary tracking-wide">{label}</div>
      <div className="mt-1" style={{ transform: 'rotate(-1deg)' }}>
        <div className="rounded-[14px] p-1.5 inline-block" style={{ background: '#F5C842' }}>
          <div className="rounded-[10px] py-1.5 px-3 text-center inline-block" style={{ background: '#1A1A1A', transform: 'skewX(-5deg)' }}>
            <span
              className="inline-block"
              style={{
                fontSize: '18px',
                fontWeight: 900,
                fontStyle: 'italic',
                color: '#F5C842',
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
      <div className="text-[10px] font-semibold text-text-secondary tracking-wide">成本单价</div>
      <div className="mt-1" style={{ transform: 'rotate(-1deg)' }}>
        <div className="rounded-[14px] p-1.5 inline-block" style={{ background: '#F5C842' }}>
          <div className="rounded-[10px] py-1.5 px-3 text-center inline-block" style={{ background: '#1A1A1A', transform: 'skewX(-5deg)' }}>
            <span
              className="inline-block"
              style={{
                fontSize: '16px',
                fontWeight: 900,
                fontStyle: 'italic',
                color: '#F5C842',
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
