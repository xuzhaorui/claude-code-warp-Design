import { motion } from 'framer-motion';
import { User, Clock } from 'lucide-react';

function DataCell({ label, value, valueColor }) {
  return (
    <div className="flex flex-col gap-0.5">
      <span className="text-[13px]" style={{ color: '#757575' }}>{label}</span>
      <span className="text-[17px] font-bold leading-tight" style={{ color: valueColor ?? '#1A1A1A' }}>{value}</span>
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
      <p className="text-[15px] font-bold mb-3" style={{ color: '#757575' }}>{title}</p>
      <div className="grid grid-cols-2 gap-x-4 gap-y-3">
        {cells.map((cell, i) => (
          <DataCell key={i} label={cell.label} value={cell.value} valueColor={cell.valueColor} />
        ))}
      </div>
    </motion.div>
  );
}

function StatRow({ bookQty, actualQty, difference, delay = 0 }) {
  const isPos = difference > 0;
  const isNeg = difference < 0;
  const diffColor = '#1A1A1A';
  const diffText = isPos ? `+${difference}` : `${difference}`;
  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, delay }}
      className="bg-white rounded-2xl"
      style={{ padding: '16px 18px' }}
    >
      <p className="text-[15px] font-bold mb-3" style={{ color: '#757575' }}>盘点数据</p>
      <div className="flex">
        <div className="flex-1 flex flex-col items-center gap-0.5">
          <span className="text-[13px]" style={{ color: '#757575' }}>账面库存</span>
          <span className="text-[24px] font-extrabold" style={{ color: '#1A1A1A' }}>{bookQty}</span>
          <span className="text-[13px]" style={{ color: '#757575' }}>件</span>
        </div>
        <div className="w-px self-stretch" style={{ background: '#F0F0F0' }} />
        <div className="flex-1 flex flex-col items-center gap-0.5">
          <span className="text-[13px]" style={{ color: '#757575' }}>实盘数量</span>
          <span className="text-[24px] font-extrabold" style={{ color: '#1A1A1A' }}>{actualQty}</span>
          <span className="text-[13px]" style={{ color: '#757575' }}>件</span>
        </div>
        <div className="w-px self-stretch" style={{ background: '#F0F0F0' }} />
        <div className="flex-1 flex flex-col items-center gap-0.5">
          <span className="text-[13px]" style={{ color: '#757575' }}>盘点差值</span>
          <span className="text-[24px] font-extrabold" style={{ color: diffColor }}>{diffText}</span>
          <span className="text-[13px]" style={{ color: '#757575' }}>件</span>
        </div>
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

function HeroCard({ difference, costPrice, showCostPrice }) {
  const price = Number(costPrice) || 0;
  const isPos = difference > 0;
  const isNeg = difference < 0;
  const diffText = isPos ? `+${difference}` : difference === 0 ? '0' : `${difference}`;
  const diffColor = '#1A1A1A';
  const diffContext = isPos ? '件盈余' : isNeg ? '件短缺' : '库存相符';
  const statusLabel = isPos ? '盈余' : isNeg ? '亏损' : '相符';
  const loss = Math.abs(difference) * price;

  return (
    <div className="rounded-3xl flex flex-col" style={{ background: '#FFC629', padding: '22px 22px 18px' }}>
      <span className="text-[13px] font-extrabold self-start px-3 py-1.5 rounded-full mb-5"
        style={{ background: '#1A1A1A', color: '#FFC629', letterSpacing: '0.3px' }}>
        盘点记录 · {statusLabel}
      </span>
      <div className="text-[56px] font-extrabold leading-none mb-1.5"
        style={{ color: diffColor, letterSpacing: '-2px' }}>
        {diffText}
      </div>
      <div className="text-[16px] font-medium mb-5" style={{ color: 'rgba(0,0,0,0.55)' }}>
        {diffContext}
      </div>
      {showCostPrice && price > 0 && (
        <div className="flex items-baseline justify-between pt-3.5"
          style={{ borderTop: '1px solid rgba(0,0,0,0.1)' }}>
          <div>
            <span className="text-[14px] font-semibold" style={{ color: 'rgba(0,0,0,0.42)' }}>成本单价</span>
            {difference !== 0 && (
              <div className="text-[14px] font-semibold mt-0.5" style={{ color: 'rgba(0,0,0,0.42)' }}>
                {isNeg ? '损失' : '溢价'} ¥{loss.toFixed(2)}
              </div>
            )}
          </div>
          <span className="text-[24px] font-extrabold" style={{ color: '#1A1A1A' }}>¥{price.toFixed(2)}</span>
        </div>
      )}
    </div>
  );
}

export default function InventoryCheckDetail({ record, showCostPrice = true }) {
  return (
    <div className="flex flex-col gap-3">
      <HeroCard difference={record.difference} costPrice={record.costPrice} showCostPrice={showCostPrice} />
      <StatRow bookQty={record.bookQty} actualQty={record.actualQty} difference={record.difference} delay={0.05} />
      <DataGrid
        title="货物信息"
        delay={0.1}
        cells={[
          { label: '品名', value: record.itemName },
          { label: '仓库', value: record.warehouse },
          { label: '编码', value: record.code },
          { label: '规格', value: record.spec },
        ]}
      />
      <MetaStrip operatorName={record.operatorName} time={record.time} remark={record.remark} delay={0.15} />
    </div>
  );
}
