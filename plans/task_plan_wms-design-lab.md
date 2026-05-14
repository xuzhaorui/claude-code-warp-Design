# Task Plan: WMS Design Lab Enhancement

**Goal**: 在 design-system.html 中插入 4 个 WMS 专属模块（扫码实验室、反馈系统、业务列表、Dark Mode），让规格书成为仓库系统的"动态 DNA"
**Starting state**: design-system.html 已有 5 个 section（~1140 行），纯 HTML/CSS/JS 单文件
**Constraints**: 单文件自包含；纯 HTML/CSS/JS；插入 section-2 之后；零延迟 Web Audio；厚实工业风 L 型转角（4-6px 线宽）

---

## Step 1: 插入工业扫码实验室（Section 3 — 新）

**STATUS**: [x]

**ACTION**:
1. 在 `design-system.html` 的 `</section>` (section-2 结束) 之后、原 section-3 之前，插入新的 `<section id="section-scan-lab">`
2. CSS：
   - 扫码取景框：300x300px 正方形区域，背景透明/半透明黑
   - 四角黄色 L 型转角：每角由两条 40px 长、6px 宽的矩形条组成，颜色 `var(--bumble-yellow)`，圆角 2px，无渐变无阴影
   - 激光扫描线：水平线从上到下循环移动，`@keyframes scanLine` 使用 `translateY(0)` → `translateY(300px)` 循环，颜色为红色半透明（`rgba(255,60,60,0.7)`），高度 2px，带 `box-shadow` 发光效果
3. HTML：
   - 取景框容器 + 四角 L 型 div（使用 `::before` + `::after` 伪元素或绝对定位 div）
   - 激光扫描线 div（绝对定位，循环动画）
   - 旁边放一段文字说明：取景框设计原理（L 型角引导视线聚焦、激光线提供实时扫描反馈）
4. 更新侧边栏导航：在 "组件层 Components" 之后添加 "扫码实验室 Scan Lab" 链接

**GATE**:
运行 PowerShell：`(Get-Content .\design-system.html | Select-String 'section-scan-lab').Count`。Expected: 至少 `2`。
文件中包含 `@keyframes scanLine` 和 `6px`（L 型转角线宽）。

**NEXT**:
- GATE passes → proceed to Step 2
- GATE fails → 检查 section 是否正确插入在 section-2 之后，L 型 div 绝对定位是否正确

---

## Step 2: 插入反馈系统（Section 4 — 新）

**STATUS**: [x]

**ACTION**:
1. 在扫码实验室 section 之后插入 `<section id="section-feedback">`
2. CSS：
   - 毛玻璃遮罩：`backdrop-filter: blur(20px)` + `background: rgba(0,0,0,0.6)`，用于深色毛玻璃效果演示
3. HTML + JS：
   - "听觉测试" 按钮：点击时执行 Web Audio API 零延迟蜂鸣
     ```js
     // 零延迟关键：AudioContext 在页面加载时预创建，不在此函数内创建
     let audioCtx;
     window.addEventListener('load', () => { audioCtx = new (window.AudioContext || window.webkitAudioContext)(); });
     function playBeep() {
       const osc = audioCtx.createOscillator();
       const gain = audioCtx.createGain();
       osc.type = 'square'; osc.frequency.value = 800;
       gain.gain.value = 0.3;
       osc.connect(gain); gain.connect(audioCtx.destination);
       osc.start(); osc.stop(audioCtx.currentTime + 0.1);
     }
     ```
   - "视觉遮罩演示" 按钮：点击后在页面上覆盖一层毛玻璃遮罩（`position: fixed; inset: 0`），中间显示 "扫码成功" 提示文字 + 关闭按钮
4. 更新侧边栏导航

**GATE**:
运行 PowerShell：`(Get-Content .\design-system.html | Select-String 'section-feedback').Count`。Expected: 至少 `2`。
文件中包含 `AudioContext` 和 `backdrop-filter`。

