import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
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
    <div className="space-y-4">
      {/* Read-only item info */}
      <div className="bg-bg-secondary rounded-2xl p-4 space-y-2">
        <InfoRow label="货物名称" value={item.itemName} />
        <InfoRow label="所属仓库" value={item.warehouse} />
        <InfoRow label="编号" value={item.code} />
        <InfoRow label="规格" value={item.spec} />
        <InfoRow label="库存数量" value={item.stockQty} />
        {showCostPrice && <InfoRow label="成本单价" value={`¥${item.costPrice.toFixed(2)}`} />}
      </div>

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

      {/* Quantity */}
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

      {/* Sale price (外销 only) */}
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

      {/* Remark (外借 only) */}
      {method === '外借' && (
        <BumbleInput
          label="出库备注（选填）"
          value={remark}
          onChange={e => setRemark(e.target.value)}
        />
      )}

      {/* Submit */}
      <motion.button
        whileTap={{ scale: 0.96 }}
        onClick={handleSubmit}
        disabled={!canSubmit}
        className="w-full py-3.5 bg-action-black text-white font-semibold rounded-full text-base disabled:opacity-40"
      >
        提交
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
