import { User, Clock } from 'lucide-react';

function Row({ label, value, bold = false, valueColor }) {
  return (
    <div className="flex items-baseline justify-between" style={{ padding: '11px 0' }}>
      <span style={{ fontSize: '15px', color: '#888888' }}>{label}</span>
      <span className="text-right" style={{ fontSize: '16px', fontWeight: bold ? 700 : 400, color: valueColor ?? '#1A1A1A' }}>{value}</span>
    </div>
  );
}

function MetaStrip({ operatorName, time, remark }) {
  return (
    <div className="flex items-center gap-2 flex-wrap" style={{ padding: '11px 0 0' }}>
      <div className="flex items-center gap-1.5">
        <User size={14} style={{ color: '#757575' }} />
        <span style={{ fontSize: '15px', fontWeight: 600, color: '#1A1A1A' }}>{operatorName}</span>
      </div>
      <span style={{ fontSize: '13px', color: '#C0C0C0' }}>·</span>
      <div className="flex items-center gap-1.5">
        <Clock size={14} style={{ color: '#757575' }} />
        <span style={{ fontSize: '15px', color: '#757575' }}>{time}</span>
      </div>
      {remark && (
        <>
          <span style={{ fontSize: '13px', color: '#C0C0C0' }}>·</span>
          <span style={{ fontSize: '15px', color: '#757575' }}>{remark}</span>
        </>
      )}
    </div>
  );
}

export default function ReturnDetail({ record }) {
  return (
    <div style={{ padding: '4px 0' }}>
      <div style={{ padding: '12px 0 10px', borderBottom: '1px solid #F0F0F0' }}>
        <p style={{ fontSize: '20px', fontWeight: 700, color: '#1A1A1A' }}>{record.itemName}</p>
        <p style={{ fontSize: '15px', color: '#888888', marginTop: '4px' }}>{record.spec} · {record.code}</p>
      </div>
      <Row label="归还数量" value={`${record.returnQty} 件`} bold />
      <Row label="外借人" value={record.borrower} bold />
      <Row label="状态" value={record.status} bold />
      <Row label="仓库" value={record.warehouse} />
      <div style={{ borderTop: '1px solid #F0F0F0' }} />
      <MetaStrip operatorName={record.operatorName} time={record.time} remark={record.remark} />
    </div>
  );
}
