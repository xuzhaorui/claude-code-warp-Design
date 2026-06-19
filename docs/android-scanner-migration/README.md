# 已废弃：Capacitor Android 扫码迁移方案

本目录原计划采用 Capacitor Android 壳增强扫码能力。

当前决策已变更：**不采用 Capacitor**。

原因：用户明确要求避开 Android Studio，并认为 Capacitor 路线仍容易回到 Android Studio 管理 Android 工程；同时工业扫码要求更强的原生扫码能力与更清晰的移动端工程边界。

新的有效方案见：

```text
docs/flutter-scanner-migration/
```

新方案采用：

```text
Flutter 壳
  + WebView 复用现有 React/Vite 页面
  + mobile_scanner / ML Kit 工业扫码
  + Flutter CLI + Android command-line tools
  + 不安装 Android Studio
```

本目录仅作为历史记录，不再作为执行依据。
