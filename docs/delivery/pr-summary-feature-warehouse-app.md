# Pull Request: feature/warehouse-app — Flutter Shell Migration

## Summary

将仓库管理 Web APP 的移动端逐步改造为 Flutter 原生实现。
保持原 Web 版 UI/UX、业务流程和接口行为。

当前分支已完成 **Flutter 原生壳层**：design token 基础设施、7 个通用 UI 组件、
3 个业务表单（出库/归还/盘点）的规则层 + UI 层、底部导航壳 (WarehouseShell)、
扫码能力 (ScannerAdapter → RealMobileScannerAdapter → ScannerPage)、
以及可执行物理门禁脚本 + 基线锁定。

## What Changed

**40 commits** across `flutter_shell/lib/`、`flutter_shell/test/`、`scripts/`、`docs/`。

### 新文件（~280 个 Flutter widget/test 文件）

```
flutter_shell/lib/design/          → 5 token 文件
flutter_shell/lib/components/       → 7 个通用 UI 组件
flutter_shell/lib/features/         → 3 业务规则层 + 3 表单 UI + 集成层 + 导航壳 + scanner
flutter_shell/lib/pages/            → ScannerPage
flutter_shell/test/                 → 284 个 widget test
scripts/                            → 物理门禁脚本 + git 报告脚本
```

### 核心功能

| 功能 | 状态 |
|------|------|
| Flutter Design Token | ✅ 5 token 文件，与 Design.md 一致 |
| 通用 UI 组件 | ✅ RecordCard, AppTextField, AppButton, AppSelectCard, AppBottomSheet, AppStepper, AppSegmentedControl |
| 出库表单 (Checkout) | ✅ 规则层 + UI 表单 + 测试 |
| 归还表单 (Return) | ✅ 规则层 + UI 表单 + 测试 |
| 盘点表单 (InventoryCheck) | ✅ 规则层 + UI 表单 + 测试 |
| 表单 BottomSheet 集成 | ✅ BusinessFormSheets |
| 底部导航壳 | ✅ WarehouseShellMin（3 tab + 扫码按钮）|
| Scanner 架构 | ✅ Adapter 合同 + Mock + RealMobileScannerAdapter + ScannerPage |
| Shell ↔ Scanner 接线 | ✅ WarehouseShell → ScannerPage → RealMobileScannerAdapter |
| Physical Gate | ✅ 可执行脚本 + 基线锁定 + 报告 |
| Design.md lint | ✅ 0 errors, 0 warnings |
| Flutter analyze | ✅ No issues found |
| Flutter test | ✅ 284/284 |
| Debug APK build | ✅ Built |

## Architecture

```
WarehouseShell
├── ScannerPage → RealMobileScannerAdapter → Camera
│   └── onScanResult → Shell callback
└── BusinessFormSheets (AppBottomSheet)
    ├── CheckoutFormMin → CheckoutFormRules → Payload
    ├── ReturnFormMin → ReturnFormRules → Payload
    └── InventoryCheckFormMin → InventoryCheckFormRules → Payload
```

## Validation

- `npm run physical:gate`: ✅ ALL PASS（6 checks）
- `npm run physical:gate:verify`: ✅ no drift detected
- `flutter analyze`: ✅ No issues found
- `flutter test`: ✅ 284/284 tests passed
- `flutter build apk --debug`: ✅ Built

## Device Testing

- **设备**: 小米 8（Android 10, USB debug）
- **测试内容**: ScannerPage + RealMobileScannerAdapter 真机扫码
- **验证结果**: 二维码 `P293` 被成功扫描，`onScanResult` 回调正确触发

## What Is Intentionally Not Included

- ❌ 真实 API 调用（form submit 仅返回 payload Map）
- ❌ 真实库存查询（使用 Fixture 数据）
- ❌ 扫码结果业务匹配（onScanResult 仅 print）
- ❌ 登录态 / 鉴权
- ❌ 生产签名 APK
- ❌ WebView 完全替换（WebShellPage 留存过渡）
- ❌ `mobile_scanner` KGP 警告修复（非阻塞）

## Risk

- 低：KGP 警告非阻塞，未来 Flutter 版本可能升级为 error
- 中：表单和 scanner 未接 API，当前为纯 UI 壳层
- 低：WebView 残留作为降级路径，不阻塞原生模块

## Next Steps

1. 接入真实 HTTP API 层（提交表单、查询库存）
2. 实现扫码结果 → 库存匹配 → 自动打开表单的链路
3. 实现登录流程 + token 管理
4. 配置 release keystore 生成签名 APK
5. 逐个替换 WebView 页面为 Flutter 原生页面
6. 升级 `mobile_scanner` plugin 解决 KGP 警告
