# 02. Android CLI 工业扫码开发执行手册

## 1. 执行顺序

严格按以下顺序推进，禁止跳步：

```text
检查当前仓库
  → 保护现场
  → 修复/重建 Capacitor Android 工程
  → 接入原生扫码插件
  → 建立 scannerAdapter
  → 改造三条业务入口
  → 构建 APK
  → 真机测试
```

## 2. Phase 0：检查当前仓库

执行：

```bash
git status
npm run build
```

检查 Android 目录：

```bash
find android -maxdepth 3 -type f | sort
```

必须确认是否存在：

```text
android/settings.gradle
android/build.gradle
android/gradlew
android/gradlew.bat
android/app/build.gradle
android/app/src/main/AndroidManifest.xml
```

如果缺任何一个，视为 Android 工程不完整。

Gate 0：

```text
[ ] npm run build 通过
[ ] 当前 git 状态已记录
[ ] Android 工程完整性已确认
```

## 3. Phase 1：保护现场

执行：

```bash
git add .
git commit -m "chore: snapshot before android scanner migration"
```

如果暂时不能提交，至少记录：

```bash
git diff > scanner-migration-before.diff
```

Gate 1：

```text
[ ] 有 Git commit 或 diff 备份
[ ] 已确认可回滚
```

## 4. Phase 2：Capacitor 基础依赖

安装：

```bash
npm install @capacitor/core @capacitor/cli @capacitor/android
```

新增或修复 `capacitor.config.js`：

```js
export default {
  appId: 'com.warehouse.app',
  appName: '仓库管理',
  webDir: 'wms-app',
  server: {
    androidScheme: 'https',
  },
};
```

构建 Web：

```bash
npm run build
```

同步：

```bash
npx cap sync android
```

如果 `android/` 不完整，执行安全重建：

```bash
mv android android.backup
npx cap add android
npm run build
npx cap sync android
```

Windows PowerShell 对应命令：

```powershell
Rename-Item android android.backup
npx cap add android
npm run build
npx cap sync android
```

Gate 2：

```text
[ ] capacitor.config.js 存在
[ ] webDir 指向 wms-app
[ ] npx cap sync android 通过
[ ] android/ 下 Gradle 文件完整
```

## 5. Phase 3：Android CLI 环境

环境变量：

```powershell
$env:ANDROID_HOME="D:\Android\Sdk"
$env:ANDROID_SDK_ROOT="D:\Android\Sdk"
$env:JAVA_HOME="C:\Program Files\Java\jdk-17"
$env:Path += ";$env:ANDROID_HOME\cmdline-tools\latest\bin"
$env:Path += ";$env:ANDROID_HOME\platform-tools"
```

安装 SDK：

```powershell
sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0" "cmdline-tools;latest"
sdkmanager --licenses
```

真机连接：

```powershell
adb devices
```

Gate 3：

```text
[ ] sdkmanager 可执行
[ ] adb version 正常
[ ] adb devices 显示 device
[ ] 不依赖 Android Studio
```

## 6. Phase 4：接入原生扫码插件

建议插件：

```bash
npm install @capacitor-mlkit/barcode-scanning
npx cap sync android
```

如果插件包名或 API 与当前版本不同，必须先写兼容说明，不允许直接散落在业务页里。

新增：

```text
src/utils/nativeScanner.js
```

职责：

```js
export async function isNativeScannerAvailable() {}
export async function scanWithNativeScanner() {}
```

返回格式固定：

```js
{
  text: string,
  format: string,
  source: 'native',
  timestamp: number,
}
```

Gate 4：

```text
[ ] 插件安装成功
[ ] npx cap sync android 通过
[ ] nativeScanner.js 不包含业务接口调用
[ ] 原生扫码异常能抛出明确错误
```

## 7. Phase 5：统一扫码适配器

新增：

```text
src/utils/scannerAdapter.js
```

目标接口：

```js
export async function scanCode(options) {
  if (await isNativeScannerAvailable()) {
    return await scanWithNativeScanner(options);
  }

  return await scanWithWebScanner(options);
}
```

注意：Web fallback 可能需要 React 状态打开 `ScannerOverlay`，因此适配器可以分两层：

```text
scannerAdapter.js       # 判断运行环境
useScannerFlow.js       # React hook，协调原生或 Overlay
```

如果实现时发现 Promise 化 Overlay 复杂，允许先做页面级过渡，但必须保留统一边界。

Gate 5：

```text
[ ] 业务页不直接 import 原生插件
[ ] 业务页不直接 new Html5Qrcode
[ ] scannerAdapter 返回结构稳定
```

## 8. Phase 6：改造业务入口

涉及文件：

```text
src/pages/CheckoutTab.jsx
src/pages/ReturnTab.jsx
src/pages/InventoryTab.jsx
```

改造规则：

1. 保留原 `handleScan(code)` 业务处理。
2. 点击扫码按钮时，优先调用统一扫码流程。
3. 扫码结果只传 `text` 给原业务函数。
4. 原 Web `ScannerOverlay` 保留为 fallback。

伪代码：

```js
const result = await scanCode({ mode: 'checkout' });
await handleScan(result.text);
```

Gate 6：

```text
[ ] 出库扫码后仍打开出库登记
[ ] 归还扫码后仍打开归还流程
[ ] 盘点扫码后仍打开盘点表单
[ ] 失败提示可见
```

## 9. Phase 7：命令行构建 APK

Git Bash：

```bash
cd android
./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

PowerShell：

```powershell
cd android
.\gradlew.bat assembleDebug
adb install -r .\app\build\outputs\apk\debug\app-debug.apk
```

Gate 7：

```text
[ ] assembleDebug 成功
[ ] APK 安装成功
[ ] APP 打开后页面正常
[ ] 点击扫码拉起原生扫码
```

## 10. Phase 8：Release 包

生成 keystore：

```bash
keytool -genkeypair -v -keystore warehouse-release.jks -alias warehouse -keyalg RSA -keysize 2048 -validity 10000
```

禁止提交：

```text
*.jks
*.keystore
keystore.properties
```

构建：

```bash
cd android
./gradlew assembleRelease
```

Gate 8：

```text
[ ] release APK 可构建
[ ] 签名文件未提交 Git
[ ] 内部分发安装成功
```

## 11. 提交拆分

推荐提交：

```text
chore: add capacitor android cli baseline
feat: add native scanner wrapper
feat: add scanner adapter boundary
feat: route warehouse scan entries through scanner adapter
test: add industrial scanner verification checklist
```

每个提交都必须能说明：改了什么、为什么改、如何验证。
