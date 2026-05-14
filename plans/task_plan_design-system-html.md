# Task Plan: Design System HTML

**Goal**: 生成 `design-system.html`，将 Design.md 全部 5 章从纯文字转化为可视化+可交互的设计系统页面
**Starting state**: Design.md 已存在于 `D:\claude-code-warp\Design\`，包含原子层/组件层/动态属性/商业模式/深度交互协议
**Constraints**: 单文件自包含 HTML；纯 HTML/CSS/JS 零依赖；双击即开；降级不阻塞

---

## Step 1: 创建 HTML 骨架与导航结构

**STATUS**: [x]

**ACTION**:
1. 在 `D:\claude-code-warp\Design\` 创建 `design-system.html`
2. 写入基础骨架：`<!DOCTYPE html>` + `<html lang="zh-CN">` + `<head>` 包含 meta charset utf-8、viewport、`<title>Bumble Design System</title>`
3. 在 `<style>` 中定义 CSS 变量（从 Design.md 提取）：`--bumble-yellow: #FFC629; --action-black: #1A1A1A; --bg-main: #FFFFFF; --bg-secondary: #F2F2F2; --text-primary: #222222; --text-secondary: #757575;`
4. 创建侧边栏导航（左侧固定），包含 5 个 section 锚点链接：
   - 1. 原子层 Tokens
   - 2. 组件层 Components
   - 3. 动态属性 Motion
   - 4. 商业模式 Pattern
   - 5. 深度交互协议 Advanced
5. 创建右侧主内容区 `<main>`，每个 section 用 `<section id="section-N">` 包裹
6. 页面顶部放一个 sticky header 显示 "Bumble Core Vibe — Design System 3.0"

**GATE**:
用浏览器打开 `design-system.html`，侧边栏导航可见且 5 个链接可点击滚动到对应 section。或者：文件存在且包含 `<nav>` 和 5 个 `<section id="section-`，且 CSS 变量已定义。
运行 PowerShell：`Select-String -Path .\design-system.html -Pattern "section-" | Measure-Object | Select-Object -ExpandProperty Count`。Expected: `5` 或以上。

**NEXT**:
- GATE passes → proceed to Step 2
- GATE fails → 检查文件是否完整写入，确认 `<section>` 标签闭合正确，重新执行 ACTION

---

## Step 2: 原子层 Token 可视化（Section 1）

**STATUS**: [x]

**ACTION**:
在 `<section id="section-1">` 中写入以下可视化内容：

1. **颜色色板**：用 `<div>` 网格展示每个品牌色（Bumble Yellow、Action Black、Background Main/Secondary、Text Primary/Secondary），每个色块内显示色值 HEX + 色块名称，文字颜色自动根据背景亮度切换黑/白
2. **字体排版**：展示三级字重效果 — Bold(700) 标题、Medium(500) 正文、Semi-Bold(600) 标签，配合实际文字示例（如 "Bumble Design System"、"探索附近的人"）
3. **圆角展示**：4 个并排方块（背景 `var(--bg-secondary)`），分别应用 8px / 16px / 24px / 50%(pill) 圆角，每个下方标注 px 值和用途说明
4. **阴影层级**：展示 3 级 elevation（sm/md/lg），对应 `0 2px 8px`, `0 8px 24px`, `0 20px 25px -5px rgba(0,0,0,0.1)`，每个阴影应用到白色卡片上

**GATE**:
文件中 `section-1` 区域包含颜色色板（含 `#FFC629`）、圆角展示（含 `border-radius`）、字重展示（含 `font-weight: 700`）。
运行 PowerShell：`Select-String -Path .\design-system.html -Pattern "FFC629" | Measure-Object | Select-Object -ExpandProperty Count`。Expected: 至少 `2`。

**NEXT**:
- GATE passes → proceed to Step 3
- GATE fails → 检查 CSS 变量和色板 div 是否正确写入，修复后重新验证

---

## Step 3: 组件层交互式原型（Section 2）

**STATUS**: [x]

**ACTION**:
在 `<section id="section-2">` 中写入以下组件原型：

