# Flutter CLI Toolchain Contract

## Principle

本项目默认不依赖 Android Studio。

只要 Android toolchain 可用、真机可识别、Flutter analyze/test/build 可通过，Android Studio 未安装不是阻塞项。

## Allowed Toolchain

允许：

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

禁止把以下动作作为必需步骤：

```text
打开 Android Studio
Android Studio SDK Manager
Android Studio Device Manager
Android Studio Gradle Sync
Android Studio Run
```

## Current Windows Paths

当前以已验证事实为准，不为了路径审美迁移 SDK。

```text
Flutter SDK:      D:\dev\flutter
Android SDK:      D:\Android\Sdk
Android AVD:      D:\Android\avd
Project root:     D:\claude-code-warp\Design
```

说明：

JAVA_HOME 实际路径：C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot

```text
SDK 已从 C:\Users\Lenovo\AppData\Local\Android\Sdk 迁移至 D:\Android\Sdk。
local.properties 已同步指向 D:\\Android\\Sdk。
AVD 存储路径跟随 ANDROID_AVD_HOME 移至 D:\Android\avd。
```

仍不建议新装到：

```text
C:\Program Files
中文路径
带空格路径
```

## Expected Environment Variables

PowerShell 当前会话设置：

```powershell
$env:FLUTTER_HOME="D:\dev\flutter"
$env:ANDROID_HOME="D:\Android\Sdk"
$env:ANDROID_SDK_ROOT="D:\Android\Sdk"
$env:ANDROID_AVD_HOME="D:\Android\avd"
$env:JAVA_HOME="C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
$env:Path="$env:FLUTTER_HOME\bin;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools;$env:Path"
```

用户系统环境变量已设置：

| 变量 | 值 |
|------|-----|
| `ANDROID_HOME` | `D:\Android\Sdk` |
| `ANDROID_SDK_ROOT` | `D:\Android\Sdk` |
| `ANDROID_AVD_HOME` | `D:\Android\avd` |

长期使用应写入系统环境变量。若 JDK 实际路径不同，先用 `where java` / `where keytool` / `flutter doctor -v` 查事实，再更新本契约。

长期使用应写入系统环境变量。若 JDK 实际路径不同，先用 `where java` / `where keytool` / `flutter doctor -v` 查事实，再更新本契约。

## CLI Environment Gates

```bash
flutter --version
sdkmanager --version
adb version
flutter doctor
flutter devices
adb devices
```

## Required Android SDK Packages

```powershell
sdkmanager "platform-tools" `
  "platforms;android-35" `
  "build-tools;35.0.0" `
  "cmdline-tools;latest"
```

许可证：

```powershell
flutter doctor --android-licenses
```

## Project Gates

```bash
cd flutter_shell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
flutter build apk --release --split-per-abi
```

## APK Install Gates

```bash
flutter install
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Signing Contract

生成 keystore 示例：

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

签名配置位置：

```text
flutter_shell/android/key.properties
flutter_shell/android/app/build.gradle
```

## Real Blockers

真正阻塞项只有：

```text
Android toolchain 缺失
SDK licenses 未接受
adb 无法识别设备
flutter analyze 失败
flutter test 失败
flutter build apk 失败
release 签名文件误提交 Git
```
