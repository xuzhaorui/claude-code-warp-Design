# 03. Flutter 工业扫码开发执行手册

## 1. 总流程

```text
保护当前 Web 项目
  → 创建 flutter_shell
  → 修改 Vite 产物路径
  → 构建 Web 静态资源
  → 复制 wms-app 到 Flutter assets
  → Flutter WebView 加载 Web 页面
  → Web 页面增加扫码桥接工具
  → Flutter 增加 ScannerPage
  → Web 点击扫码调用 Flutter
  → 扫码结果回传 Web
  → 打包 APK 真机验证
```

## 2. Phase 0：保护现场

执行：

```bash
git status
git add .
git commit -m "chore: snapshot before flutter scanner migration"
```

Gate：

```text
[ ] 有可回滚 commit
[ ] 当前 npm run build 通过
```

## 3. Phase 1：创建 Flutter 壳工程

执行：

```bash
flutter create flutter_shell --platforms=android
cd flutter_shell
flutter pub get
flutter run
```

Gate：

```text
[ ] flutter_shell 创建成功
[ ] 真机能启动默认 Flutter 页面
[ ] 未安装 Android Studio
```

## 4. Phase 2：添加 Flutter 依赖

修改 `flutter_shell/pubspec.yaml`：

```yaml
dependencies:
  flutter:
    sdk: flutter
  webview_flutter: ^4.0.0
  webview_flutter_android: ^4.0.0
  mobile_scanner: ^7.0.0
```

增加 assets：

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/wms-app/
    - assets/wms-app/assets/
