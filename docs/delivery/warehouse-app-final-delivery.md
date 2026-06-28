# Warehouse App — Flutter Shell 最终交付说明

## 1. 项目目标

将现有仓库管理移动 Web APP 逐步改造为 Flutter 原生实现，
保持原 Web 版 UI/UX、业务流程、接口行为一致。

核心流程覆盖：**出库 / 归还 / 盘点 / 扫码 / 服务器配置**。

## 2. 完成范围

### Flutter 原生层

| 模块 | 说明 |
|------|------|
| Design Token 基础设施 | 5 个 token 文件（colors、text styles、spacing、radii、theme） |
| 7 个基础组件 | RecordCard、AppTextField、AppButton、AppSelectCard、AppBottomSheet、AppStepper、AppSegmentedControl |
| 3 个业务表单 UI | CheckoutFormMin、ReturnFormMin、InventoryCheckFormMin |
| 3 个业务规则层 | CheckoutFormRules、ReturnFormRules、InventoryCheckFormRules |
| BusinessFormSheets | 整合三个表单到 AppBottomSheet 的集成层 |
| WarehouseShellMin | 底部导航壳 + 表单/扫码入口 |
| Scanner 合同 + Adapter | ScannerAdapter 接口 + MockScannerAdapter + RealMobileScannerAdapter |
| ScannerPage | 全屏扫码页，支持 adapter 注入 |
| Physical Gate Runtime | 可执行门禁脚本 + baseline 锁定 + 机器可读报告 |
| CLI Toolchain 文档 | Flutter SDK、Android SDK、adb 真机验证流程 |

### 测试覆盖

- Flutter widget test: **284 个**，覆盖全部组件和表单
- `flutter analyze`: ✅ No issues found
- `flutter test`: ✅ 284/284 All tests passed
- `flutter build apk --debug`: ✅ Built

### 真机验证

- 设备：小米 8（Android 10）
- 扫码链路：✅ 通过
- 示例扫码结果：`P293`

## 3. 架构分层

```
flutter_shell/lib/
├── design/              # Design Token 基础设施
│   ├── app_design_colors.dart
│   ├── app_text_styles.dart
│   ├── app_spacing.dart
│   ├── app_radii.dart
│   └── app_theme.dart
├── components/          # 通用 UI 组件
│   ├── record_card.dart
│   ├── app_text_field.dart
│   ├── app_button.dart
│   ├── app_select_card.dart
│   ├── app_bottom_sheet.dart
│   ├── app_stepper.dart
│   └── app_segmented_control.dart
├── features/            # 领域功能
│   ├── checkout/        # 出库表单 + 规则
│   ├── return_form/     # 归还表单 + 规则
│   ├── inventory_check/ # 盘点表单 + 规则
│   ├── business_forms/  # 三个表单的 BottomSheet 集成
│   ├── warehouse_shell/ # 底部导航壳 + 表单/扫码入口
│   └── scanner/         # ScannerAdapter 合同 + 实现
├── pages/
│   ├── scanner_page.dart      # 全屏扫码页
│   └── web_shell_page.dart    # WebView 过渡兼容层
└── main.dart            # 应用入口（WarehouseApp）
```

## 4. 核心链路

### 扫码链路

```
WarehouseShell
  → ScannerPage
  → ScannerAdapter
  → RealMobileScannerAdapter
  → Camera (mobile_scanner)
  → Scan Result (code string)
  → Shell callback (onScanResult)
```

扫码结果从硬件 camera 经 `RealMobileScannerAdapter` 流式传递到 `ScannerPage`，
通过 `onScanResult` 回调到 `WarehouseShell`。当前仅做 `print` 日志，未接入业务匹配。

### 表单链路

```
WarehouseShell
  → BusinessFormSheets (AppBottomSheet)
  → CheckoutFormMin / ReturnFormMin / InventoryCheckFormMin
  → FormRules (evaluate / buildPayload)
  → Payload callback to Shell
```

## 5. 已完成模块清单

