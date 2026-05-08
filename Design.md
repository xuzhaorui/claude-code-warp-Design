# Design System: Bumble Core Vibe (Full Protocol 3.0)

## 1. 原子层 (Foundation)

* **Brand Color:** #FFC629 (Bumble Yellow) - 仅用于品牌标识、VIP特权（Premium）强调和选中高亮。
* **Action Color (New):** #1A1A1A (Solid Black) - 用于绝大多数主操作按钮（如“了解Premium+”）、激活状态的开关（Toggle）和核心 Icon，提供极高的视觉稳定性。
* **Background Color:** #FFFFFF (Main) / #F2F2F2 (Secondary/Card background).
* **Text Color:** #222222 (Primary Title) / #757575 (Secondary/Hints/Subtitles).
* **Typography:** - Font: 现代无衬线体 (如 Inter, Gilroy 或 System Sans-serif).
* Weight: 标题使用 Bold (700)，正文使用 Medium (500)，标签或微小文字使用 Semi-Bold (600) 配合大字间距（Tracking）。


* **Corner Radius:** - Small (8px): 用于列表项、内部小图片。
* Medium (16px): 用于大尺寸的人像展示卡片。
* Large (24px - 32px): 用于主功能卡片和弹窗容器。
* Full (50% / Pill): 用于操作按钮、分段控制器（Segmented Control）。



## 2. 组件层 (Components)

### A. 底部抽屉与模态框 (Bottom Sheet / Modal)

* **Behavior:** 向上滑动弹出，背景带有 50% 透明度的深灰色遮罩。
* **Header:** 带有明确的关闭图标 (X) 或向下的滑动指示条。顶部常伴随带有暗角渐变（Dark Gradient Overlay）的 Hero Image。

### B. 选择卡片 (Selection Cards)

* **Style:** 默认背景为白色或浅灰。选中时边框变为黄色，并出现黄色圆环单选框。
* **Layout:** 横向滚动 (Horizontal Scroll)，每张卡片展示价格、数量和折扣标签。
* **Badge:** “最热门”等标签使用高对比度的反色小标签，挂载在卡片边缘。

### C. 设置与数据列表 (Lists & Cells - New)

* **Layout:** 典型的上下分层结构。黑色粗体 Title 在上，灰色常规体 Subtitle 在下，提供极佳的阅读节奏。
* **Controls:** - **Toggles (开关):** 激活状态为纯黑底色白圆点（非传统的绿色或蓝色），保持克制的工业感。
* **Chevrons:** 列表右侧使用极简的黑色线性向右箭头表示可进入。



### D. 导航与控制器 (Navigation & Segments - New)

* **Segmented Control:** 胶囊状（Pill-shaped）背景，激活项为深色/黑色药丸块，文字反白；未激活项为透明背景，文字深灰。
* **Bottom Tab Bar:** 纯白底色，线性 Icon（未激活）与 面性 Icon（激活）结合，图标下方带极小字号的文本标签。
* **Avatar:** 圆形头像外部带有进度环（Progress Ring），用于展示个人档案完善度。

### E. 媒体卡片 (Media Cards - New)

* **Discovery Cards:** 满版图片排布，底部叠加从黑色到透明的渐变遮罩（Gradient Overlay），确保其上的白色名字与年龄文字绝对清晰。

*(注：第 3、4、5 部分的动效与交互协议保持你之前确认的最佳物理参数不变)*

## 3. 动态属性 (Motion & Interaction)

* **Transition:** 使用 `Cubic-bezier(0.4, 0, 0.2, 1)` 或 `Spring(mass: 1, tension: 120, friction: 14)`。
* **Hover/Touch State:** 按钮点击时应有轻微的 0.98x 缩放反馈。
* **Loading:** 采用脉冲式 (Pulse) 骨架屏，而非旋转进度条。

## 4. 商业模式布局 (Pattern)

* **Information Hierarchy:** 顶部为利益点（如“浏览量提升10倍”），中间为选择方案，底部为明确的支付行动点按钮。

## 5. 深度交互协议 (Advanced Motion Protocol)

### A. 物理引擎参数 (Framer Motion Base)

* **Primary Spring:** 使用 `type: "spring"`。
* `stiffness: 200` (保证响应灵敏)
* `damping: 25` (消除多余抖动，增加稳重感)
* `mass: 1`


* **Tap Feedback:** 所有的可交互元素必须具备 `whileTap={{ scale: 0.96 }}`，反馈延迟需控制在 50ms 以内。

### B. 容器转换逻辑 (Transitions)

* **Bottom Sheet:** 必须支持从 `y: "100%"` 到 `y: 0` 的弹性滑入，且带有背景遮罩（Overlay）的渐变（Opacity: 0.5）。
* **Layout Animations:** 切换选中状态时，必须使用 Framer Motion 的 `layout` 属性，确保背景高亮色块是“流动”过去的，而不是闪现。

### C. 滑动与吸附 (Swipe & Snap)

* **Horizontal Draggable:** - 必须具备边缘阻尼感（`dragElastic: 0.2`）。
* 必须实现“释放后吸附”（Snap on drag end）：根据滑动速度（Velocity）和位移（Offset）自动计算并吸附到最近的卡片中心。



### D. 物理弹性与韧性 (Elasticity & Resilience)

* **Overscroll Behavior:** 所有的拖拽容器（如选项卡）必须配置 `dragElastic: 0.15`。
* 目的：模拟物理边界的“橡皮筋”效果，滑动到尽头时应允许 10% 的溢出并带有强回弹。


* **Snap Logic:** 滑动结束时必须结合速度（Velocity）计算：
* `power: 0.8`
* `timeConstant: 200`
* 确保卡片始终平滑吸附至容器中心对齐。



### E. 手势关闭协议 (Gesture Dismissal)

* **Vertical Drag:** 底部抽屉 (Bottom Sheet) 需支持 `drag="y"`。
* **关闭阈值：** 当 `y > 150px` 或 `vy > 500px/s` (向下快速挥动) 时，触发 `exit` 动画，同时背景遮罩同步淡出。
* **阻尼限制：** 向上拖拽应设置 `dragConstraints={{ top: 0 }}` 且具备高阻尼，防止抽屉被拉离底部。



### F. 视觉层级动效 (Visual Hierarchy Motion)

* **Shared Layout:** 选中状态的黄色边框必须带有 `layoutId="active-pill"`。
* 确保在不同卡片间切换时，高亮色块是“流动”过去的，而不是渐隐。


* **Elevation Transition:** 选中状态的卡片需在 0.2s 内完成阴影扩散：
* `box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1)`。


* **Staggered Entrance:** 列表项进入时延迟公式：`delay: index * 0.05s`。