1. **Bottom Sheet 模态框**：一个按钮 "打开底部抽屉"，点击后从底部滑入一个面板，背景出现 50% 透明遮罩，面板顶部有拖拽条和关闭 X 按钮，点击遮罩或 X 可关闭。使用 CSS `transform: translateY` + `transition` 实现
2. **Selection Cards 选择卡片**：3-4 张横向排列的卡片，点击选中时边框变黄 + 出现黄色圆环单选框，未选中为白色边框。用 JS `onclick` 切换 `data-selected` 属性。其中一张带 "最热门" badge
3. **Settings List 设置列表**：3-4 行列表项，每行左侧黑体标题+灰色副标题，右侧放 Toggle 开关（激活态为黑底白圆点）或右箭头 chevron
4. **Segmented Control 分段控制器**：3 段胶囊控制器，激活项为黑色药丸背景白色文字，点击切换时药丸背景平滑滑动（CSS transition `left`）
5. **Bottom Tab Bar**：模拟底部导航栏，5 个 tab（线性 Icon + 文字标签），激活项为面性 Icon，用纯 CSS/Unicode 符号代替 icon
6. **Discovery Card 媒体卡片**：一张满版图片卡片（用 `picsum.photos` 占位图），底部叠加黑到透明渐变遮罩，白色名字+年龄文字覆盖

**GATE**:
文件中 `section-2` 包含至少 5 个可交互组件。Bottom Sheet 可点击打开/关闭，Segmented Control 可切换。
运行 PowerShell：`Select-String -Path .\design-system.html -Pattern "section-2" | Measure-Object | Select-Object -ExpandProperty Count`。Expected: 至少 `2`（开始标签 + ID 引用）。
手动验证：在浏览器中点击 "打开底部抽屉" 按钮，面板应从底部滑入；点击 Segmented Control 不同段，药丸应平滑移动。

**NEXT**:
- GATE passes → proceed to Step 4
- GATE fails → 如果某组件 JS 事件未绑定，检查 `onclick` / `addEventListener` 是否在 DOM 加载后执行，包裹在 `DOMContentLoaded` 中。如果动画不平滑，检查 CSS transition 属性。降级：失败的组件保留静态展示 + 文字说明

---

## Step 4: 动态属性演示（Section 3）

**STATUS**: [x]

**ACTION**:
在 `<section id="section-3">` 中写入：

1. **按钮点击反馈演示**：3 个按钮（Primary 黑底白字、Secondary 白底黑边、Yellow 强调），点击时触发 `scale(0.98)` 缩放动画，用 CSS `:active` 实现
2. **骨架屏 Loading 演示**：展示一个卡片骨架屏，使用 CSS `@keyframes pulse` 实现从 `rgba(0,0,0,0.04)` 到 `rgba(0,0,0,0.12)` 的脉冲闪烁
3. **过渡曲线可视化**：用 `<canvas>` 绘制 `cubic-bezier(0.4, 0, 0.2, 1)` 的贝塞尔曲线，旁边放一个动画球沿该曲线运动，展示 easing 效果
4. **Spring 参数展示**：显示 `stiffness: 200 / damping: 25 / mass: 1` 的当前默认值，作为 Step 5 playground 的预览

**GATE**:
`section-3` 包含按钮点击缩放效果（CSS `transform: scale(0.98)`）、骨架屏脉冲动画（`@keyframes pulse`）、贝塞尔曲线 canvas。
运行 PowerShell：`Select-String -Path .\design-system.html -Pattern "scale\(0.98\)" | Measure-Object | Select-Object -ExpandProperty Count`。Expected: 至少 `1`。

**NEXT**:
- GATE passes → proceed to Step 5
- GATE fails → 检查 CSS keyframes 和 canvas 绑定。Canvas 部分若失败可降级为静态 SVG 曲线图

---

## Step 5: 深度交互协议 Playground（Section 5 + Section 3 扩展）

**STATUS**: [x]

**ACTION**:
在 `<section id="section-5">` 中写入动效调参 Playground：

1. **Spring Playground**：
   - 3 个 `<input type="range">` 滑块：stiffness(50-500, 默认200)、damping(5-50, 默认25)、mass(0.5-3, 默认1)
   - 右侧一个演示方块（或卡片），点击 "播放" 按钮后用 JS `requestAnimationFrame` + 简化弹簧物理公式 `x(t) = A * e^(-ζωt) * cos(ωd*t)` 模拟弹簧动画
   - 方块从偏移位置弹回原位，实时反映滑块参数
   - 底部一个 "复制参数" 按钮，点击后将当前参数格式化为 `stiffness: X, damping: Y, mass: Z` 写入剪贴板

