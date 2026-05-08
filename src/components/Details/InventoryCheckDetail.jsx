export default function InventoryCheckDetail({ record }) {
  const diffColor = record.difference > 0 ? 'text-green-600' : record.difference < 0 ? 'text-red-500' : 'text-text-primary';
  const diffText = record.difference > 0 ? `+${record.difference}` : `${record.difference}`;

  return (
    <div className="space-y-3">
      <Row label="货物名称" value={record.itemName} />
      <Row label="仓库名称" value={record.warehouse} />
      <Row label="编号" value={record.code} />
      <Row label="规格" value={record.spec} />
      <Row label="账面库存" value={record.bookQty} />
      <Row label="盘点数量" value={record.actualQty} />
      <div className="flex justify-between py-2 border-b border-gray-50">
        <span className="text-sm text-text-secondary">差值</span>
        <span className={`text-sm font-bold ${diffColor}`}>{diffText}</span>
      </div>
      <Row label="操作人" value={record.operatorName} />
      <Row label="盘点时间" value={record.time} />
      {record.remark && <Row label="备注" value={record.remark} />}
    </div>
  );
}

function Row({ label, value }) {
  return (
    <div className="flex justify-between py-2 border-b border-gray-50">
      <span className="text-sm text-text-secondary">{label}</span>
      <span className="text-sm font-semibold text-text-primary text-right max-w-[60%]">{value}</span>
    </div>
  );
}
