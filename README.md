# 仓库管理（Warehouse App）

仓库管理系统 — React Web 应用 + Flutter 原生 Android 客户端。

## 项目结构

```
├── src/                  # React + Vite Web 应用（参考实现）
├── flutter_shell/        # Flutter 原生 Android 客户端
├── scripts/              # 构建、物理门禁等工具脚本
├── Design.md             # 设计令牌规范（颜色、排版、间距）
└── CLAUDE.md             # 开发规则与约定
```

## Flutter 客户端

基于 `mobile_scanner` 的原生扫码仓库管理应用，完全对齐 Web 版功能：

- **扫码出库 / 归还 / 盘点** — 聚焦框 + 扫描动画 + 音效震动反馈
- **权限管理** — Tab 可见性与成本单价控制，对齐 Web 权限模型
- **多服务器配置** — 添加 / 编辑 / 删除 / 切换
- **会话管理** — 持久化登录 + 302/401 自动过期检测

### 构建

```bash
cd flutter_shell
flutter pub get
flutter build apk --release   # 产出 build/app/outputs/flutter-apk/app-release.apk
```

### 物理门禁

代码变更必须通过物理门禁验证（design:lint + flutter analyze + flutter test + build + baseline）：

```bash
npm run physical:gate:baseline   # 刷新基线快照
npm run physical:gate            # 运行门禁（期望 ALL PASS）
```

## Web 应用

React + Vite 前端，Vite 开发服务器：

```bash
npm install
npm run dev
```

## 文档

- 使用文档：`docs/delivery/warehouse-app-usage-guide.md`

## 版本

最新版本：**v1.0.3** — [下载 APK](https://github.com/xuzhaorui/warehouse-app/releases/tag/v1.0.3)
