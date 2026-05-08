import { useState } from 'react';
import { motion } from 'framer-motion';

export default function CheckoutForm({ item, operatorName, onSubmit, onClose }) {
  const [quantity, setQuantity] = useState('');
  const [method, setMethod] = useState('外销');
  const [saleTotalPrice, setSaleTotalPrice] = useState('');
  const [remark, setRemark] = useState('');
  const [confirmLoss, setConfirmLoss] = useState(false);

  const qty = Number(quantity) || 0;
  const saleTotal = Number(saleTotalPrice) || 0;
  const saleUnitPrice = qty > 0 ? (saleTotal / qty).toFixed(2) : '0.00';
  const overStock = qty > item.stockQty;
  const isLoss = method === '外销' && qty > 0 && saleTotal > 0 && (saleTotal / qty) < item.costPrice;
  const canSubmit = qty > 0 && !overStock && (method === '外借' || saleTotal > 0) && (!isLoss || confirmLoss);

  const handleSubmit = () => {
    if (!canSubmit) return;
    onSubmit({
      id: 'co-' + Date.now(),
      itemId: item.id,
      itemName: item.name,
      warehouse: item.warehouse,
      code: item.code,
      spec: item.spec,
      costPrice: item.costPrice,
      quantity: qty,
      method,
      saleTotalPrice: method === '外销' ? saleTotal : 0,
      saleUnitPrice: method === '外销' ? Number(saleUnitPrice) : 0,
      remark,
      operatorId: JSON.parse(localStorage.getItem('currentUser') || '{}').id,
      operatorName,
      time: new Date().toLocaleString('zh-CN', { hour12: false }).replace(/\//g, '-'),
      status: '正常',
    });
  };

  return (
    <div className="space-y-4">
      {/* Read-only item info */}
      <div className="bg-bg-secondary rounded-2xl p-4 space-y-2">
        <InfoRow label="货物名称" value={item.name} />
        <InfoRow label="所属仓库" value={item.warehouse} />
        <InfoRow label="编号" value={item.code} />
        <InfoRow label="规格" value={item.spec} />
        <InfoRow label="库存数量" value={item.stockQty} />
        <InfoRow label="成本单价" value={`¥${item.costPrice.toFixed(2)}`} />
      </div>

      {/* Method selector */}
      <div className="bg-bg-secondary rounded-full p-1 flex">
        {['外销', '外借'].map(m => (
          <button
            key={m}
            onClick={() => { setMethod(m); setConfirmLoss(false); }}
            className={`flex-1 py-2 text-sm font-semibold rounded-full transition-colors ${method === m ? 'bg-action-black text-white' : 'text-text-secondary'}`}
          >
            {m}
          </button>
        ))}
      </div>

      {/* Quantity */}
      <div>
        <label className="text-xs font-semibold text-text-secondary mb-1 block">出库数量</label>
        <input
          type="number"
          min="1"
          value={quantity}
          onChange={e => { setQuantity(e.target.value); setConfirmLoss(false); }}
          placeholder="请输入出库数量"
          className="w-full px-4 py-3 bg-bg-secondary rounded-2xl text-sm"
        />
        {overStock && (
          <p className="text-red-500 text-xs mt-1">出库数量超过库存数量（库存: {item.stockQty}）</p>
        )}
      </div>

      {/* Sale price (外销 only) */}
      {method === '外销' && (
        <>
          <div>
            <label className="text-xs font-semibold text-text-secondary mb-1 block">销售总价</label>
            <input
              type="number"
              min="0"
              step="0.01"
              value={saleTotalPrice}
              onChange={e => { setSaleTotalPrice(e.target.value); setConfirmLoss(false); }}
              placeholder="请输入销售总价"
              className="w-full px-4 py-3 bg-bg-secondary rounded-2xl text-sm"
            />
          </div>
          <div className="bg-bg-secondary rounded-2xl px-4 py-3">
            <span className="text-xs text-text-secondary">销售单价：</span>
            <span className="text-sm font-semibold text-text-primary">¥{saleUnitPrice}</span>
          </div>
          {isLoss && !confirmLoss && (
            <div className="bg-red-50 rounded-2xl p-3">
              <p className="text-xs text-red-600 mb-2">销售单价低于成本单价（¥{item.costPrice.toFixed(2)}），存在亏损风险</p>
              <button
                onClick={() => setConfirmLoss(true)}
                className="text-xs font-semibold text-red-600 underline"
              >
                确认继续
              </button>
            </div>
          )}
          {isLoss && confirmLoss && (
            <p className="text-xs text-text-secondary">已确认亏损操作</p>
          )}
        </>
      )}

      {/* Remark */}
      <div>
        <label className="text-xs font-semibold text-text-secondary mb-1 block">出库备注（选填）</label>
        <input
          value={remark}
          onChange={e => setRemark(e.target.value)}
          placeholder="可选填写备注"
          className="w-full px-4 py-3 bg-bg-secondary rounded-2xl text-sm"
        />
      </div>

      {/* Submit */}
      <motion.button
        whileTap={{ scale: 0.96 }}
        onClick={handleSubmit}
        disabled={!canSubmit}
        className="w-full py-3.5 bg-action-black text-white font-semibold rounded-full text-sm disabled:opacity-40"
      >
        提交
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
