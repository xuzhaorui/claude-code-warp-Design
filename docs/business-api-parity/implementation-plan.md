# Implementation Plan — Real Business API Integration

## 任务总览

| 任务 | 标题 | 依赖 | 预计文件数 | 测试数 |
|------|------|------|-----------|-------|
| task-031 | ServerConfigStore | 无 | 2-3 | 5-8 |
| task-032 | WarehouseApiClient Contract + Mock | task-031 | 3-4 | 10-15 |
| task-033 | HttpWarehouseApiClient Min | task-032 | 2 | 8-12 |
| task-034 | Scan → Real Data Lookup | task-033 | 4-5 | 10-15 |
| task-035 | Checkout Real Submit | task-034 | 2-3 | 5-8 |
| task-036 | Return Real Submit | task-034 | 2-3 | 5-8 |
| task-037 | InventoryCheck Real Submit | task-034 | 2-3 | 5-8 |
| task-038 | Record List Refresh | task-033 | 4-5 | 10-15 |
| task-039 | Device E2E Real API | task-035~038 | 1 | — |

---

## task-031: ServerConfigStore

### 目标
实现服务配置存储接口 + InMemory 实现 + 设置页 UI。

### 允许修改
- `flutter_shell/lib/features/settings/server_config_store.dart`
- `flutter_shell/lib/features/settings/server_config_page.dart`
- `flutter_shell/test/features/settings/server_config_store_test.dart`
- `flutter_shell/test/features/settings/server_config_page_test.dart`

### 禁止修改
- Checkout / Return / InventoryCheck
- Scanner
- WarehouseShell
- Design.md

### 测试要求
- ServerConfigStore interface is abstract
- InMemoryServerConfigStore implements load/save/active
- ServerConfigPage renders form with url+name inputs
- Save button stores config
- Active config is displayed

### 物理门禁
- flutter analyze
- flutter test (≥ 5 new tests)
- npm run physical:gate

---

## task-032: WarehouseApiClient Contract + MockClient

### 目标
定义 WarehouseApiClient 接口 + DTO + MockClient 供测试使用。

### 允许修改
- `flutter_shell/lib/services/warehouse_api_client.dart`
- `flutter_shell/lib/services/mock_warehouse_api_client.dart`
- `flutter_shell/test/services/warehouse_api_client_test.dart`
- `flutter_shell/test/services/mock_warehouse_api_client_test.dart`

### 禁止修改
- 业务表单组件
- Scanner
- WarehouseShell
- Design.md

### 接口方法
```dart
findInventoryByCode(String code) → InventoryItemDto?
findBorrowersByQrcode(String qrcode) → List<BorrowRecordDto>
submitCheckout(...) → void
submitReturn(...) → void
submitInventoryCheck(...) → void
fetchCheckoutRecords() → List<CheckoutRecordDto>
fetchReturnRecords() → List<ReturnRecordDto>
fetchInventoryCheckRecords() → List<InventoryCheckRecordDto>
```

### DTO 文件
- `InventoryItemDto`
- `BorrowRecordDto`
- `CheckoutRecordDto`
- `ReturnRecordDto`
- `InventoryCheckRecordDto`
- `ApiError`
- `AuthSession`

---

## task-033: HttpWarehouseApiClient Min

### 目标
实现基于 `http` (或 `dart:io` HttpClient) 的真实 HTTP 客户端。

### 允许修改
- `flutter_shell/lib/services/http_warehouse_api_client.dart`
- `flutter_shell/test/services/http_warehouse_api_client_test.dart`
- `flutter_shell/pubspec.yaml` (if adding http package)

### 禁止修改
- 业务表单
- Scanner
- Design.md

### 要求
- 使用 URL Session 上传
- 处理 401 → AuthExpired
- 处理 JSON 响应
- 支持 ServerConfigStore 中的 baseURL

---

## task-034: Scan → Real Data Lookup

### 目标
扫码后调用真实 API 查询库存 / 借用人，然后打开对应的业务表单。

### 允许修改
- `flutter_shell/lib/features/warehouse_shell/warehouse_shell_scanner_entry.dart`
- `flutter_shell/lib/features/warehouse_shell/warehouse_shell_form_wiring.dart`
- `flutter_shell/test/features/warehouse_shell/...`

### 扫码后流程
```
出库扫码 code
  → apiClient.findInventoryByCode(code)
  → if found: showCheckoutFormSheet(item)
  → if not found: show error toast

归还扫码 code
  → apiClient.findBorrowersByQrcode(code)
  → if found: show borrower select → showReturnFormSheet(record)
  → if not found: show error

盘点扫码 code
  → apiClient.findInventoryByCode(code)
  → if found: showInventoryCheckFormSheet(item)
  → if not found: show error
```

---

## task-035: Checkout Real Submit

### 目标
出库表单提交时调用真实 API。

### 修改范围
- `flutter_shell/lib/features/checkout/checkout_form.dart`
- `flutter_shell/lib/features/checkout/checkout_form_rules.dart` (if buildPayload needs update)

### 流程
```
CheckoutFormMin submit
  → buildPayload()
  → apiClient.submitCheckout(payload)
  → on success: close sheet + show toast + refresh records
  → on error: show error in sheet
```

---

## task-036: Return Real Submit

同 task-035 但用于归还表单。

---

## task-037: InventoryCheck Real Submit

同 task-035 但用于盘点表单。

---

## task-038: Record List Refresh

### 目标
为三个 tab 添加 PullToRefresh + 真实记录列表加载。

### 修改范围
- `flutter_shell/lib/features/warehouse_shell/warehouse_shell.dart`
- `flutter_shell/lib/features/warehouse_shell/warehouse_shell_form_wiring.dart`
- Three record section widgets

### 流程
```
Tab opens
  → apiClient.fetchXxxRecords()
  → display list (RecordCard) or empty state
Pull down
  → refresh: re-fetch
  → show loading indicator
```

---

## task-039: Device E2E Real API

### 目标
在小米 8 上完成真实 API 端到端验证。

### 真机验收点
1. 配置服务器地址 → 保存
2. 扫码 → 查库存 → 打开表单
3. 提交表单 → API 收到请求
4. 记录列表 → 正确显示
5. 下拉刷新 → 重新加载
6. 401 → 错误提示
7. 网络错误 → 友好提示
