export default function CheckoutDetail({ record }) {
  const statusColor = record.status === '正常' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700';
  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2 mb-2">
        <span className={`px-3 py-1 rounded-full text-xs font-semibold ${statusColor}`}>
          {record.status}
        </span>
      </div>
      <Row label="货物名称" value={record.itemName} />
      <Row label="仓库" value={record.warehouse} />
      <Row label="编号" value={record.code} />
      <Row label="规格" value={record.spec} />
      <Row label="出库数量" value={record.quantity} />
      <Row label="出库方式" value={record.method} />
      <Row label="成本单价" value={`¥${record.costPrice.toFixed(2)}`} />
      {record.method === '外销' && (
        <>
          <Row label="销售总价" value={`¥${record.saleTotalPrice.toFixed(2)}`} />
          <Row label="销售单价" value={`¥${record.saleUnitPrice.toFixed(2)}`} />
        </>
      )}
      <Row label="操作人" value={record.operatorName} />
      <Row label="出库时间" value={record.time} />
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