**NEXT**:
- GATE passes → proceed to Step 3
- GATE fails → 如果 AudioContext 未找到，检查 JS 是否在 `<script>` 标签内。如果 backdrop-filter 未找到，检查 CSS 块

---

## Step 3: 插入业务列表规范（Section 5 — 新）

**STATUS**: [x]

**ACTION**:
1. 在反馈系统 section 之后插入 `<section id="section-business-list">`
2. CSS：
   - Status Pill：胶囊标签，不同状态对应不同颜色 — 待处理(gray)、进行中(bumble-yellow)、已完成(green)、异常(red)
   - 滑动底板：列表项可横向拖拽，左侧露出"完成"(green)操作，右侧露出"删除"(red)操作
3. HTML：
   - 5-6 条 WMS 任务列表项，每条包含：任务编号、仓库名称、Status Pill、时间戳
   - 其中至少 2 条可左右滑动演示（使用 mousedown/mousemove/mouseup 实现拖拽）
4. 更新侧边栏导航

**GATE**:
运行 PowerShell：`(Get-Content .\design-system.html | Select-String 'section-business-list').Count`。Expected: 至少 `2`。
文件中包含 Status Pill 相关的 CSS 类和至少 5 条列表项。

**NEXT**:
- GATE passes → proceed to Step 4
- GATE fails → 如果拖拽不响应，检查 touch/mouse 事件绑定和 `user-select: none`。降级：保留静态列表展示

---

## Step 4: 插入 Dark Mode 视觉对比（Section 6 — 新）

**STATUS**: [x]

**ACTION**:
1. 在业务列表 section 之后插入 `<section id="section-darkmode">`
2. 在页面顶部 sticky header 右侧添加一个 Dark Mode 切换按钮（太阳/月亮图标或文字 toggle）
3. CSS：
   - `body.dark-mode` 类切换：`--bg-main: #1A1A1A; --bg-secondary: #2A2A2A; --text-primary: #FFFFFF; --text-secondary: #AAAAAA;` 其他 token 不变
   - 侧边栏、header、section 背景跟随 dark-mode 变化
4. HTML：
   - 在 section-darkmode 中展示同一组件的 Light/Dark 并排对比
   - 说明文字：Dark Mode 下 Action Color (#1A1A1A) 如何转变为背景色，品牌色如何成为唯一视觉锚点
5. JS：
   - 切换按钮 `onclick="document.body.classList.toggle('dark-mode')"` 即可
6. 更新侧边栏导航

**GATE**:
运行 PowerShell：`(Get-Content .\design-system.html | Select-String 'section-darkmode').Count`。Expected: 至少 `2`。
文件中包含 `.dark-mode` CSS 规则和切换按钮。

**NEXT**:
- GATE passes → proceed to Step 5
- GATE fails → 检查 CSS 变量覆盖和 body class toggle 逻辑

---

## Step 5: 重新编号和导航同步

**STATUS**: [x]

**ACTION**:
1. 原有 section 编号更新：
   - 原 section-3 (动态属性) → section-7
   - 原 section-4 (商业模式) → section-8
   - 原 section-5 (深度交互) → section-9
2. 侧边栏导航最终顺序：
   - 1 原子层 Tokens → 2 组件层 Components → 3 扫码实验室 → 4 反馈系统 → 5 业务列表 → 6 Dark Mode → 7 动态属性 → 8 商业模式 → 9 深度交互协议
3. 确认 IntersectionObserver 仍然正确追踪所有 section

**GATE**:
运行 PowerShell：`(Get-Content .\design-system.html | Select-String '<section id="section-').Count`。Expected: `9`。
文件大小 > 60000 bytes。

**NEXT**:
- GATE passes → **task_plan_wms-design-lab.md complete — all 5 steps passed GATE.**
- GATE fails → 检查 section ID 是否有遗漏或重复，手动统计 section 数量
