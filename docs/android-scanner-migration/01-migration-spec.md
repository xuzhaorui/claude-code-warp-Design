# 01. 工业扫码迁移规格说明

## 1. 问题定义

当前 `html5-qrcode` Web 扫码在普通测试场景可用，但在工业仓库场景下无法满足稳定性要求。

工业扫码的核心约束：

1. 标签可能磨损、反光、弯曲、尺寸小。
2. 仓库光线不稳定。
3. 操作员手持手机，抖动明显。
4. 扫码频次高，不能要求反复对焦。
5. 码制可能包含二维码和一维条码。
6. 识别失败会直接影响出库、归还、盘点效率。

结论：Web 摄像头扫码只能作为 fallback，不能作为工业主方案。

## 2. 目标方案

采用 Capacitor Android 壳复用现有 Web 页面，并新增 Android 原生扫码能力。

目标架构：

```text
src/pages/*Tab.jsx
      ↓
src/utils/scannerAdapter.js
      ↓
┌─────────────────────┬──────────────────────┐
│ Android APK 环境     │ 普通浏览器环境          │
├─────────────────────┼──────────────────────┤
│ NativeScannerPlugin │ ScannerOverlay        │
│ ML Kit / 原生扫码    │ html5-qrcode fallback │
└─────────────────────┴──────────────────────┘
      ↓
业务接口：getItemByCode / getBorrowersByQrcode
```

## 3. 关键边界

### 3.1 Web 业务边界

业务页面只能依赖统一扫码接口，不允许直接依赖原生插件。

允许：

```js
const code = await scanCode({ mode: 'checkout' });
```

禁止：

```js
BarcodeScanner.scan();
Html5Qrcode.start();
navigator.mediaDevices.getUserMedia();
```

原因：业务流程不应关心扫码实现，否则未来会形成三套重复逻辑。

### 3.2 原生扫码边界

原生扫码只负责返回字符串，不负责业务查询。

原生扫码返回：

```js
{
  text: 'ITEM-001',
  format: 'CODE_128',
  source: 'native',
  timestamp: 1780000000000
}
```

原生扫码不做：

1. 不调用后端接口。
2. 不判断库存。
3. 不打开业务表单。
4. 不写业务记录。

### 3.3 Web fallback 边界

Web fallback 保留现有 `ScannerOverlay`，仅作为以下场景兜底：

1. 用户通过浏览器访问。
2. Android 原生插件不可用。
3. 原生扫码异常退出。
4. 开发环境未接入 Android 壳。

## 4. 文件级设计

### 4.1 新增文件

```text
src/utils/scannerAdapter.js
src/utils/nativeScanner.js
src/utils/webScanner.js
```

职责：

| 文件 | 职责 |
|---|---|
| `scannerAdapter.js` | 对业务层提供唯一入口 |
| `nativeScanner.js` | 封装 Capacitor / ML Kit 插件调用 |
| `webScanner.js` | 触发现有 ScannerOverlay fallback |

### 4.2 修改文件

```text
src/pages/CheckoutTab.jsx
src/pages/ReturnTab.jsx
src/pages/InventoryTab.jsx
src/components/Scanner/ScannerOverlay.jsx
package.json
capacitor.config.js
```

修改原则：

1. 页面内保留原有业务处理函数 `handleScan`。
2. 页面内扫码入口改为调用统一适配器。
3. `ScannerOverlay` 保留，但变成 fallback。
4. 不改接口层，不改数据结构，不改登录逻辑。

## 5. 扫码模式

### 5.1 单次扫码

用于出库、归还、盘点当前流程。

流程：

```text
点击扫码
  → 打开原生扫码页
  → 识别一个码
  → 关闭扫码页
  → 返回 code
  → 进入现有表单
```

### 5.2 连续扫码

本阶段不做。

原因：当前业务扫描后需要填写数量、方式、备注等表单。连续扫码会引入队列、去重、批量提交，不属于本次最小迁移。

### 5.3 图片识别

保留现有“从图片识别”。

本阶段不迁移到原生图片识别，除非现场明确需要扫码枪拍照后识别。

## 6. 码制范围

第一阶段必须支持：

```text
QR_CODE
CODE_128
CODE_39
EAN_13
EAN_8
ITF
UPC_A
UPC_E
```

不在第一阶段支持：

```text
PDF_417
DATA_MATRIX
AZTEC
多码同时识别
批量框选识别
```

如现场标签包含 Data Matrix 或 PDF417，需要单独确认。

## 7. Android Studio 边界

本项目不把 Android Studio 作为必需工具。

允许使用：

```text
Node.js
npm
Capacitor CLI
Android command-line tools
sdkmanager
adb
Gradle Wrapper
keytool
apksigner
VS Code / Cursor / Claude Code / Codex
```

禁止把以下动作写成必需步骤：

```text
Open Android Studio
Sync Gradle in Android Studio
Run from Android Studio
Use Android Studio Profiler
Use Android Studio Device Manager
```

如果某插件官方文档只给 Android Studio 路线，必须转换为 CLI 路线。

## 8. 完成定义

本迁移完成必须同时满足：

1. `npm run build` 通过。
2. `npx cap sync android` 通过。
3. `./gradlew assembleDebug` 通过。
4. APK 可通过 `adb install -r` 安装。
5. Android APK 内扫码走原生能力。
6. 浏览器内扫码仍可 fallback。
7. 出库、归还、盘点三条业务流不破坏。
8. 真实仓库标签测试达到验收标准。
