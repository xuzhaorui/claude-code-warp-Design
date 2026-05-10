import { buildApiUrl, buildFormBody, parseJsonResponse, ensureAjaxSuccess, normalizeTableRows } from './config';

export async function getItemByCode(code) {
  const response = await fetch(buildApiUrl(`/inventory/list/outbound_qrcode/${code}`), {
    method: 'GET',
    credentials: 'include',
  });

  const payload = await parseJsonResponse(response);
  return ensureAjaxSuccess(payload, '获取货物信息失败');
}

export async function submitInventoryCheck(record) {
  const response = await fetch(buildApiUrl('/calculate/calculate/mobilePhoneInventory'), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
    },
    credentials: 'include',
    body: buildFormBody({
      itemId: record.itemId,
      bookQty: record.bookQty,
      actualQty: record.actualQty,
      difference: record.difference,
      remark: record.remark,
      operatorId: record.operatorId,
    }),
  });

  const payload = await parseJsonResponse(response);
  return ensureAjaxSuccess(payload, '盘点提交失败');
}

export async function getInventoryCheckRecords() {
  const response = await fetch(buildApiUrl('/calculate/calculate/mobilePhoneInventoryLog/100'), {
    method: 'GET',
    credentials: 'include',
  });

  const payload = await parseJsonResponse(response);
  const records = ensureAjaxSuccess(payload, '获取盘点记录失败');
  return normalizeTableRows(records).map(mapInventoryCheckRecord);
}

export async function removeInventoryCheckRecord(id) {
  const response = await fetch(buildApiUrl('/calculate/calculate/delete'), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
    },
    credentials: 'include',
    body: buildFormBody({ id }),
  });

  const payload = await parseJsonResponse(response);
  return ensureAjaxSuccess(payload, '删除盘点记录失败');
}

function mapInventoryCheckRecord(item) {
  return {
    id: item.id,
    itemId: item.itemId,
    itemName: item.itemName || '',
    warehouse: item.warehouse || '',
    code: item.code || '',
    spec: item.spec || '',
    costPrice: item.costPrice || 0,
    bookQty: item.bookQty || 0,
    actualQty: item.actualQty || 0,
    difference: item.difference || 0,
    remark: item.remark || '',
    operatorId: item.operatorId || '',
    operatorName: item.operatorName || '',
    time: item.createTime || '',
    status: item.status || '正常',
  };
}
