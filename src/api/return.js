import { buildApiUrl, buildFormBody, parseJsonResponse, ensureAjaxSuccess, normalizeTableRows } from './config';

export async function getBorrowersByItem(itemId) {
  const response = await fetch(buildApiUrl(`/inventory/loan/loan_borrower_qrcode/${itemId}`), {
    method: 'GET',
    credentials: 'include',
  });

  const payload = await parseJsonResponse(response);
  const borrowers = ensureAjaxSuccess(payload, '获取借用人列表失败');
  return normalizeTableRows(borrowers).map(mapBorrowerCandidate);
}

export async function getBorrowerDetail(loanId, borrowerUserId) {
  const response = await fetch(buildApiUrl(`/inventory/loan/${loanId}/${borrowerUserId}`), {
    method: 'GET',
    credentials: 'include',
  });

  const payload = await parseJsonResponse(response);
  return ensureAjaxSuccess(payload, '获取借用人详情失败').then(mapBorrowerDetail);
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
      itemId: record.itemId,
      returnQuantity: record.returnQty,
      remark: record.remark,
      operatorId: record.operatorId,
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

export async function removeReturnRecord(id) {
  const response = await fetch(buildApiUrl('/inventory/inbound/delete'), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
    },
    credentials: 'include',
    body: buildFormBody({ id }),
  });

  const payload = await parseJsonResponse(response);
  return ensureAjaxSuccess(payload, '删除归还记录失败');
}

function mapBorrowerCandidate(item) {
  return {
    id: item.id,
    itemId: item.itemId,
    itemName: item.itemName || '',
    warehouse: item.warehouse || '',
    code: item.code || '',
    spec: item.spec || '',
    costPrice: item.costPrice || 0,
    borrowQty: item.quantity || 0,
    borrower: item.borrower || '',
    borrowTime: item.borrowTime || '',
    operatorId: item.operatorId || '',
  };
}

function mapBorrowerDetail(item) {
  return {
    id: item.id,
    itemId: item.itemId,
    itemName: item.itemName || '',
    warehouse: item.warehouse || '',
    code: item.code || '',
    spec: item.spec || '',
    costPrice: item.costPrice || 0,
    borrowQty: item.quantity || 0,
    borrower: item.borrower || '',
    borrowTime: item.borrowTime || '',
    operatorId: item.operatorId || '',
  };
}

function mapReturnRecord(item) {
  return {
    id: item.id,
    borrowRecordId: item.loanId,
    itemId: item.itemId,
    itemName: item.itemName || '',
    warehouse: item.warehouse || '',
    code: item.code || '',
    spec: item.spec || '',
    costPrice: item.costPrice || 0,
    returnQty: item.returnQuantity || 0,
    borrower: item.borrower || '',
    operatorId: item.operatorId || '',
    operatorName: item.operatorName || '',
    time: item.returnTime || '',
    remark: item.remark || '',
    status: item.status || '正常',
  };
}
