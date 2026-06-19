# 01. Flutter 工业扫码迁移规格

## 1. 目标

解决当前仓库管理 Web APP 在 Android 手机上工业扫码不灵敏的问题。

本迁移目标是：

```text
用 Flutter 提供 Android 原生扫码能力，继续复用当前 React/Vite 业务页面。
```

最终用户感知：

1. 打开的是一个 Android APP。
2. 页面仍是当前仓库管理页面。
3. 点击扫码时不再使用浏览器摄像头扫码。
4. 扫码时进入 Flutter 原生扫码页。
5. 扫码成功后返回当前业务表单。

## 2. 非目标

本阶段不做：

1. 不全量重写 React 页面为 Flutter 页面。
2. 不引入 Android Studio。
3. 不使用 Capacitor。
4. 不继续把 Web 扫码作为主方案。
5. 不改后端接口。
6. 不改登录、权限、出库、归还、盘点业务规则。
7. 不做连续批量扫码。
8. 不做离线数据库。

## 3. 总体架构

```text
D:\claude-code-warp\Design
  ├─ src/                         # 当前 React/Vite Web 业务
  ├─ wms-app/                     # npm run build 输出
  ├─ flutter_shell/               # 新增 Flutter APP
  │   ├─ lib/main.dart
  │   ├─ lib/pages/web_shell_page.dart
  │   ├─ lib/pages/scanner_page.dart
  │   ├─ assets/wms-app/          # 打包后的 Web 静态资源
  │   └─ android/                 # Flutter 自动生成 Android 工程
  └─ docs/flutter-scanner-migration/
```

运行结构：

```text
Flutter APP
  ↓
WebView 加载 assets/wms-app/index.html
  ↓
React 页面运行
  ↓
用户点击扫码
  ↓
JS Bridge 调用 Flutter
  ↓
Flutter 打开 ScannerPage
  ↓
mobile_scanner 调用 Android CameraX / ML Kit
  ↓
返回 code 给 WebView
  ↓
React 继续调用现有业务接口
```

## 4. 技术选型

### 4.1 Flutter 壳

选择 Flutter 的原因：

1. Flutter CLI 可以创建、运行、构建 Android APP。
2. 不需要安装 Android Studio 作为开发入口。
3. Flutter 插件生态有成熟扫码插件。
4. 可以通过 WebView 复用现有 Web 页面。
5. Android 工程由 Flutter 维护，日常只操作 Flutter CLI。

### 4.2 WebView

使用：

```yaml
webview_flutter
```

职责：

1. 加载现有 `wms-app/index.html`。
2. 提供 JavaScript Channel。
3. 接收 Web 页面扫码请求。
4. 将扫码结果回传给 Web 页面。

### 4.3 扫码插件

使用：

```yaml
mobile_scanner
```

职责：

1. 调用 Android CameraX / ML Kit。
2. 支持二维码和主流一维条码。
3. 支持 scanWindow。
4. 支持 autoZoom。
5. 支持 torch。
6. 支持单次扫码返回。

## 5. Web 与 Flutter 的接口契约

### 5.1 Web 发起扫码

Web 页面调用：

```js
window.WarehouseScanner.scan({
  mode: 'checkout'
});
```

Flutter 接收消息：

```json
{
  "type": "scan",
  "requestId": "scan_1780000000000",
  "mode": "checkout"
}
```

### 5.2 Flutter 返回扫码成功

Flutter 注入 JS：

```js
window.dispatchEvent(new CustomEvent('warehouse-scan-result', {
  detail: {
    requestId: 'scan_1780000000000',
    ok: true,
    text: 'ITEM-001',
    format: 'CODE_128',
    source: 'flutter-mobile-scanner'
  }
}));
```

### 5.3 Flutter 返回扫码失败或取消

```js
window.dispatchEvent(new CustomEvent('warehouse-scan-result', {
  detail: {
    requestId: 'scan_1780000000000',
    ok: false,
    errorCode: 'USER_CANCELLED',
    message: '用户取消扫码'
  }
}));
```

## 6. 业务页面边界

React 页面只允许依赖一个统一工具：

```text
src/utils/warehouseScannerBridge.js
```

禁止业务页面直接写：

```js
window.ScannerChannel.postMessage(...)
Html5Qrcode.start(...)
navigator.mediaDevices.getUserMedia(...)
```

业务页面只使用：

```js
const result = await scanWarehouseCode({ mode: 'checkout' });
await handleScan(result.text);
```

## 7. Web fallback 策略

浏览器访问仍保留 fallback。

判断逻辑：

```text
如果 window.ScannerChannel 存在
  → 使用 Flutter 原生扫码
否则
  → 使用原 ScannerOverlay / html5-qrcode
```

原因：

1. APK 内必须用 Flutter 原生扫码。
2. 浏览器内仍可继续访问。
3. 开发环境无需每次打 APK。

## 8. Vite 构建要求

当前 `vite.config.js` 输出：

```js
outDir: 'wms-app'
```

Flutter 加载本地静态资源时，Vite 必须使用相对路径：

```js
base: './'
```

否则 `index.html` 内引用 `/assets/...`，在 Flutter asset WebView 中可能加载失败。

验收标准：

```text
flutter_shell/assets/wms-app/index.html 可以正确加载 JS/CSS
WebView 中页面不白屏
```

## 9. 码制范围

第一阶段支持：

```text
QR_CODE
CODE_128
CODE_39
CODE_93
EAN_13
EAN_8
ITF
UPC_A
UPC_E
```

暂不支持：

```text
PDF_417
DATA_MATRIX
AZTEC
多码同时返回
批量扫码队列
```

如果现场存在 PDF417 / Data Matrix，必须先确认后再扩展。

## 10. 完成定义

必须全部满足：

1. 不安装 Android Studio。
2. `flutter doctor` Android toolchain 可用，允许 Android Studio 项提示非阻塞。
3. `npm run build` 通过。
4. Web 静态资源成功复制到 Flutter assets。
5. `flutter pub get` 通过。
6. `flutter run` 可在真机运行。
7. `flutter build apk` 可生成 APK。
8. APK 内扫码使用 `mobile_scanner`。
9. 出库、归还、盘点扫码流程可用。
10. 浏览器访问仍可 fallback。
11. 工业现场扫码验收通过。
