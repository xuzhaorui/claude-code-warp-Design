# Warehouse Flutter Parity Rules

## Purpose

将现有仓库管理移动 Web APP 逐步改造为 Flutter 原生实现，
保持原 Web 版 UI/UX、业务流程、接口行为一致。

核心流程：出库 / 归还 / 盘点 / 扫码 / 服务器配置。

第一性原理：人类给方向，`Design.md` 给设计契约，现有 Web 代码给行为参考，
Flutter 编译器 / Analyzer / Linter 给真实裁判。

## Source of Truth

1. `agent_state.json` — 任务状态源；每轮先读，领取 `status=next` 的任务。
2. `Design.md` — 唯一设计物理契约，包含可 lint 的 token、组件规则、Flutter 映射。
3. `src/pages/`、`src/components/`、`src/api/` — Web 行为与接口参考（非 Flutter 约束）。
4. `flutter_shell/lib/` — Flutter 实现目标。`docs/physical-gate-runtime.md` — 门禁脚本文档。

禁止把旧 Web 技术栈、HTML 样例、截图主观观感当成 Flutter 设计契约。

## Agent State Protocol

每轮开始：读 `agent_state.json`，取 `taskQueue.status=next` 的任务，
`currentGoal` 不可等于 `lastCompletedGoal`（冲突则停止）。
每轮结束：更新 `agent_state.json` 的 `completedIterations`、`currentState`、`taskQueue`。
未更新视为本轮未完成。

## CLI Toolchain

工具链契约：`docs/flutter-scanner-migration/cli-toolchain-contract.md`。
不依赖 Android Studio。真机验证前必须按契约验证环境。Android SDK 缺失、adb 不可用、
Flutter analyze/test/build 失败是真正阻塞项。

## Physical Gate

裁判不是 CLAUDE.md。裁判是 scripts/ 中的可执行门禁：

| 命令 | 作用 |
|------|------|
| `npm run physical:gate` | 全量门禁（analyze / test / build / baseline verify / git scoped status），生成 `physical-gate.report.json` |
| `npm run physical:gate:verify` | 基线 drift 检测 |
| `npm run physical:gate:report` | Git 状态报告 |
| `npm run physical:gate:baseline` | 保存当前状态为基线 |
| `npm run physical:gate:dry` | 预览门禁命令 |

每轮结束必须运行 `npm run physical:gate`。gate fail 则先修 gate，不继续开发。
`Design.md` lint 失败先修 token。`flutter analyze` 失败先修静态问题。
禁止用主观判断代替门禁结果。

`physical-gate.config.json` 定义 `allowedDirty` 与 `scopedStatusPaths`。
`physical-gate.baseline.json` 锁定 clean state 基线。

## Failure Protocol

- 第 1 次失败：读报错，直接修。
- 第 2 次失败：收缩范围，只查相关文件、token、组件边界。
- 第 3 次失败：停止扩大改动，写 handoff（命令、错误日志、已改文件、判断），等顶级模型纠偏。

## Iteration Protocol

每轮只做一个最小闭环：读契约 → 选页面/组件 → 实现 → 跑门禁 → 修复 → 记录。
禁止一次性大爆炸重构。

迁移优先级：token 基础设施 → 基础组件 → 页面壳层 → 出库/归还/盘点主流程 → WebView 替换。

## Flutter Boundaries

允许：在 `flutter_shell/lib/design/`、`components/`、`pages/` 建立原生结构，
保留 `WebShellPage` 过渡兼容层。

禁止：重新设计视觉风格；使用 Design.md 外的颜色/字号/圆角/间距；
使用 Material 默认蓝色/随机灰色/随机阴影；为方便改变业务流程；
在 Widget 中散落硬编码 `Color(0x...)`、`TextStyle(fontSize:)`、`EdgeInsets.all()`、`BorderRadius.circular()`。

## Coding Discipline

- 中文 UI 文案，英文代码标识。
- 不伪造测试、构建、lint 通过结果。
- 遇到问题先读`踩坑记录.txt`，新问题写回。
- 每次有效变更后应本地提交。不允许 `git add .`。

## Key Invariants

- 出库 / 归还 / 盘点主流程不能被破坏。
- 扫码能力是核心入口，不能退化。
- 服务器配置与接口目标不能被破坏。
- API 路径和代理策略不得随意更改。
- UI 保持 375px–428px 移动端单手操作优先。
- `Design.md` token 与 Flutter token 文件必须可追踪对应。

## Notes

- 做任何任务都从第一性原理的角度出发
