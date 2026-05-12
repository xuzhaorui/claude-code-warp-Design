import { buildApiUrl, buildFormBody, parseJsonResponse, ensureAjaxSuccess, normalizeTableRows } from './config';

export async function getBorrowersByQrcode(qrcode) {
  const response = await fetch(buildApiUrl(`/inventory/loan/loan_borrower_qrcode/${encodeURIComponent(qrcode)}`), {
    method: 'GET',
    credentials: 'include',
  });

  const payload = await parseJsonResponse(response);
  const borrowers = ensureAjaxSuccess(payload, '获取借用人列表失败');
  return normalizeTableRows(borrowers).map(mapBorrowerCandidate);
}

export async function getBorrowerDetail(inventoryId, borrowerUserId) {
  const response = await fetch(buildApiUrl(`/inventory/loan/${inventoryId}/${borrowerUserId}`), {
    method: 'GET',
    credentials: 'include',
  });

  const payload = await parseJsonResponse(response);
  ensureAjaxSuccess(payload, '获取借用人详情失败');
  const data = payload?.data ?? payload;
  return mapBorrowerDetail(data);
}

export async function submitReturn(record) {
  const response = await fetch(buildApiUrl('/inventory/loan/loanReturnInbound'), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
    },
    credentials: 'include',
    body: buildFormBody({
      loanId: record.loanId,
      freightId: record.freightId,
      storageId: record.storageId,
      quantity: record.returnQty,
      type: 2,
      inDescription: record.remark,
    }),
  });

  const payload = await parseJsonResponse(response);
  return ensureAjaxSuccess(payload, '归还提交失败');
}

export async function getReturnRecords() {
  const response = await fetch(buildApiUrl('/inventory/inbound/returnLogTop/100'), {
    method: 'GET',
    credentials: 'include',
  });

  const payload = await parseJsonResponse(response);
  const records = ensureAjaxSuccess(payload, '获取归还记录失败');
  return normalizeTableRows(records).map(mapReturnRecord);
}

function mapBorrowerCandidate(item) {
  return {
    id: item.id,
    loanId: item.id,
    inventoryId: item.inventoryId,
    borrowerUserId: item.borrowerUserId,
    itemName: item.freightName || '',
    warehouse: item.storageName || '',
    freightId: item.freightId,
    storageId: item.storageId,
    code: item.freightNumber || '',
    spec: item.specification || '',
    borrowQty: Number(item.loanQuantity || 0),
    costPrice: Number(item.loanPrice || 0),
    borrower: item.userName || '',
    borrowTime: item.recentLoanInboundTime || '',
  };
}

function mapBorrowerDetail(item) {
  return {
    id: item.id,
    loanId: item.id,
    inventoryId: item.inventoryId,
    borrowerUserId: item.borrowerUserId,
    itemName: item.freightName || '',
    warehouse: item.storageName || '',
    freightId: item.freightId,
    storageId: item.storageId,
    code: item.freightNumber || '',
    spec: item.specification || '',
    borrowQty: Number(item.loanQuantity || 0),
    costPrice: Number(item.loanPrice || 0),
    borrower: item.userName || '',
    borrowTime: item.recentLoanInboundTime || '',
  };
}

function mapReturnRecord(item) {
  const inState = Number(item.inState || 1);
  const numAndSpec = item.numberAndSpec || '';
  const parts = numAndSpec.split('/').map(s => s.trim());
  return {
    id: item.id,
    itemName: item.freightName || '',
    warehouse: item.warehouseName || item.storageName || '',
    code: item.freightNumber || parts[0] || '',
    spec: item.specification || parts[1] || '',
    returnQty: Number(item.num || 0),
    borrower: item.inBorrowerUserName || '',
    operatorName: item.operationUserName || item.userName || '',
    time: item.operationTime || '',
    remark: item.inDescription || '',
    status: inState === 2 ? '已撤销' : '正常',
  };
}