- [x] Design Token 基础设施（5 token 文件）
- [x] RecordCard 组件 + 7 测试
- [x] AppTextField 组件 + 8 测试
- [x] AppButton 组件 + 6 测试
- [x] AppSelectCard 组件 + 6 测试
- [x] AppBottomSheet 组件 + 8 测试
- [x] AppStepper 组件 + 10 测试
- [x] AppSegmentedControl 组件 + 7 测试
- [x] AppFormSection 组件 + 4 测试
- [x] CheckoutFormRules 规则层 + 26 测试
- [x] ReturnFormRules 规则层 + 22 测试
- [x] InventoryCheckFormRules 规则层 + 24 测试
- [x] CheckoutFormMin UI 表单 + 17 测试
- [x] ReturnFormMin UI 表单 + 12 测试
- [x] InventoryCheckFormMin UI 表单 + 15 测试
- [x] BusinessFormSheets 集成层 + 10 测试
- [x] WarehouseShellMin 导航壳 + 48 测试
- [x] ScannerAdapter 接口合同 + 20 测试
- [x] RealMobileScannerAdapter 实现 + 20 测试
- [x] ScannerPage UI + 13 测试
- [x] ScannerPage ↔ WarehouseShell 正式接线 + 10 测试
- [x] Physical Gate Runtime（5 npm scripts）
- [x] Baseline Lock（drift detection）

## 6. 未接入内容清单

以下内容**不在当前交付范围内**，需后续迭代：

- **未接真实 API** — 表单 submit callback 仅返回 payload（Map），未发送 HTTP 请求
- **未接真实库存查询** — `CheckoutItemSnapshot` 等模型数据为 Fixture，不从服务器加载
- **未做扫码结果业务匹配** — ScannerPage 的 `onScanResult` 仅 `print`，未调取库存/打开表单
- **未做登录态** — 无登录页面、token 管理、鉴权拦截
- **未做服务端提交** — 表单 `onSubmit` callback 返回 payload 后停止，未 POST 到服务器
- **未做生产发布签名 APK** — 仅有 `flutter build apk --debug`，需配置 release keystore
- **WebView 兼容桥未替换** — `WebShellPage` 保留，部分 Web 页面仍通过 WebView 加载
- **`mobile_scanner` KGP 警告** — 非阻塞，需升级 plugin 版本或等待 Flutter 内置 Kotlin 支持

## 7. 真机验证结果

| 项目 | 值 |
|------|-----|
| 设备 | 小米 8 (d96a5413) |
| Android | 10 |
| 连接方式 | USB debug over PowerShell |
| 验证入口 | `DeviceSmokeScannerApp` → `ScannerPage` + `RealMobileScannerAdapter` |
| Camera 权限 | 已授予 |
| 扫码测试 | ✅ 扫描二维码 `P293` 成功 |
| 结果回调 | `onScanResult(code: P293)` 触发，code 字符串正确 |
| 验证范围 | camera → `mobile_scanner` → `RealMobileScannerAdapter` → `ScannerPage` callback |
| 验证结论 | 扫码链路端到端通过，Adatper 将原始 Barcode 转换为 `ScannerResult(code, rawValue, format, scannedAt)` |

## 8. 物理门禁结果

```text
npm run physical:gate       → ALL PASS (6 checks)
npm run physical:gate:verify → PASS — no drift detected
npm run physical:gate:report → clean, no unexpected dirty
```

## 9. 风险与后续建议

| 风险 | 影响 | 建议 |
|------|------|------|
| KGP 警告 | build 时 warning，Flutter 未来版本可能 error | 升级 `mobile_scanner` 到兼容 Built-in Kotlin 的版本 |
| 未接 API | 表单不能真正提交 | 下一阶段接入真实 HTTP 层 |
| 未做登录态 | 无法部署到生产 | 实现登录流程 + token 管理 |
| 未做扫码匹配 | 扫码后不会自动打开表单 | 实现 code → item lookup → form open 链路 |
| WebView 残留 | 部分页面仍用 WebView | 逐个替换为 Flutter 原生页面 |
