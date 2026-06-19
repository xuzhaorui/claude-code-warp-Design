# Flutter 工业扫码迁移文档索引

## 结论

当前项目的工业扫码增强路线改为 Flutter。

采用方案：

```text
Flutter Android APP
  ├─ WebView：承载现有 React/Vite 仓库管理页面
  ├─ ScannerPage：Flutter 原生扫码页，使用 mobile_scanner / ML Kit
  ├─ JavaScript Bridge：Web 页面点击扫码后调用 Flutter 原生扫码
  └─ Flutter CLI：构建、安装、签名，全程不安装 Android Studio
```

## 为什么不是全量 Flutter 重写

当前真正瓶颈是扫码，不是出库、归还、盘点业务页面。

因此第一阶段不重写业务 UI，而是：

1. 继续复用现有 React/Vite 页面。
2. 用 Flutter WebView 承载页面。
3. 把扫码从 Web 摄像头迁移到 Flutter 原生扫码页。
4. 扫码结果通过 JS Bridge 回传给 Web 页面。

这样可以最小化迁移成本，同时解决工业扫码灵敏度问题。

## 有效文档

| 文档 | 作用 |
|---|---|
| `01-migration-spec.md` | 迁移规格：目标、边界、架构、接口契约 |
| `02-cli-toolchain.md` | 无 Android Studio 工具链：Flutter、Android SDK CLI、构建命令 |
| `03-implementation-playbook.md` | 开发执行手册：文件改造、桥接、扫码页、构建流程 |
| `04-verification.md` | 验收标准：工业扫码测试、失败判断、回滚 |
| `05-ai-prompts.md` | 给 AI 执行的精确提词 |

## 废弃文档

```text
docs/android-scanner-migration/
```

该目录为 Capacitor 方案历史记录，不再作为执行依据。

## 必须确认的问题

这些问题影响实现参数，但不阻塞文档制定：

1. 现场主要码制是一维条码、二维码，还是混合？
2. 货物码内容是单字段编号，还是包含多个字段？
3. 是否存在专用工业 PDA？
4. 是否允许安装内部 APK？
5. 目标最低 Android 版本是多少？
6. 后端接口是固定公网/内网地址，还是需要用户在 APP 内配置？
