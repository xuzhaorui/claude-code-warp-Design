import { buildApiUrl, buildFormBody, parseJsonResponse, ensureAjaxSuccess, normalizeTableRows } from './config';

export async function getItemByCode(code) {
  const response = await fetch(buildApiUrl(`/inventory/list/outbound_qrcode/${encodeURIComponent(code)}`), {
    method: 'GET',
    credentials: 'include',
  });

  const payload = await parseJsonResponse(response);
  ensureAjaxSuccess(payload, '获取货物信息失败');
  const data = payload?.data ?? payload;
  if (!data || (typeof data === 'object' && Object.keys(data).length === 0)) return null;
  return mapInventoryItem(data);
}

export async function submitCheckout(record) {
  const fields = {
    inventoryId: record.inventoryId,
    num: record.quantity,
    type: record.type,
  };
  if (record.type === 1 && record.totalPrice) {
    fields.totalPrice = record.totalPrice;
    if (record.costUnitPrice) fields.costUnitPrice = record.costUnitPrice;
  }
  if (record.type === 2 && record.outDescription) {
    fields.outDescription = record.outDescription;
  }

  const response = await fetch(buildApiUrl('/inventory/list/outbound'), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
    },
    credentials: 'include',
    body: buildFormBody(fields),
  });

  const payload = await parseJsonResponse(response);
  return ensureAjaxSuccess(payload, '出库提交失败');
}

export async function getCheckoutRecords() {
  const response = await fetch(buildApiUrl('/inventory/outbound/getUserOutboundInDay'), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
    },
    credentials: 'include',
    body: buildFormBody({}),
  });

  const payload = await parseJsonResponse(response);
  const records = ensureAjaxSuccess(payload, '获取出库记录失败');
  return normalizeTableRows(records).map(mapCheckoutRecord);
}

function mapInventoryItem(item) {
  return {
    id: item.id,
    warehouse: item.storageName || '',
    itemName: item.freightName || '',
    code: item.freightNumber || '',
    spec: item.specification || '',
    stockQty: Number(item.quantity || 0),
    costPrice: Number(item.unitPrice || 0),
  };
}

function mapCheckoutRecord(item) {
  const type = Number(item.type || 0);
  const outState = Number(item.outState || 1);
  const numAndSpec = item.numberAndSpec || '';
  const parts = numAndSpec.split('/').map(s => s.trim());
  return {
    id: item.id,
    inventoryId: item.inventoryId,
    warehouse: item.storageName || '',
    itemName: item.freightName || '',
    code: item.freightNumber || parts[0] || '',
    spec: item.specification || parts[1] || '',
    quantity: Number(item.num || 0),
    type,
    method: type === 1 ? '外销' : '外借',
    saleTotalPrice: Number(item.totalPrice || 0),
    saleUnitPrice: Number(item.outUnitPrice || (Number(item.totalPrice || 0) / Number(item.num || 1)) || 0),
    costPrice: Number(item.costUnitPrice || 0),
    remark: item.outDescription || '',
    operatorName: item.operationNickName || item.nickName || item.operationUserName || '',
    time: item.operationTime || '',
    status: outState === 2 ? '已撤销' : '正常',
  };
}
