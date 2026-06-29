# Web API Audit — Full Inventory

## 通用基础设施

### CONFIG: Server Config
| 项目 | 值 |
|------|-----|
| 文件 | `src/api/config.js` |
| 依赖 | `localStorage('api-base-url')` |
| 鉴权 | Cookie (`credentials: 'include'`) |
| 错误模型 | `{success, code, msg, data}` — `success===false` 或 `code==='1'` 为失败 |
| 401 | `handleAuthExpired()` → 登出跳转 |

### CONFIG: URL Build

```
/api-root/store/{path}
/api-root = normalized stored base URL, with /store context path
DEV mode: /store/{path} via Vite proxy
```

### AUTH: Login / Session
| 项目 | 值 |
|------|-----|
| 文件 | `src/api/auth.js` |
| Login | `POST /login` — form body: `{username, password, rememberMe}` |
| Logout | `POST /logout` |
| Session | `localStorage('currentUser')` + `sessionStorage('wms-auth-session')` |
| 鉴权传输 | Cookie (session-based, `credentials: 'include'`) |
| 过期检测 | 401 status / redirected / HTML login page / `data.code===401` text match |

---

## API 清单

### 1. getItemByCode(code)

| 项目 | 值 |
|------|-----|
| 来源 | `src/api/outbound.js` L3 |
| Method | GET |
| Path | `/inventory/list/outbound_qrcode/{code}` |
| 参数 | code (path encodeURIComponent) |
| 响应 | `{data: {id, storageName, freightName, freightNumber, specification, quantity, unitPrice}}` |
| 使用 | CheckoutTab / InventoryTab — 扫码后查询库存 |
| 鉴权 | Cookie |
| 错误 | `ensureAjaxSuccess` → throw |

### 2. submitCheckout(record)

| 项目 | 值 |
|------|-----|
| 来源 | `src/api/outbound.js` L16 |
| Method | POST |
| Path | `/inventory/list/outbound` |
| Body | `{inventoryId, num, type, [totalPrice, costUnitPrice], [outDescription]}` |
| 使用 | CheckoutTab — 表单提交 |
| 鉴权 | Cookie |

### 3. getCheckoutRecords()

| 项目 | 值 |
|------|-----|
| 来源 | `src/api/outbound.js` L43 |
| Method | POST |
| Path | `/inventory/outbound/getUserOutboundInDay` |
| Body | `{}` (empty form) |
| 响应 | `{data: {rows: [...]}}` |
| 使用 | CheckoutTab — 加载出库记录列表 |
| 鉴权 | Cookie |

### 4. getBorrowersByQrcode(qrcode)

| 项目 | 值 |
|------|-----|
| 来源 | `src/api/return.js` L3 |
| Method | GET |
| Path | `/inventory/loan/loan_borrower_qrcode/{qrcode}` |
| 使用 | ReturnTab — 扫码匹配借用人 |
| 鉴权 | Cookie |

### 5. getBorrowerDetail(inventoryId, borrowerUserId)

| 项目 | 值 |
|------|-----|
| 来源 | `src/api/return.js` L14 |
| Method | GET |
| Path | `/inventory/loan/{inventoryId}/{borrowerUserId}` |
| 使用 | ReturnTab — 获取单个借用人详情 |
| 鉴权 | Cookie |

### 6. submitReturn(record)

| 项目 | 值 |
|------|-----|
| 来源 | `src/api/return.js` L26 |
| Method | POST |
| Path | `/inventory/loan/loanReturnInbound` |
| Body | `{loanId, freightId, storageId, quantity, type:2, inDescription}` |
| 使用 | ReturnTab — 归还表单提交 |
| 鉴权 | Cookie |

### 7. getReturnRecords()

| 项目 | 值 |
|------|-----|
| 来源 | `src/api/return.js` L47 |
| Method | GET |
| Path | `/inventory/inbound/returnLogTop/100` |
| 响应 | `{data: {rows: [...]}}` |
| 使用 | ReturnTab — 加载归还记录列表 |
| 鉴权 | Cookie |

### 8. submitInventoryCheck(record)

| 项目 | 值 |
|------|-----|
| 来源 | `src/api/inventory.js` L3 |
| Method | POST |
| Path | `/calculate/calculate/mobilePhoneInventory` |
| Body | `{inventoryId, physicalInventoryQuantity, remark}` |
| 使用 | InventoryCheckTab — 盘点表单提交 |
| 鉴权 | Cookie |

### 9. getInventoryCheckRecords()

| 项目 | 值 |
|------|-----|
| 来源 | `src/api/inventory.js` L21 |
| Method | POST |
| Path | `/calculate/calculate/mobilePhoneInventoryLog/100` |
| Body | `{}` (empty form) |
| 使用 | InventoryCheckTab — 加载盘点记录列表 |
| 鉴权 | Cookie |

### 10. Login

| 项目 | 值 |
|------|-----|
| 来源 | `src/api/auth.js` L5 |
| Method | POST |
| Path | `/login` |
| Body | `{username, password, rememberMe}` |
| 鉴权 | Cookie-based session |
| 使用 | 登录页 |

### 11. Logout

| 项目 | 值 |
|------|-----|
| 来源 | `src/api/auth.js` L27 |
| Method | POST |
| Path | `/logout` |
| 鉴权 | Cookie |
| 副作用 | 清除 localStorage/sessionStorage |

---

## 数据模型映射

### InventoryItemDto (出库扫码结果)
```dart
class InventoryItemDto {
  final int id;
  final String warehouse;       // storageName
  final String itemName;        // freightName
  final String code;            // freightNumber
  final String spec;            // specification
  final int stockQty;           // quantity
  final double costPrice;       // unitPrice
}
```

### BorrowRecordDto (归还扫码结果)
```dart
class BorrowRecordDto {
  final int id;
  final int loanId;
  final int inventoryId;
  final String itemName;        // freightName
  final String warehouse;       // storageName
  final String code;            // freightNumber
  final String spec;            // specification
  final int borrowQty;          // loanQuantity
  final double costPrice;       // loanPrice
  final String borrower;        // userName
  final String borrowTime;      // recentLoanInboundTime
}
```

### CheckoutRecordDto (出库记录列表)
```dart
class CheckoutRecordDto {
  final int id;
  final int inventoryId;
  final String itemName;
  final String code;
  final String spec;
  final int quantity;
  final int type;               // 1=外销, 2=外借
  final double saleTotalPrice;
  final double saleUnitPrice;
  final String remark;
  final String operatorName;
  final String time;
  final String status;          // '正常' | '已撤销'
}
```

### ReturnRecordDto (归还记录列表)
```dart
class ReturnRecordDto {
  final int id;
  final String itemName;
  final int returnQty;
  final String borrower;
  final String operatorName;
  final String time;
  final String status;
}
```

### InventoryCheckRecordDto (盘点记录列表)
```dart
class InventoryCheckRecordDto {
  final int id;
  final int inventoryId;
  final String itemName;
  final String code;
  final String spec;
  final int bookQty;
  final int actualQty;
  final int difference;
  final double costPrice;
  final String remark;
  final String operatorName;
  final String time;
}
```

---

## 错误处理模型

```dart
class ApiError {
  final String message;
  final int? httpStatus;
  final String? code;
}
```

Web 错误处理链：
1. HTTP 401 → `handleAuthExpired()` → redirect login
2. Redirected → "未登录或会话已过期"
3. HTML response with login page → `handleAuthExpired()`
4. 403 / HTML with 权限/denied → "账号权限不足"
5. `data.success === false` || `data.code === '1'` → `data.msg || fallbackMessage`
6. Network failure → throw
