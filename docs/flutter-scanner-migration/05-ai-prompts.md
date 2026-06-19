# 05. Flutter 工业扫码迁移 AI 执行提词

## 1. 总规划提词

```text
你是一名 Flutter + React 混合架构工程师。当前项目是 React 19 + Vite 的仓库管理 Web APP，路径为 D:\claude-code-warp\Design。目标是在不安装 Android Studio 的前提下，使用 Flutter 构建 Android APP 壳，通过 WebView 复用现有 wms-app 静态页面，并使用 mobile_scanner 提供工业级扫码能力。禁止使用 Capacitor，禁止全量重写业务页面，禁止把 Android Studio 写成必需步骤。请先阅读 docs/flutter-scanner-migration/ 下所有文档，再制定最小可执行计划。
```

## 2. 创建 Flutter 壳提词

```text
请在当前项目根目录创建 flutter_shell Flutter 工程，只支持 Android 平台。要求：
1. 使用 flutter create flutter_shell --platforms=android；
2. 不使用 Android Studio；
3. 添加 webview_flutter、webview_flutter_android、mobile_scanner 依赖；
4. 在 pubspec.yaml 中配置 assets/wms-app/；
5. 运行 flutter pub get；
6. 不改 React 业务代码；
7. 输出执行命令和验证结果。
```

## 3. WebView 壳实现提词

```text
请在 flutter_shell 中实现 WebView 壳页面。要求：
1. 新增 lib/pages/web_shell_page.dart；
2. 使用 WebViewController 加载 assets/wms-app/index.html；
3. JavaScriptMode 设置为 unrestricted；
4. 注册 ScannerChannel；
5. ScannerChannel 收到 scan 消息后打开 ScannerPage；
6. ScannerPage 返回结果后，通过 runJavaScript 向 Web 页面派发 warehouse-scan-result 事件；
7. 不在 Flutter 中调用任何仓库业务接口；
8. 运行 flutter analyze。
```

## 4. Flutter 扫码页实现提词

```text
请实现 Flutter 原生扫码页 lib/pages/scanner_page.dart。要求：
1. 使用 mobile_scanner；
2. 使用后置摄像头；
3. 开启 autoZoom；
4. detectionSpeed 使用 noDuplicates；
5. 支持 QR_CODE、CODE_128、CODE_39、CODE_93、EAN_13、EAN_8、ITF、UPC_A、UPC_E；
6. 提供补光按钮；
7. 提供取消按钮；
8. 首次识别成功后立即 Navigator.pop 返回 ScanResult；
9. 防止重复触发；
10. 不调用后端接口。
```

## 5. React 桥接提词

```text
请在 React Web 工程中新增 src/utils/warehouseScannerBridge.js，并改造 CheckoutTab.jsx、ReturnTab.jsx、InventoryTab.jsx。要求：
1. 判断 window.ScannerChannel 是否存在；
2. 如果存在，点击扫码时调用 Flutter 原生扫码；
3. 如果不存在，保留原 ScannerOverlay 逻辑；
4. Flutter 返回结果后继续调用原 handleScan(code)；
5. 不改变现有业务接口；
6. 不移除 html5-qrcode；
7. npm run build 必须通过。
```

## 6. 构建脚本提词

```text
请新增脚本，实现一键构建 Flutter APK。要求：
1. 先执行 npm run build；
2. 清空 flutter_shell/assets/wms-app；
3. 复制 wms-app 到 flutter_shell/assets/wms-app；
4. 进入 flutter_shell；
5. 执行 flutter pub get；
6. 执行 flutter build apk --debug；
7. 输出 APK 路径；
8. 提供 PowerShell 和 Git Bash 两套脚本；
9. 不使用 Android Studio。
```

## 7. 验收提词

```text
请根据 docs/flutter-scanner-migration/04-verification.md 执行验收。重点验证：
1. npm run build；
2. flutter analyze；
3. flutter build apk --debug；
4. flutter build apk --release；
5. 真机安装；
6. APK 内点击出库/归还/盘点扫码时进入 Flutter ScannerPage；
7. 浏览器访问时仍使用 Web ScannerOverlay；
8. 真实仓库条码扫码成功率；
9. 是否出现重复提交。
请输出通过/不通过，并列出阻塞问题。
```
