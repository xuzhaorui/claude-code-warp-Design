import { motion } from 'framer-motion';
import { User, Clock } from 'lucide-react';

function DataCell({ label, value, valueFontSize = '16px', valueFontWeight = 700 }) {
  return (
    <div className="flex flex-col" style={{ gap: '4px' }}>
      <span style={{ fontSize: '12px', color: '#888888', fontWeight: 400 }}>{label}</span>
      <span className="leading-tight" style={{ fontSize: valueFontSize, color: '#1A1A1A', fontWeight: valueFontWeight }}>{value}</span>
    </div>
  );
}

function DataGrid({ cells, delay = 0, isAmount = false }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, delay }}
      className="bg-white"
      style={{ padding: '0 20px' }}
    >
      <div className="grid grid-cols-2" style={{ gap: '20px 24px' }}>
        {cells.map((cell, i) => (
          <DataCell
            key={i}
            label={cell.label}
            value={cell.value}
            valueFontSize={isAmount ? '18px' : '16px'}
            valueFontWeight={isAmount ? 800 : 700}
          />
        ))}
      </div>
    </motion.div>
  );
}

function MetaStrip({ operatorName, time, remark, delay = 0 }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, delay }}
      className="bg-white rounded-2xl"
      style={{ padding: '14px 18px' }}
    >
      <div className="flex items-center gap-2 flex-wrap">
        <div className="flex items-center gap-1.5">
          <User size={13} style={{ color: '#757575' }} />
          <span className="text-[15px] font-semibold" style={{ color: '#1A1A1A' }}>{operatorName}</span>
        </div>
        <span className="text-[13px]" style={{ color: '#C0C0C0' }}>·</span>
        <div className="flex items-center gap-1.5">
          <Clock size={13} style={{ color: '#757575' }} />
          <span className="text-[15px]" style={{ color: '#757575' }}>{time}</span>
        </div>
        {remark && (
          <>
            <span className="text-[13px]" style={{ color: '#C0C0C0' }}>·</span>
            <span className="text-[15px]" style={{ color: '#757575' }}>{remark}</span>
          </>
        )}
      </div>
    </motion.div>
  );
}

function HeroCard({ quantity, method, costPrice, status, showCostPrice }) {
  const isCancelled = status === '已撤销';
  const bg = isCancelled ? '#fff' : '#FFC629';
  const border = isCancelled ? '1.5px solid #E5E5E5' : 'none';
  const badgeColor = isCancelled ? '#fff' : '#FFC629';
  const badge = `${method === '外借' ? '外借出库' : '外销出库'} · ${status}`;
  return (
    <div className="rounded-3xl flex flex-col" style={{ background: bg, border, padding: '22px 22px 18px' }}>
      <span className="text-[13px] font-extrabold self-start px-3 py-1.5 rounded-full mb-5"
        style={{ background: '#1A1A1A', color: badgeColor, letterSpacing: '0.3px' }}>
        {badge}
      </span>
      <div className="text-[56px] font-extrabold leading-none mb-1.5"
        style={{ color: '#1A1A1A', letterSpacing: '-2px' }}>
        {quantity}
      </div>
      <div className="text-[16px] font-medium mb-5" style={{ color: 'rgba(0,0,0,0.55)' }}>
        件 · {method}
      </div>
      {showCostPrice && (
        <div className="flex items-baseline justify-between pt-3.5"
          style={{ borderTop: '1px solid rgba(0,0,0,0.1)' }}>
          <span className="text-[14px] font-semibold" style={{ color: 'rgba(0,0,0,0.42)' }}>成本单价</span>
          <span className="text-[24px] font-extrabold" style={{ color: '#1A1A1A' }}>¥{costPrice.toFixed(2)}</span>
        </div>
      )}
    </div>
  );
}

export default function CheckoutDetail({ record, showCostPrice = true }) {
  const isLoss = record.method === '外销' && record.saleUnitPrice < record.costPrice;
  return (
    <div className="flex flex-col gap-3">
      <HeroCard quantity={record.quantity} method={record.method} costPrice={record.costPrice} status={record.status} showCostPrice={showCostPrice} />
      <DataGrid
        delay={0.05}
        cells={[
          { label: '品名', value: record.itemName },
          { label: '仓库', value: record.warehouse },
          { label: '编号', value: record.code },
          { label: '规格', value: record.spec },
        ]}
      />
      {record.method === '外销' && (
        <>
          <div style={{ margin: '16px 20px', borderTop: '1px solid #EEEEEE' }} />
          <DataGrid
            isAmount
            delay={0.1}
            cells={[
              { label: '销售总价', value: `¥${record.saleTotalPrice.toFixed(2)}` },
              { label: '销售单价', value: `¥${record.saleUnitPrice.toFixed(2)}${isLoss ? ' ↓' : ' ↑'}` },
            ]}
          />
        </>
      )}
      <MetaStrip
        operatorName={record.operatorName}
        time={record.time}
        remark={record.remark}
        delay={record.method === '外销' ? 0.15 : 0.1}
      />
    </div>
  );
}
