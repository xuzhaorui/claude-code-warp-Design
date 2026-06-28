# Device Acceptance Test Report — Xiaomi 8

## Test Info

| 项目 | 值 |
|------|-----|
| 测试时间 | 2026-06-28 14:42~14:57 CST |
| 测试设备 | 小米 8 |
| Android 版本 | 10 (API 29) |
| 设备 ID | d96a5413 |
| 分支 | feature/warehouse-app |
| HEAD commit | f7cbe41 |
| Git clean | ✅ 是（报告生成前） |
| Physical gate (pre) | ✅ ALL PASS (6 checks) |
| Baseline verify (pre) | ✅ PASS |

## 安装启动

| 项目 | 结果 |
|------|------|
| APK 构建 | ✅ flutter build apk --debug 成功 |
| 安装 | ✅ adb install -r 成功 |
| App 启动 | ✅ 启动正常，进入 WarehouseShell |
| Crash | ❌ 无 crash |
| 终端异常 | ❌ 无异常日志 |
| 渲染引擎 | Impeller (Vulkan) |

## 路径 A：Shell 导航

| # | 测试项 | 结果 |
|---|--------|------|
| A1 | 默认进入出库 tab | ✅ PASS |
| A2 | 点击归还 tab | ✅ PASS |
| A3 | 点击盘点 tab | ✅ PASS |
| A4 | 点击回出库 tab | ✅ PASS |
| A5 | 页面无白屏 | ✅ PASS |
| A6 | 页面无 crash | ✅ PASS |
| A7 | 底部导航选中/未选中状态正常 | ✅ PASS |

**结论：** ✅ PASS — Shell 导航完全正常。

## 路径 B：业务表单入口

| # | 测试项 | 结果 |
|---|--------|------|
| B1 | 出库入口打开出库表单 | ✅ PASS |
| B2 | 出库表单输入数量/方式/备注 | ✅ PASS |
| B3 | 出库表单提交后不崩溃 | ✅ PASS |
| B4 | 归还入口打开归还表单 | ✅ PASS |
| B5 | 归还表单输入数量/备注 | ✅ PASS |
| B6 | 归还表单提交后不崩溃 | ✅ PASS |
| B7 | 盘点入口打开盘点表单 | ✅ PASS |
| B8 | 盘点表单修改实盘数量 | ✅ PASS |
| B9 | 盘点表单显示差值 (+5) | ✅ PASS |
| B10 | 盘点表单提交后不崩溃 | ✅ PASS |

**结论：** ✅ PASS — 三个业务表单均可打开、交互、提交，提交后不崩溃。

## 路径 C：扫码入口

| # | 测试项 | 结果 |
|---|--------|------|
| C1 | 点击扫码入口 | ✅ PASS |
| C2 | ScannerPage 正常打开 | ✅ PASS |
| C3 | Camera 预览正常 | ✅ PASS |
| C4 | 退出扫码按钮可返回 Shell | ✅ PASS |
| C5 | 返回后再次进入扫码页不崩溃 | ✅ PASS |

**结论：** ✅ PASS — 扫码入口正常工作。

## 路径 D：扫码识别

| # | 测试项 | 结果 |
|---|--------|------|
| D1 | 识别二维码 P293 | ✅ PASS |
| D2 | 识别二维码 SKU-TEST-001 | ✅ PASS |
| D3 | 终端输出 scan result | ✅ PASS |
| D4 | Shell 收到 scan callback | ✅ PASS |
| D5 | 多次扫描不崩溃 | ✅ PASS |
| D7 | 横竖移动手机不崩溃 | ✅ PASS |

**结论：** ✅ PASS — 两种二维码均成功识别，多次扫描无崩溃。

## 路径 E：回归稳定性

| # | 测试项 | 结果 |
|---|--------|------|
| E1 | 全程无 crash | ✅ PASS |
| E2 | 无明显卡死 | ✅ PASS |
| E3 | 无白屏 | ✅ PASS |
| E4 | 无不可返回页面 | ✅ PASS |

**结论：** ✅ PASS — 回归稳定性通过。

## 终端日志摘要

```
06-28 14:42:13 I flutter : Using the Impeller rendering backend (Vulkan).
06-28 14:42:13 I flutter : The Dart VM service is listening on http://127.0.0.1:39343/
```

扫码结果通过 `onScanResult` 回调输出到 Shell 层。

## 发现的问题

无 blocker。所有验收项均通过。

## 未覆盖项

1. ❌ 未测真实 API（当前版本故意未接）
2. ❌ 未测真实库存查询
3. ❌ 未测扫码后业务匹配
4. ❌ 未测登录态
5. ❌ 未测生产签名 APK
6. ❌ 未测多机型兼容
7. ❌ 未测弱光/破损码/低电量场景

## 最终结论

```text
PASS
```

所有 11 项成功标准均满足：

1. ✅ App 可安装
2. ✅ App 可启动
3. ✅ WarehouseShell 可操作
4. ✅ 三个 tab 可切换
5. ✅ 三类业务表单可打开并提交 callback
6. ✅ ScannerPage 可打开
7. ✅ 小米 8 能扫码（P293 和 SKU-TEST-001 均识别成功）
8. ✅ 扫码结果可回到 Shell callback
9. ✅ 全程无 crash
10. ✅ physical gate 通过
11. ✅ git status clean
