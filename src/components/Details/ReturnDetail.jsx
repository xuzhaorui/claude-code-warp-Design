export default function ReturnDetail({ record }) {
  return (
    <div className="space-y-3">
      <Row label="货物名称" value={record.itemName} />
      <Row label="仓库名称" value={record.warehouse} />
      <Row label="编号" value={record.code} />
      <Row label="规格" value={record.spec} />
      <Row label="归还数量" value={record.returnQty} />
      <Row label="外借人" value={record.borrower} />
      <Row label="操作人" value={record.operatorName} />
      <Row label="归还时间" value={record.time} />
      {record.remark && <Row label="归还备注" value={record.remark} />}
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
