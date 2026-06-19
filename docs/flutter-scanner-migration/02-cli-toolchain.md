# 02. Flutter 无 Android Studio 工具链

## 1. 原则

本项目不安装 Android Studio。

允许安装：

```text
Flutter SDK
Git
JDK
Android command-line tools
Android SDK Platform-Tools
Android SDK Build-Tools
Android SDK Platform
VS Code / Cursor / Claude Code / Codex
```

不允许把以下动作作为必需步骤：

```text
打开 Android Studio
Android Studio SDK Manager
Android Studio Device Manager
Android Studio Gradle Sync
Android Studio Run
```

## 2. 目录建议

Windows 推荐目录：

```text
D:\dev\flutter
D:\Android\Sdk
D:\project\WIP\Design
```

不建议放到：

```text
C:\Program Files
C:\Users\<user>\AppData
中文路径
带空格路径
```

## 3. 环境变量

PowerShell 临时设置：

```powershell
$env:FLUTTER_HOME="D:\dev\flutter"
$env:ANDROID_HOME="D:\Android\Sdk"
$env:ANDROID_SDK_ROOT="D:\Android\Sdk"
$env:JAVA_HOME="C:\Program Files\Java\jdk-17"
$env:Path="$env:FLUTTER_HOME\bin;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools;$env:Path"
```

长期使用应写入系统环境变量。

## 4. 安装 Android SDK CLI

只安装命令行工具，不安装 Android Studio。

需要安装的 SDK 包：

```powershell
sdkmanager "platform-tools" `
  "platforms;android-35" `
  "build-tools;35.0.0" `
  "cmdline-tools;latest"
```

接受许可证：

```powershell
flutter doctor --android-licenses
```

校验：

```powershell
flutter doctor
flutter devices
adb devices
```

Gate：

```text
[ ] flutter --version 正常
[ ] sdkmanager --version 正常
[ ] adb version 正常
[ ] flutter doctor 能识别 Android toolchain
[ ] flutter devices 能识别真机
```

## 5. 真机调试

手机开启：

```text
开发者选项
USB 调试
允许当前电脑调试
```

校验：

```powershell
adb devices
```

正确输出：

```text
设备序列号    device
```

错误输出处理：

| 输出 | 原因 | 处理 |
|---|---|---|
| `unauthorized` | 手机未授权 | 重新插拔 USB，手机确认授权 |
| 空列表 | 驱动或线材问题 | 换线、换 USB 口、安装 OEM USB driver |
| `offline` | adb 状态异常 | `adb kill-server && adb start-server` |

## 6. Flutter 项目创建

在主工程根目录执行：

```bash
flutter create flutter_shell --platforms=android
```

进入目录：

```bash
cd flutter_shell
flutter pub get
flutter run
```

Gate：

```text
[ ] flutter_shell/ 创建成功
[ ] flutter_shell/android/ 存在
[ ] flutter run 可在真机启动默认 Flutter APP
```

## 7. 构建 APK

Debug：

```bash
cd flutter_shell
flutter build apk --debug
```

Release：

```bash
cd flutter_shell
flutter build apk --release
```

分 ABI Release：

```bash
cd flutter_shell
flutter build apk --release --split-per-abi
```

安装：

```bash
flutter install
```

或：

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Gate：

```text
[ ] flutter build apk --debug 通过
[ ] flutter build apk --release 通过
[ ] APK 可安装
[ ] 安装后可打开 APP
```

## 8. 签名

生成 keystore：

```bash
keytool -genkeypair -v \
  -keystore warehouse-release.jks \
  -alias warehouse \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

禁止提交：

```text
*.jks
*.keystore
key.properties
```

Flutter Android 签名配置放在：

```text
flutter_shell/android/key.properties
flutter_shell/android/app/build.gradle
```

Gate：

```text
[ ] release APK 已签名
[ ] keystore 未提交 Git
[ ] key.properties 未提交 Git
```

## 9. Android Studio 提示处理

`flutter doctor` 可能提示 Android Studio 未安装。

本项目判断标准：

```text
只要 Android toolchain 可用、真机可识别、flutter build apk 可通过，Android Studio 未安装不是阻塞项。
```

阻塞项只有：

```text
Android toolchain 缺失
SDK licenses 未接受
adb 无法识别设备
flutter build apk 失败
```

## 10. 参考依据

Flutter 官方支持手动安装 Flutter SDK，并提供命令行构建、安装 APK 的流程。Android 侧仍需要 SDK、Build Tools、Platform Tools 和许可证，但这些可通过命令行工具完成，不需要 Android Studio 作为开发入口。
