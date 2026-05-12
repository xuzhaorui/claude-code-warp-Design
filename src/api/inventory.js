import { buildApiUrl, buildFormBody, parseJsonResponse, ensureAjaxSuccess, normalizeTableRows } from './config';

export async function submitInventoryCheck(record) {
  const response = await fetch(buildApiUrl('/calculate/calculate/mobilePhoneInventory'), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
    },
    credentials: 'include',
    body: buildFormBody({
      inventoryId: record.inventoryId,
      physicalInventoryQuantity: record.actualQty,
      remark: record.remark,
    }),
  });

  const payload = await parseJsonResponse(response);
  return ensureAjaxSuccess(payload, '盘点提交失败');
}

export async function getInventoryCheckRecords() {
  const response = await fetch(buildApiUrl('/calculate/calculate/mobilePhoneInventoryLog/100'), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
    },
    credentials: 'include',
    body: buildFormBody({}),
  });

  const payload = await parseJsonResponse(response);
  const records = ensureAjaxSuccess(payload, '获取盘点记录失败');
  return normalizeTableRows(records).map(mapInventoryCheckRecord);
}

function mapInventoryCheckRecord(item) {
  return {
    id: item.id,
    inventoryId: item.inventoryId,
    itemName: item.freightName || '',
    warehouse: item.storageName || '',
    code: item.freightNumber || '',
    spec: item.specification || '',
    bookQty: Number(item.warehousNum || 0),
    actualQty: Number(item.physicalInventoryQuantity || 0),
    difference: Number(item.difference || 0),
    costPrice: Number(item.unitPrice || 0),
    remark: item.remark || '',
    operatorName: item.purchaseUserName || '',
    time: item.purchaseTime || '',
    status: '正常',
  };
}