2. **手势模拟区**：
   - 一个可拖拽的 Bottom Sheet 卡片，支持 `mousedown/mousemove/mouseup` + `touchstart/touchmove/touchend`
   - 拖拽超过 150px 或速度超过阈值时触发关闭动画
   - 旁边显示实时拖拽位移 `y` 值和速度 `vy` 值

3. **滑动吸附演示**：
   - 3-4 张可横向拖拽的卡片（用 `overflow: hidden` 容器）
   - 释放时根据速度和位移自动吸附到最近的卡片中心
   - 演示 `dragElastic: 0.2` 的橡皮筋效果

**GATE**:
Playground 区域包含 3 个 range 滑块、1 个可拖拽 Bottom Sheet、1 个横向滑动吸附卡片组。
运行 PowerShell：`Select-String -Path .\design-system.html -Pattern 'type="range"' | Measure-Object | Select-Object -ExpandProperty Count`。Expected: 至少 `3`。
手动验证：拖动 stiffness 滑块到最大值，点击播放，方块弹跳频率应变快；拖动 Bottom Sheet 超过 150px 释放，面板应关闭。

**NEXT**:
- GATE passes → proceed to Step 6
- GATE fails → 如果弹簧物理模拟不准确，先用简单的 `CSS spring-like keyframes` 降级，保留滑块交互。如果拖拽事件不响应，检查是否同时绑定了 mouse 和 touch 事件，并阻止了默认滚动行为。降级：失败的交互保留文字说明占位

---

## Step 6: 商业模式布局 Pattern（Section 4）

**STATUS**: [x]

**ACTION**:
在 `<section id="section-4">` 中写入商业模式卡片布局：

1. **Premium Upsell 卡片**：模拟 Design.md 描述的信息层级 — 顶部大标题利益点（"浏览量提升10倍"），中间放 3 张选择方案卡片（Basic/Premium/Premium+），底部放一个黄色/黑色主操作按钮
2. **信息层级标注**：在卡片旁用虚线标注 + 文字说明 "顶部：利益点 → 中间：方案选择 → 底部：行动点"，让读者理解布局逻辑
3. **响应式演示**：卡片在不同宽度下的自适应表现（可用一个容器宽度滑块来演示）

**GATE**:
`section-4` 包含至少 1 张完整的 upsell 卡片，包含标题、方案选择、操作按钮三层结构。
运行 PowerShell：`Select-String -Path .\design-system.html -Pattern "section-4" | Measure-Object | Select-Object -ExpandProperty Count`。Expected: 至少 `2`。

**NEXT**:
- GATE passes → proceed to Step 7
- GATE fails → 检查 HTML 结构完整性，确保卡片嵌套层级正确。降级：简化为静态卡片截图式展示

---

## Step 7: 整体样式润色与导航联动

**STATUS**: [x]

**ACTION**:
1. 添加侧边栏高亮联动：监听 `IntersectionObserver`，当某个 section 进入视口时，对应的侧边栏导航项添加 `active` 类（加粗+左侧黄色竖条）
2. 添加全局平滑滚动：`html { scroll-behavior: smooth; }`
3. 确保 section 之间有足够的 padding/margin，避免内容拥挤
4. 在页面底部添加一行小字："Based on Design.md — Bumble Core Vibe Design System 3.0"
5. 检查所有交互组件是否正常工作：Bottom Sheet 开关、Segmented Control 切换、Playground 滑块、复制参数按钮、拖拽手势

**GATE**:
完整打开 `design-system.html`，侧边栏导航随滚动高亮变化，点击导航项平滑滚动到对应 section，所有 5 个 section 有可见内容。
运行 PowerShell：`(Get-Item .\design-system.html).Length`。Expected: 大于 `15000` 字节（约 15KB，确保内容充实）。

**NEXT**:
- GATE passes → **task_plan_design-system-html.md complete — all 7 steps passed GATE.**
- GATE fails → 如果文件太小，说明某 section 内容缺失，检查对应 step 的 ACTION 是否完整执行。如果是交互问题，检查 JS console 错误信息。降级：有问题的 section 保留已完部分，标注为"待完善"
