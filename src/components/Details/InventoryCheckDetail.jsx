import { User, Clock } from 'lucide-react';

function Row({ label, value, bold = false, valueColor }) {
  return (
    <div className="flex items-baseline justify-between" style={{ padding: '10px 0' }}>
      <span style={{ fontSize: '14px', color: '#888888', fontWeight: 400 }}>{label}</span>
      <span className="text-right" style={{ fontSize: '15px', fontWeight: bold ? 700 : 400, color: valueColor ?? '#1A1A1A' }}>{value}</span>
    </div>
  );
}

function MetaStrip({ operatorName, time, remark }) {
  return (
    <div className="flex items-center gap-2 flex-wrap" style={{ padding: '10px 0 0' }}>
      <div className="flex items-center gap-1.5">
        <User size={13} style={{ color: '#757575' }} />
        <span style={{ fontSize: '14px', fontWeight: 600, color: '#1A1A1A' }}>{operatorName}</span>
      </div>
      <span style={{ fontSize: '13px', color: '#C0C0C0' }}>·</span>
      <div className="flex items-center gap-1.5">
        <Clock size={13} style={{ color: '#757575' }} />
        <span style={{ fontSize: '14px', color: '#757575' }}>{time}</span>
      </div>
      {remark && (
        <>
          <span style={{ fontSize: '13px', color: '#C0C0C0' }}>·</span>
          <span style={{ fontSize: '14px', color: '#757575' }}>{remark}</span>
        </>
      )}
    </div>
  );
}

export default function InventoryCheckDetail({ record, showCostPrice = true }) {
  const diff = record.difference;
  const diffText = diff > 0 ? `+${diff}` : `${diff}`;
  const price = Number(record.costPrice) || 0;
  const loss = Math.abs(diff) * price;
  return (
    <div style={{ padding: '4px 0' }}>
      <div style={{ padding: '12px 0', borderBottom: '1px solid #F0F0F0' }}>
        <p style={{ fontSize: '18px', fontWeight: 700, color: '#1A1A1A' }}>{record.itemName}</p>
        <p style={{ fontSize: '14px', color: '#888888', marginTop: '4px' }}>{record.spec}</p>
      </div>
      <Row label="账面库存" value={`${record.bookQty} 件`} />
      <Row label="实盘数量" value={`${record.actualQty} 件`} bold />
      <Row label="盘点差值" value={`${diffText} 件`} bold valueColor={diff !== 0 ? '#1A1A1A' : undefined} />
      {showCostPrice && price > 0 && <Row label="成本单价" value={`¥${price.toFixed(2)}`} />}
      {showCostPrice && diff !== 0 && price > 0 && (
        <Row label={diff < 0 ? '损失' : '溢价'} value={`¥${loss.toFixed(2)}`} bold valueColor="#FF4444" />
      )}
      <Row label="仓库" value={record.warehouse} />
      <Row label="编号" value={record.code} />
      <div style={{ borderTop: '1px solid #F0F0F0' }} />
      <MetaStrip operatorName={record.operatorName} time={record.time} remark={record.remark} />
    </div>
  );
}
