import { motion } from 'framer-motion';
import { User, Clock } from 'lucide-react';

function DataCell({ label, value, valueColor }) {
  return (
    <div className="flex flex-col gap-0.5">
      <span className="text-[13px]" style={{ color: '#757575' }}>{label}</span>
      <span className="text-[15px] font-bold leading-tight" style={{ color: valueColor ?? '#1A1A1A' }}>{value}</span>
    </div>
  );
}

function DataGrid({ title, cells, delay = 0 }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, delay }}
      className="bg-white rounded-2xl"
      style={{ padding: '16px 18px' }}
    >
      <p className="text-[13px] font-bold mb-3" style={{ color: '#757575' }}>{title}</p>
      <div className="grid grid-cols-2 gap-x-4 gap-y-3">
        {cells.map((cell, i) => (
          <DataCell key={i} label={cell.label} value={cell.value} valueColor={cell.valueColor} />
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

function HeroCard({ returnQty, borrower, status }) {
  const isCancelled = status === '已撤销';
  const bg = isCancelled ? '#fff' : '#FFC629';
  const border = isCancelled ? '1.5px solid #E5E5E5' : 'none';
  const badgeColor = isCancelled ? '#fff' : '#FFC629';
  const statusText = isCancelled ? '已撤销' : '已归还';
  return (
    <div className="rounded-3xl flex flex-col"
      style={{ background: bg, border, padding: '22px 22px 18px' }}>
      <span className="text-[13px] font-extrabold self-start px-3 py-1.5 rounded-full mb-5"
        style={{ background: '#1A1A1A', color: badgeColor, letterSpacing: '0.3px' }}>
        归还记录 · {statusText}
      </span>
      <div className="text-[56px] font-extrabold leading-none mb-1.5"
        style={{ color: '#1A1A1A', letterSpacing: '-2px' }}>
        {returnQty}
      </div>
      <div className="text-[16px] font-medium mb-5" style={{ color: 'rgba(0,0,0,0.55)' }}>
        件 · {statusText}
      </div>
      <div className="flex items-baseline justify-between pt-3.5"
        style={{ borderTop: '1px solid rgba(0,0,0,0.1)' }}>
        <span className="text-[14px] font-semibold" style={{ color: 'rgba(0,0,0,0.42)' }}>外借人</span>
        <span className="text-[17px] font-extrabold" style={{ color: '#1A1A1A' }}>{borrower}</span>
      </div>
    </div>
  );
}

export default function ReturnDetail({ record }) {
  return (
    <div className="flex flex-col gap-3">
      <HeroCard returnQty={record.returnQty} borrower={record.borrower} status={record.status} />
      <DataGrid
        title="货物信息"
        delay={0.05}
        cells={[
          { label: '品名', value: record.itemName },
          { label: '仓库', value: record.warehouse },
          { label: '编码', value: record.code },
          { label: '规格', value: record.spec },
        ]}
      />
      <MetaStrip operatorName={record.operatorName} time={record.time} remark={record.remark} delay={0.1} />
    </div>
  );
}