```

执行：

```bash
cd flutter_shell
flutter pub get
```

Gate：

```text
[ ] flutter pub get 通过
[ ] mobile_scanner 可解析
[ ] webview_flutter 可解析
```

## 5. Phase 3：调整 Vite 构建

修改根目录 `vite.config.js`：

```js
export default defineConfig({
  base: './',
  plugins: [...],
  build: {
    outDir: 'wms-app',
    emptyOutDir: true,
  },
});
```

原因：Flutter WebView 加载本地 asset 时，绝对路径 `/assets/...` 可能失效；必须使用相对路径 `./assets/...`。

执行：

```bash
npm run build
```

Gate：

```text
[ ] wms-app/index.html 存在
[ ] index.html 内资源路径为 ./assets 或相对路径
[ ] 浏览器预览仍正常
```

## 6. Phase 4：复制 Web 产物到 Flutter assets

创建目录：

```bash
mkdir -p flutter_shell/assets/wms-app
```

复制：

```bash
cp -r wms-app/* flutter_shell/assets/wms-app/
```

Windows PowerShell：

```powershell
New-Item -ItemType Directory -Force flutter_shell\assets\wms-app
Copy-Item -Recurse -Force wms-app\* flutter_shell\assets\wms-app\
```

Gate：

```text
[ ] flutter_shell/assets/wms-app/index.html 存在
[ ] flutter_shell/assets/wms-app/assets/ 存在
```

后续可以把复制动作做成脚本：

```text
scripts/build_flutter_assets.ps1
scripts/build_flutter_assets.sh
```

## 7. Phase 5：Flutter WebShell 页面

新增：

```text
flutter_shell/lib/pages/web_shell_page.dart
```

职责：

1. 创建 `WebViewController`。
2. 开启 JavaScript。
3. 加载 `assets/wms-app/index.html`。
4. 注册 `ScannerChannel`。
5. 接收 Web 的扫码请求。
6. 打开 `ScannerPage`。
7. 将扫码结果注入回 Web 页面。

关键伪代码：

```dart
controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..addJavaScriptChannel(
    'ScannerChannel',
    onMessageReceived: (message) async {
      final result = await Navigator.push(...ScannerPage...);
      controller.runJavaScript('window.__receiveWarehouseScanResult(...)');
    },
  )
  ..loadFlutterAsset('assets/wms-app/index.html');
```

Gate：

```text
[ ] APP 打开后显示 React 页面
[ ] 页面 JS/CSS 正常加载
[ ] WebView 不白屏
```

## 8. Phase 6：Flutter ScannerPage

新增：

```text
flutter_shell/lib/pages/scanner_page.dart
```

职责：

1. 全屏扫码。
2. 使用后置摄像头。
3. 支持 torch 按钮。
4. 支持 autoZoom。
5. 单次识别后立即返回。
6. 防止重复返回。

建议配置：

```dart
MobileScanner(
  controller: MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
    autoZoom: true,
    formats: [
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.itf,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  ),
  scanWindow: scanWindow,
  onDetect: (capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    Navigator.pop(context, ScanResult(...));
  },
)
```

Gate：

```text
[ ] 打开扫码页能看到相机
[ ] 扫码成功后自动返回 Web 页面
[ ] 同一个码不会重复触发两次
[ ] 补光按钮可用
[ ] 返回按钮可取消扫码
```

## 9. Phase 7：Web 侧扫码桥接

新增：

```text
src/utils/warehouseScannerBridge.js
```

职责：

1. 判断是否在 Flutter WebView 内。
2. 发送扫码请求。
3. 等待扫码结果。
4. 如果不是 Flutter WebView，则走原 `ScannerOverlay` fallback。

建议接口：

```js
export function isFlutterScannerAvailable() {
  return Boolean(window.ScannerChannel);
}

export async function scanWarehouseCode({ mode }) {
  if (!window.ScannerChannel) {
    throw new Error('FLUTTER_SCANNER_NOT_AVAILABLE');
  }

  const requestId = `scan_${Date.now()}`;
  window.ScannerChannel.postMessage(JSON.stringify({
    type: 'scan',
    requestId,
    mode,
  }));

  return waitForScanResult(requestId);
}
```

Gate：

```text
[ ] Web 页面能发出 ScannerChannel 消息
[ ] Flutter 能收到消息
[ ] Flutter 能回传结果
[ ] Promise 能正确 resolve/reject
```

## 10. Phase 8：改造业务入口

涉及：

```text
src/pages/CheckoutTab.jsx
src/pages/ReturnTab.jsx
src/pages/InventoryTab.jsx
```

保留现有：

```js
handleScan(code)
```

改造点击扫码逻辑：

```js
if (isFlutterScannerAvailable()) {
  const result = await scanWarehouseCode({ mode: 'checkout' });
  await handleScan(result.text);
  return;
}

setScanning(true);
```

Gate：

```text
[ ] APK 内点击扫码进入 Flutter ScannerPage
[ ] 浏览器内点击扫码仍进入 ScannerOverlay
[ ] 三个业务 Tab 均可用
```

## 11. Phase 9：构建与安装

执行完整链路：

```bash
npm run build
rm -rf flutter_shell/assets/wms-app
mkdir -p flutter_shell/assets/wms-app
cp -r wms-app/* flutter_shell/assets/wms-app/
cd flutter_shell
flutter pub get
flutter build apk --debug
flutter install
```

PowerShell：

```powershell
npm run build
Remove-Item -Recurse -Force flutter_shell\assets\wms-app -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force flutter_shell\assets\wms-app
Copy-Item -Recurse -Force wms-app\* flutter_shell\assets\wms-app\
cd flutter_shell
flutter pub get
flutter build apk --debug
flutter install
```

Gate：

```text
[ ] APK 安装成功
[ ] Web 页面显示正常
[ ] 扫码走 Flutter 原生扫码
```

## 12. 禁止事项

1. 禁止安装 Android Studio 作为必要步骤。
2. 禁止把出库/归还/盘点页面全量重写为 Flutter。
3. 禁止在 React 业务页面直接操作 WebView 原生细节。
4. 禁止让扫码页调用后端接口。
5. 禁止没有真机测试就宣布完成。
