import { buildApiUrl, buildFormBody, parseJsonResponse, ensureAjaxSuccess, normalizeTableRows } from './config';

export async function getItemByCode(code) {
  const response = await fetch(buildApiUrl(`/inventory/list/outbound_qrcode/${code}`), {
    method: 'GET',
    credentials: 'include',
  });

  const payload = await parseJsonResponse(response);
  return ensureAjaxSuccess(payload, '获取货物信息失败');
}

export function submitCheckout(record) {
  const response = await fetch(buildApiUrl('/inventory/list/outbound'), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
    },
    credentials: 'include',
    body: buildFormBody({
      itemId: record.itemId,
      quantity: record.quantity,
      method: record.method,
      remark: record.remark,
      operatorId: record.operatorId,
    }),
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

export async function removeCheckoutRecord(id) {
  const response = await fetch(buildApiUrl('/inventory/list/outbound/delete'), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
    },
    credentials: 'include',
    body: buildFormBody({ id }),
  });

  const payload = await parseJsonResponse(response);
  return ensureAjaxSuccess(payload, '删除出库记录失败');
}

function mapCheckoutRecord(item) {
  return {
    id: item.id,
    itemId: item.itemId,
    itemName: item.itemName,
    warehouse: item.warehouse || '',
    code: item.code || '',
    spec: item.spec || '',
    quantity: item.quantity,
    method: item.method || '',
    saleTotalPrice: item.saleTotalPrice || 0,
    saleUnitPrice: item.saleUnitPrice || 0,
    remark: item.remark || '',
    operatorId: item.operatorId || '',
    operatorName: item.operatorName || '',
    time: item.createTime || '',
    status: item.status || '正常',
  };
}
