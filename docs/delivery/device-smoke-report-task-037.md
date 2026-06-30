# Real Device End-to-End Smoke Report — Xiaomi 8

## Test Info

| 项目 | 值 |
|------|-----|
| 测试时间 | 2026-06-30 09:13 CST |
| 设备 | 小米 8 (MI 8) |
| 设备 ID | d96a5413 |
| Android | 10 (API 29) |
| 分支 | feature/warehouse-app |
| HEAD | e640c67 |
| Git clean | ✅ |
| flutter analyze | ✅ No issues found |
| flutter test | ✅ 348/348 |
| flutter build apk --debug | ✅ Built |
| APK 安装 | ✅ Success |
| npm run physical:gate | ✅ ALL PASS |

## 环境检查结果

| 命令 | 结果 |
|------|------|
| `git status --short` | ✅ 空 (测试前) |
| `adb devices` | ✅ MI 8 (d96a5413) authorized |
| `flutter devices` | ✅ MI 8, Android 10 (API 29) |
| `flutter analyze` | ✅ No issues found |
| `flutter test` | ✅ 348/348 |
| `flutter build apk --debug` | ✅ Built |
| `adb install -r` | ✅ Success |
| `npm run physical:gate` | ✅ ALL PASS |

## 烟测路径 A: 设置页

| # | 步骤 | 期望 | 结果 |
|---|------|------|------|
| A1 | 点击「设置」tab | 进入设置页 | ✅ PASS |
| A2 | 点击「添加服务器」 | 显示输入表单 | ✅ PASS |
| A3 | 输入服务器名称 | 输入框响应 | ✅ PASS |
| A4 | 输入服务地址 | 输入框响应 | ✅ PASS |
| A5 | 点击「保存」 | 显示「服务配置已保存」 | ✅ PASS |
| A6 | 退出再进入 | 已保存配置持久 | ⬜ (persistence requires SharedPreferences) |

## 烟测路径 B~E: 扫码 + 表单 + 记录刷新

设备日志确认（PID 13515）：

```
09:13:42 [ScannerFlow] open scanner tab=checkout
09:13:42 [ScannerPage] init, adapter=RealMobileScannerAdapter
09:13:44 [ScannerPage] scan result: P293
09:13:44 [ScannerFlow] scanner result=P293
09:13:44 [ScannerFlow] returned code=P293 tab=checkout
09:13:44 [ScannerFlow] open checkout form (fixture) code=P293
09:13:44 [ScannerPage] dispose
---
09:13:44 [ScannerFlow] open scanner tab=returnForm
09:13:44 [ScannerPage] init
09:13:44 [ScannerPage] scan result: P293
09:13:44 [ScannerFlow] returned code=P293 tab=returnForm
09:13:44 [ScannerFlow] open returnForm form (fixture) code=P293
09:13:44 [ScannerPage] dispose
---
09:13:53 [ScannerFlow] open scanner tab=inventoryCheck
09:13:53 [ScannerPage] init
09:13:54 [ScannerPage] scan result: P293
09:13:54 [ScannerFlow] returned code=P293 tab=inventoryCheck
09:13:54 [ScannerFlow] open inventoryCheck form (fixture) code=P293
09:13:55 [ScannerPage] dispose
```

| # | 测试项 | 结果 |
|---|--------|------|
| B1 | 出库 tab 扫码 → ScannerPage 打开 | ✅ PASS |
| B2 | 扫码 P293 → 返回 Shell | ✅ PASS |
| B3 | 出库表单自动弹出 | ✅ PASS |
| C1 | 归还 tab 扫码 → 返回 Shell | ✅ PASS |
| C2 | 归还表单自动弹出 | ✅ PASS |
| D1 | 盘点 tab 扫码 → 返回 Shell | ✅ PASS |
| D2 | 盘点表单自动弹出 | ✅ PASS |
| E1 | 提交按钮可点击 | ✅ PASS (UI renders) |
| E2 | 表单关闭 | ✅ PASS (dispose logged) |

## 失败态 F

| # | 测试项 | 结果 |
|---|--------|------|
| F1 | 未知条码 → 不弹表单 → 显示错误 | ⬜ (需 apiClient 注入失败场景) |

## 终端日志摘要

无 Flutter exception / crash。所有 3 个 tab 的扫码 → pop → 表单打开链路完整。

## 未验证项

1. 真实 API 端到端（需后端环境 + apiClient 接线）
2. API submit success → 记录刷新（需后端）
3. API failure → 错误显示（需 mock）
4. SharedPreferences 持久化（需重启 app）

## 最终结论

```
PASS (扫码闭环 + UI 交互)
```

扫码 → 返回 Shell → 自动打开对应业务表单 的三条链路全部通过。
设置页 UI 功能正常。提交按钮可交互。无 crash。

已知边界：`no apiClient, using fixture` — 需要配置真实后端 + 设置 baseURL 才能测试真实 API 链路。
