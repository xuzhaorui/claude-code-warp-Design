# Business Flow Matrix — Web vs Flutter

| # | Web 业务流 | Web 文件 | API 调用 | Flutter 当前状态 | 缺口 | 下一步任务 |
|---|-----------|---------|---------|----------------|------|----------|
| 1 | App 启动 → 登录检查 | AppShell.jsx | `/login` GET | 无登录 — 直接进入 Shell | 无登录态、无 token、无 session | task-032 |
| 2 | 服务配置保存/切换 | ServerConfig.jsx | `localStorage('servers')` | 占位设置页，未接配置 | 无服务配置 UI、无持久化 | task-031 |
| 3 | 出库 tab 加载 → 记录列表 | CheckoutTab.jsx | `getCheckoutRecords()` | 无 API 调用 — 空状态 | 无记录列表查询 | task-038 |
| 4 | 出库扫码 → 查库存 | CheckoutTab.jsx | `getItemByCode(code)` | 扫码后自动弹 fixture 表单 | 未接真实库存查询 | task-034 |
| 5 | 出库表单提交 | CheckoutTab.jsx | `submitCheckout(record)` | Fixture callback — 不调用 API | 未接真实提交 | task-035 |
| 6 | 归还 tab 加载 → 记录列表 | ReturnTab.jsx | `getReturnRecords()` | 无 API 调用 — 空状态 | 无记录列表查询 | task-038 |
| 7 | 归还扫码 → 查借用人 | ReturnTab.jsx | `getBorrowersByQrcode(code)` | 扫码后自动弹 fixture 表单 | 未接真实借用人查询 | task-034 |
| 8 | 归还表单提交 | ReturnTab.jsx | `submitReturn(record)` | Fixture callback — 不调用 API | 未接真实提交 | task-036 |
| 9 | 盘点 tab 加载 → 记录列表 | InventoryTab.jsx | `getInventoryCheckRecords()` | 无 API 调用 — 空状态 | 无记录列表查询 | task-038 |
| 10 | 盘点扫码 → 查库存 | InventoryTab.jsx | `getItemByCode(code)` | 扫码后自动弹 fixture 表单 | 未接真实库存查询 | task-034 |
| 11 | 盘点表单提交 | InventoryTab.jsx | `submitInventoryCheck(record)` | Fixture callback — 不调用 API | 未接真实提交 | task-037 |
| 12 | 下拉刷新记录 | CheckoutTab/ReturnTab/InventoryTab | Pull-to-refresh + re-fetch | 无刷新机制 | 无 PullToRefresh | task-038 |
| 13 | Toast / 错误提示 | CheckoutTab/ReturnTab/InventoryTab | — | 无 Toast 组件 | 无用户错误反馈 | task-039 |
| 14 | 鉴权过期跳转 | config.js → handleAuthExpired | 401 检测 | 无 | 无错误拦截 | task-032 |
| 15 | 权限控制 tab | permissions.js | `getAllowedTabs(profile)` | 全部 4 tab 始终显示 | 无权限判断 | task-032 |

---

## 关键缺口分组

### Group A: 基础设施 (task-031, 032)
- 服务配置存储 (ServerConfigStore)
- API 客户端合同 (WarehouseApiClient)
- 登录/鉴权/401 拦截

### Group B: 库存查询 (task-034)
- 扫码 → 查库存 / 查借用人 → 打开真实表单

### Group C: 业务提交 (task-035, 036, 037)
- 出库 / 归还 / 盘点 表单提交 API

### Group D: 记录列表 (task-038)
- 三个列表的加载、刷新、空状态

### Group E: 端到端 (task-039)
- 真机 API 验收、Toast、错误处理
