# Device Smoke Report — Xiaomi 8

## 基本信息

| 项目 | 值 |
|------|-----|
| 设备型号 | 小米 8 |
| Android 版本 | 10 |
| 连接方式 | USB debug over PowerShell |
| ADB 设备 ID | d96a5413 |
| Flutter Shell Commit | 5fad8d1（测试时 HEAD） |
| 测试入口 | `DeviceSmokeScannerApp` → `ScannerPage` + `RealMobileScannerAdapter` |

## 测试步骤

1. 构建 APK：`flutter build apk --debug` ✅ Built
2. 安装到设备：`flutter install` ✅ Success
3. 启动 App：自动进入 `ScannerPage`
4. Camera 权限请求：已授予
5. 对准二维码 `P293` 扫描

## 测试结果

| 步骤 | 结果 |
|------|------|
| APK 构建 | ✅ Built |
| 安装 | ✅ Success |
| App 启动 | ✅ 启动不崩溃 |
| Camera 预览 | ✅ 实时预览正常 |
| 二维码扫描 (#P293） | ✅ 扫码成功 |
| `onScanResult` 回调 | ✅ 触发，code 字符串正确 |
| `onScanFailure` 触发 | 未触发（扫码正常） |

## 验证链路

```
Camera (硬件)
  → mobile_scanner plugin
  → RealMobileScannerAdapter (监听 barcodeStream)
  → ScannerResult(code: "P293", rawValue: "P293", format: BarcodeFormat.qrCode, scannedAt: ...)
  → ScannerPage (onScanResult callback)
  → print("[ScannerSmoke] Result: P293")
```

## 结论

扫码链路端到端验证通过。`RealMobileScannerAdapter` 在真机上正常工作，
将 `mobile_scanner` 的 `BarcodeCapture` 事件正确转换为统一的 `ScannerResult`。

## 未覆盖项

- 扫码后未做业务匹配（不在此轮验证范围）
- 未测试连续扫码（测试说明中标记了 `skip` 的 long-press 场景）
- 未测试相机权限拒绝场景
- 未测试弱光 / 复杂背景扫码
