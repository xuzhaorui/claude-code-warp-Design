const inventoryItems = [
  { id: 'item-1', name: '笔记本电脑', warehouse: 'A仓', code: 'IT-001', spec: '14寸/16GB/512GB', costPrice: 4500, stockQty: 25 },
  { id: 'item-2', name: '机械键盘', warehouse: 'A仓', code: 'IT-002', spec: '87键/青轴', costPrice: 320, stockQty: 80 },
  { id: 'item-3', name: '无线鼠标', warehouse: 'B仓', code: 'IT-003', spec: '蓝牙/静音', costPrice: 85, stockQty: 150 },
  { id: 'item-4', name: '显示器', warehouse: 'A仓', code: 'IT-004', spec: '27寸/4K', costPrice: 2200, stockQty: 12 },
  { id: 'item-5', name: 'USB-C 数据线', warehouse: 'C仓', code: 'IT-005', spec: '1.5米/100W', costPrice: 25, stockQty: 500 },
];

let checkoutRecords = [
  { id: 'co-1', itemId: 'item-1', itemName: '笔记本电脑', warehouse: 'A仓', code: 'IT-001', spec: '14寸/16GB/512GB', costPrice: 4500, quantity: 2, method: '外销', saleTotalPrice: 11000, saleUnitPrice: 5500, remark: '客户采购', operatorId: 'user-1', operatorName: '张三', time: '2026-05-07 14:30:00', status: '正常' },
  { id: 'co-2', itemId: 'item-2', itemName: '机械键盘', warehouse: 'A仓', code: 'IT-002', spec: '87键/青轴', costPrice: 320, quantity: 5, method: '外借', saleTotalPrice: 0, saleUnitPrice: 0, remark: '部门借用', operatorId: 'user-1', operatorName: '张三', time: '2026-05-06 10:15:00', status: '正常' },
  { id: 'co-3', itemId: 'item-3', itemName: '无线鼠标', warehouse: 'B仓', code: 'IT-003', spec: '蓝牙/静音', costPrice: 85, quantity: 10, method: '外销', saleTotalPrice: 1200, saleUnitPrice: 120, remark: '', operatorId: 'user-2', operatorName: '李四', time: '2026-05-05 16:45:00', status: '已撤销' },
];

let borrowRecords = [
  { id: 'br-1', itemId: 'item-1', itemName: '笔记本电脑', warehouse: 'A仓', code: 'IT-001', spec: '14寸/16GB/512GB', costPrice: 4500, borrowQty: 3, borrower: '王五', borrowTime: '2026-05-03 09:00:00', operatorId: 'user-1' },
  { id: 'br-2', itemId: 'item-1', itemName: '笔记本电脑', warehouse: 'A仓', code: 'IT-001', spec: '14寸/16GB/512GB', costPrice: 4500, borrowQty: 2, borrower: '赵六', borrowTime: '2026-05-04 11:30:00', operatorId: 'user-1' },
  { id: 'br-3', itemId: 'item-2', itemName: '机械键盘', warehouse: 'A仓', code: 'IT-002', spec: '87键/青轴', costPrice: 320, borrowQty: 5, borrower: '王五', borrowTime: '2026-05-02 14:00:00', operatorId: 'user-2' },
];

let returnRecords = [
  { id: 'rt-1', borrowRecordId: 'br-1', itemId: 'item-1', itemName: '笔记本电脑', warehouse: 'A仓', code: 'IT-001', spec: '14寸/16GB/512GB', costPrice: 4500, returnQty: 1, borrower: '王五', operatorId: 'user-1', operatorName: '张三', time: '2026-05-06 15:00:00', remark: '归还一台' },
  { id: 'rt-2', borrowRecordId: 'br-3', itemId: 'item-2', itemName: '机械键盘', warehouse: 'A仓', code: 'IT-002', spec: '87键/青轴', costPrice: 320, returnQty: 3, borrower: '王五', operatorId: 'user-1', operatorName: '张三', time: '2026-05-05 10:00:00', remark: '' },
  { id: 'rt-3', borrowRecordId: 'br-2', itemId: 'item-1', itemName: '笔记本电脑', warehouse: 'A仓', code: 'IT-001', spec: '14寸/16GB/512GB', costPrice: 4500, returnQty: 1, borrower: '赵六', operatorId: 'user-2', operatorName: '李四', time: '2026-05-04 17:30:00', remark: '部分归还' },
];

let inventoryCheckRecords = [
  { id: 'ic-1', itemId: 'item-1', itemName: '笔记本电脑', warehouse: 'A仓', code: 'IT-001', spec: '14寸/16GB/512GB', bookQty: 25, actualQty: 24, difference: -1, remark: '少一台', operatorId: 'user-1', operatorName: '张三', time: '2026-05-07 08:00:00' },
  { id: 'ic-2', itemId: 'item-3', itemName: '无线鼠标', warehouse: 'B仓', code: 'IT-003', spec: '蓝牙/静音', bookQty: 150, actualQty: 150, difference: 0, remark: '', operatorId: 'user-1', operatorName: '张三', time: '2026-05-06 08:00:00' },
  { id: 'ic-3', itemId: 'item-5', itemName: 'USB-C 数据线', warehouse: 'C仓', code: 'IT-005', spec: '1.5米/100W', bookQty: 500, actualQty: 495, difference: -5, remark: '损耗', operatorId: 'user-2', operatorName: '李四', time: '2026-05-05 08:00:00' },
];

const mockUsers = [
  { id: 'user-1', username: 'admin', password: '123456' },
  { id: 'user-2', username: 'operator', password: '123456' },
];

const delay = (ms = 300) => new Promise(r => setTimeout(r, ms));

export async function getItemByCode(code) {
  await delay();
  return inventoryItems.find(i => i.code === code) || null;
}

export async function getCheckoutRecords() {
  await delay();
  return [...checkoutRecords].sort((a, b) => b.time.localeCompare(a.time));
}

export async function submitCheckout(record) {
  await delay();
  const item = inventoryItems.find(i => i.id === record.itemId);
  if (item) item.stockQty -= record.quantity;
  checkoutRecords.unshift(record);
  return record;
}

export async function getBorrowersByItem(itemId) {
  await delay();
  return borrowRecords.filter(b => b.itemId === itemId && b.borrowQty > 0);
}

export async function submitReturn(record) {
  await delay();
  const borrow = borrowRecords.find(b => b.id === record.borrowRecordId);
  if (borrow) borrow.borrowQty -= record.returnQty;
  returnRecords.unshift(record);
  return record;
}

export async function getReturnRecords() {
  await delay();
  return [...returnRecords].sort((a, b) => b.time.localeCompare(a.time));
}

export async function submitInventoryCheck(record) {
  await delay();
  const item = inventoryItems.find(i => i.id === record.itemId);
  if (item) item.stockQty = record.actualQty;
  inventoryCheckRecords.unshift(record);
  return record;
}

export async function getInventoryCheckRecords() {
  await delay();
  return [...inventoryCheckRecords].sort((a, b) => b.time.localeCompare(a.time));
}

export async function mockLogin(username, password) {
  await delay(500);
  if (!username || !password) return null;
  const user = mockUsers.find(u => u.username === username && u.password === password);
  if (user) return { id: user.id, username: user.username };
  return { id: 'user-' + Date.now(), username };
}
