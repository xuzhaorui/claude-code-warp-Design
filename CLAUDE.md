# Warehouse Flutter Parity Rules

## Mission

当前分支目标：将现有仓库管理移动 Web APP 逐步改造为 Flutter 原生实现，并保持原 Web 版 UI/UX、业务流程、接口行为一致。

核心流程：出库 / 归还 / 盘点 / 扫码 / 服务器配置。

第一性原理：

> 人类给方向，`Design.md` 给设计契约，现有 Web 代码给行为参考，Flutter 编译器 / Analyzer / Linter 给真实裁判。

## Source of Truth

1. `CLAUDE.md` — Agent 执行纪律。
2. `Design.md` — 唯一设计物理契约，包含可 lint 的 token、组件规则、Flutter 映射。
3. `src/pages/`、`src/components/`、`src/api/` — Web 行为与接口参考，不是 Flutter 技术约束。
4. `flutter_shell/lib/` — Flutter 实现目标。

禁止把旧 Web 技术栈、HTML 样例、截图主观观感当成 Flutter 设计契约。

## CLI Toolchain Contract

工具链契约见：`docs/flutter-scanner-migration/cli-toolchain-contract.md`。

本项目默认不依赖 Android Studio。Android Studio 未安装不是阻塞项。

Agent 涉及 Flutter 环境、Android SDK、真机、APK、签名时，必须先按该契约验证，不得凭经验假设环境可用。

真正阻塞项只有：Android toolchain 缺失、SDK licenses 未接受、adb 无法识别设备、Flutter analyze/test/build 失败、签名文件误提交 Git。

## Physical Gate Protocol

任意一轮实现、重构、UI 迁移或修复后，必须执行：

```bash
npm run design:lint
cd flutter_shell && flutter analyze
```

阶段交付前优先执行：

```bash
npm run physical:lint
cd flutter_shell && flutter test
cd flutter_shell && flutter build apk --debug
```

规则：

- 未跑物理门禁，视为未完成。
- `Design.md` lint 失败，先修 token / 引用 / 对比度 / 结构。
- `flutter analyze` 失败，先修 Flutter 静态问题。
- 有测试文件就跑 `flutter test`；没有测试文件必须说明，不得伪造通过。
- 不允许用“看起来一致”“应该没问题”“AI 认为完成”作为验收。

## Failure Protocol

- 第 1 次失败：读取报错，直接修。
- 第 2 次失败：收缩范围，只查相关文件、token、组件边界。
- 第 3 次失败：停止扩大改动，写 handoff：失败命令、完整错误日志、已改文件、当前判断，交给顶级模型纠偏。

## Iteration Protocol

每轮只做一个最小闭环：

```text
读契约 -> 选一个页面/组件 -> 实现 -> 跑门禁 -> 修复 -> 记录结果
```

迁移顺序：

1. Flutter design token 基础设施。
2. Flutter 基础组件。
3. Flutter 页面壳层。
4. 出库 / 归还 / 盘点主流程。
5. 替换 WebView 兼容桥。

禁止一次性大爆炸重构。

## Flutter Boundaries

允许：

- 在 `flutter_shell/lib/design/` 建立 token 文件。
- 在 `flutter_shell/lib/components/` 建立原生组件。
- 在 `flutter_shell/lib/pages/` 建立原生页面。
- 保留 `WebShellPage` 作为过渡兼容层。

禁止：

- 重新设计视觉风格。
- 引入与 `Design.md` 不一致的新颜色、字号、圆角、间距。
- 使用 Material 默认蓝色、随机灰色、随机阴影作为产品 UI。
- 为了 Flutter 方便而改变既有业务流程。
- 在 Widget 中散落硬编码 `Color(0x...)`、`TextStyle(fontSize: ...)`、`EdgeInsets.all(...)`、`BorderRadius.circular(...)`。
- 引入大型状态管理、UI 框架或新架构，除非用户明确要求。

## Coding Discipline

- 中文 UI 文案，英文代码标识。
- 不伪造测试、构建、lint 通过结果。
- 遇到问题先读 `踩坑记录.txt`，新问题写回。
- 每次有效变更后应本地提交。

## Key Invariants

- 出库 / 归还 / 盘点主流程不能被破坏。
- 扫码能力是核心入口，不能退化。
- 服务器配置与接口目标不能被破坏。
- API 路径和代理策略不得随意更改。
- UI 保持 375px–428px 移动端单手操作优先。
- `Design.md` token 与 Flutter token 文件必须可追踪对应。
