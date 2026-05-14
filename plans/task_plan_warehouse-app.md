# Task Plan: Warehouse Management App

**Goal**: 构建一个仓库管理移动端 APP（出库/归还/盘点/设置），支持摄像头扫码、表单提交、记录列表与详情、服务器配置与登录，遵循 Design.md 规范。
**Starting state**: React + Vite + Tailwind + Framer Motion 项目骨架，feature/warehouse-app 分支已创建
**Constraints**: Design.md 规范、Mock 数据、真实摄像头扫码、后续 Capacitor 打包

---

## Step 1: 安装依赖

**STATUS**: [x]

**ACTION**:
在项目根目录执行：
```bash
npm install html5-qrcode react-router-dom lucide-react
```

**GATE**:
执行 `npm ls html5-qrcode react-router-dom lucide-react 2>&1 | head -10`，输出中应包含这三个包的版本号且无 "ERR" 或 "missing" 字样。

**NEXT**:
- GATE passes → proceed to Step 2
- GATE fails → 删除 `node_modules` 和 `package-lock.json`，重新 `npm install`，再安装这三个包。重试3次后 escalate

---

## Step 2: 创建项目目录结构

**STATUS**: [x]

**ACTION**:
在 `src/` 下创建以下目录结构：
```
src/
  components/
    Scanner/
    BottomSheet/
    Records/
    Splash/
    Forms/
    Details/
    Settings/
    Login/
    Layout/
  data/
  hooks/
  pages/
```
删除不再需要的旧文件：`src/BottomSheet.jsx`、`src/PricingCard.jsx`、`src/FeatureList.jsx`、`src/data.js`、`src/App.css`。

**GATE**:
执行 `ls src/components/Scanner src/components/Forms src/data src/hooks src/pages`，每个目录都应存在且无报错。执行 `test -f src/BottomSheet.jsx && echo EXISTS || echo GONE`，输出应为 `GONE`。

**NEXT**:
- GATE passes → proceed to Step 3
- GATE fails → 检查路径拼写，手动补全缺失目录

---

## Step 3: 编写 Mock 数据层

**STATUS**: [x]

**ACTION**:
创建 `src/data/mockData.js`，包含以下 Mock 数据和辅助函数：

1. **货物库存列表** `inventoryItems`（至少5条），每条包含：
   - `id`, `name`（货物名称）, `warehouse`（所属仓库）, `code`（编号）, `spec`（规格）, `costPrice`（成本单价）, `stockQty`（库存数量）

2. **出库记录** `checkoutRecords`（至少3条），每条包含：
   - `id`, `itemId`, `itemName`, `warehouse`, `code`, `spec`, `costPrice`, `quantity`, `method`（"外销"/"外借"）, `saleTotalPrice`, `saleUnitPrice`, `remark`, `operatorId`, `operatorName`, `time`, `status`（"正常"/"已撤销"）

3. **外借记录** `borrowRecords`（至少3条），每条包含：
   - `id`, `itemId`, `itemName`, `warehouse`, `code`, `spec`, `costPrice`, `borrowQty`（在借数量）, `borrower`（外借人）, `borrowTime`, `operatorId`

4. **归还记录** `returnRecords`（至少3条），每条包含：
   - `id`, `borrowRecordId`, `itemId`, `itemName`, `warehouse`, `code`, `spec`, `costPrice`, `returnQty`, `borrower`, `operatorId`, `operatorName`, `time`, `remark`

5. **盘点记录** `inventoryCheckRecords`（至少3条），每条包含：
   - `id`, `itemId`, `itemName`, `warehouse`, `code`, `spec`, `bookQty`（账面数量）, `actualQty`（盘点数量）, `difference`（差值）, `remark`, `operatorId`, `operatorName`, `time`

6. **用户列表** `mockUsers`（2条），包含 `id`, `username`, `password`

7. **辅助函数**（均返回 Promise 模拟异步）：
   - `getItemByCode(code)` — 根据编号查库存
   - `getCheckoutRecords()` — 获取出库记录
   - `submitCheckout(record)` — 提交出库（推入 checkoutRecords）
   - `getBorrowersByItem(itemId)` — 查某货物的外借人列表
   - `submitReturn(record)` — 提交归还
   - `getReturnRecords()` — 获取归还记录
   - `submitInventoryCheck(record)` — 提交盘点
   - `getInventoryCheckRecords()` — 获取盘点记录
   - `mockLogin(username, password)` — 模拟登录，返回 user 对象或 null

**GATE**:
在 Node 环境中执行（临时测试脚本）：
```bash
node -e "const m = require('./src/data/mockData.js'); console.log(typeof m.mockLogin)"
```
若 ESM 报错，则改为：读取文件内容确认所有上述函数和数组都已定义，且无语法错误（`node --check src/data/mockData.js` 不报错，或者用 `node -e "import('./src/data/mockData.js').then(m=>console.log(Object.keys(m)))"` 成功打印所有导出名）。

**NEXT**:
- GATE passes → proceed to Step 4
- GATE fails → 检查 ES Module 语法（确保有 `export`），修复语法错误

---

## Step 4: 编写全局样式和 Tailwind 配置

**STATUS**: [x]

**ACTION**:
1. 重写 `src/index.css`，引入 Tailwind 并添加 Design.md 规范的自定义样式：
   - CSS 变量：`--brand-yellow: #FFC629`, `--action-black: #1A1A1A`, `--bg-main: #FFFFFF`, `--bg-secondary: #F2F2F2`, `--text-primary: #222222`, `--text-secondary: #757575`
   - 全局字体设置（Inter 或 system sans-serif）
   - 隐藏滚动条样式（移动端）
   - 输入框聚焦样式
   - 脉冲动画 keyframes（`pulse-scale`：从 scale(1) 到 scale(1.15) 循环）

2. 更新 `index.html` 的 `<head>` 添加 viewport meta 和字体：
   ```html
   <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
   <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet" />
   ```

**GATE**:
执行 `grep -c "pulse-scale" src/index.css`，输出 ≥ 1。执行 `grep -c "viewport" index.html`，输出 ≥ 1。

**NEXT**:
- GATE passes → proceed to Step 5
- GATE fails → 检查文件写入是否成功，补全缺失内容

---

## Step 5: 编写共享组件 — BottomSheet

**STATUS**: [x]

**ACTION**:
创建 `src/components/BottomSheet/FormSheet.jsx`：
- 使用 Framer Motion 的 `AnimatePresence` + `motion.div` 实现从底部滑入的底部抽屉
- Props: `isOpen`, `onClose`, `title`, `children`
- 顶部：拖拽指示条 + 标题 + 关闭 X 按钮
- 背景遮罩：50% 透明黑色，点击关闭
- 支持 `drag="y"` 手势关闭（y > 150px 或 vy > 500px/s 触发关闭）
- 弹簧参数：`stiffness: 200, damping: 25, mass: 1`
- 样式遵循 Design.md：Large corner radius (24-32px)，纯白背景

创建 `src/components/BottomSheet/DetailSheet.jsx`：
- 结构与 FormSheet 类似，但内容为只读详情展示
- Props: `isOpen`, `onClose`, `title`, `children`

**GATE**:
文件存在且无语法错误。执行 `node -e "import('./src/components/BottomSheet/FormSheet.jsx').catch(()=>console.log('jsx-ok'))"` 或者简单地用 grep 确认文件包含 `motion.div`, `AnimatePresence`, `drag="y"` 关键字。同理检查 DetailSheet。

**NEXT**:
- GATE passes → proceed to Step 6
- GATE fails → 检查 Framer Motion import 路径，修复 JSX 语法

---

## Step 6: 编写共享组件 — ScannerOverlay

**STATUS**: [x]

**ACTION**:
创建 `src/components/Scanner/ScannerOverlay.jsx`：
- 使用 `html5-qrcode` 库的 `Html5QrcodeScanner` 或 `Html5Qrcode` 实现
- Props: `isOpen`, `onClose`, `onScanSuccess(result)`
- 全屏覆盖，黑色背景，中间显示摄像头画面
- 扫描框动画：四角有扫描线动画（绿色/黄色线条）
- 扫描成功后自动关闭并回调 `onScanSuccess`
- 支持手动关闭（X 按钮）

创建 `src/hooks/useScanner.js`：
- 自定义 Hook，封装 `Html5Qrcode` 的初始化和清理逻辑
- 返回 `{ startScan, stopScan, isScanning, error }`

**GATE**:
文件存在且包含 `Html5Qrcode` import。grep `Html5Qrcode src/components/Scanner/ScannerOverlay.jsx` 有输出。

**NEXT**:
- GATE passes → proceed to Step 7
- GATE fails → 确认 html5-qrcode 已安装（Step 1），检查 import 路径

---

## Step 7: 编写共享组件 — RecordCard

**STATUS**: [x]

**ACTION**:
创建 `src/components/Records/RecordCard.jsx`：
- Props: `icon`, `badge`, `title`, `subtitle`, `extra`, `onClick`
- 左侧：图标（Lucide icon 组件），右上角红色/黄色小圆角 badge 显示数字
- 右侧：标题行（粗体）+ 副标题行（灰色）+ 附加信息行
- 右侧箭头 chevron
- 点击效果：`whileTap={{ scale: 0.96 }}`
- 列表项之间有 1px 分割线
- 白色背景，8px corner radius
- Staggered entrance animation：`delay: index * 0.05s`

**GATE**:
文件存在且包含 `whileTap`, `motion.div`, `onClick` 关键字。

**NEXT**:
- GATE passes → proceed to Step 8
- GATE fails → 修复组件语法

---

## Step 8: 编写 Splash 加载动画

**STATUS**: [x]

**ACTION**:
创建 `src/components/Splash/SplashScreen.jsx`：
- 全屏黄色背景（#FFC629），白色图标居中
- 图标使用一个仓库/箱子图标（Lucide `Package` icon）
- 动画：图标从 `scale(0.8)` 脉冲到 `scale(1.15)`，循环播放，使用 Design.md 的弹簧参数
- 2-3秒后自动淡出，回调 `onFinish`
- 使用 Framer Motion 的 `animate` 循环 + `AnimatePresence` 淡出
- 脉冲节奏感：像心跳一样有膨胀感（先快后慢）

创建 `src/components/Splash/index.js` 导出。

**GATE**:
文件存在且包含 `Package`（lucide icon）、`scale`（动画）、`onFinish` 关键字。

**NEXT**:
- GATE passes → proceed to Step 9
- GATE fails → 检查 Lucide 图标名称和 Framer Motion 语法

---

## Step 9: 编写登录页面

**STATUS**: [x]

**ACTION**:
创建 `src/components/Login/LoginPage.jsx`：
- 居中的白色卡片，大圆角 (24px)
- 标题："登录"（Bold 700）
- 两个输入框：用户名、密码（password 类型）
- 输入框样式：浅灰背景 (#F2F2F2)，16px 圆角，无传统边框
- 主操作按钮：黑色背景 (#1A1A1A)，白色文字，Pill 形状（50% radius）
- 按钮点击效果：`whileTap={{ scale: 0.96 }}`
- 调用 `mockLogin(username, password)`
- 登录成功 → 存 `localStorage` (`currentUser`) → 跳转主页面
- 登录失败 → 输入框下方显示红色提示文字
- 底部小字提示："任意账号密码均可登录"

**GATE**:
文件存在且包含 `mockLogin`, `localStorage`, `whileTap` 关键字。

**NEXT**:
- GATE passes → proceed to Step 10
- GATE fails → 修复组件逻辑

---

## Step 10: 编写设置页面（服务器配置 + 登出）

**STATUS**: [x]

**ACTION**:
创建 `src/components/Settings/ServerConfig.jsx`：
- 服务器列表（从 `localStorage` 读取 key `servers`）
- 每条服务器显示：名称、IP地址、右侧 chevron
- 当前激活服务器左侧有黑色圆点标记
- 点击切换激活服务器（存入 `localStorage` key `activeServer`）
- 支持左滑删除（或点击后弹出编辑/删除选项）
- 底部 "添加服务器" 按钮（Pill 形状，黑色）
- 添加/编辑弹出一个 BottomSheet 表单：服务器名称输入框 + IP地址输入框
- 删除需要二次确认（简单的确认弹窗）

创建 `src/components/Settings/SettingsTab.jsx`：
- 顶部标题 "设置"（Bold）
- "服务器配置" 列表项，右侧 chevron，点击进入 ServerConfig
- "退出登录" 按钮（红色文字，点击后清除 localStorage 中的 currentUser，跳转到登录页）
- 所有列表项遵循 Design.md 的 Lists & Cells 样式：黑色粗体 Title + 灰色 Subtitle

**GATE**:
两个文件均存在。SettingsTab 包含 `localStorage`, `退出登录`。ServerConfig 包含 `servers`, `activeServer`。

**NEXT**:
- GATE passes → proceed to Step 11
- GATE fails → 检查文件内容和 localStorage key 名称一致性

---

## Step 11: 编写出库 Tab（扫描 + 表单 + 记录列表）

**STATUS**: [x]

**ACTION**:
创建 `src/components/Forms/CheckoutForm.jsx`：
- Props: `item`（扫码查到的库存对象）, `onSubmit(data)`, `onClose`
- 显示字段（只读）：货物名称、所属仓库、编号、规格、库存数量、成本单价
- 输入字段：
  - 出库数量（数字输入）
  - 出库方式：Segmented Control（外销/外借，默认外销），胶囊状 Pill 样式
  - 外销时显示：销售总价输入框，自动计算并显示销售单价（销售总价÷出库数量）
  - 外借时只显示：出库数量
  - 出库备注（可选）
- 校验逻辑：
  - 出库数量 > 库存数量 → 输入框下方红色提示 "出库数量超过库存数量"
  - 销售单价 < 成本单价 → 提示 "销售单价低于成本单价，存在亏损风险"，带"确认继续"按钮
- 提交按钮：黑色 Pill，`whileTap={{ scale: 0.96 }}`

创建 `src/pages/CheckoutTab.jsx`：
- 上方 30-40% 区域：扫码提示卡片
  - 中央大图标（Lucide `ScanLine`）+ 文字 "点击扫码出库"
  - 点击打开 ScannerOverlay
  - 扫码成功后，用 `getItemByCode(code)` 查库存，弹出 FormSheet 包裹 CheckoutForm
  - 提交成功 → 关闭 FormSheet → 刷新记录列表
- 下方 60-70% 区域：出库记录列表
  - 标题："出库记录"
  - 使用 RecordCard 组件渲染 `getCheckoutRecords()` 的结果
  - icon 使用 `LogOut`（Lucide），badge 显示出库数量
  - 标题行：仓库 + 出库时间
  - 副标题行：货物名称
  - 附加行：总价
  - 超出页面时启用滚动
  - 点击记录 → 弹出 DetailSheet 显示出库详情

创建 `src/components/Details/CheckoutDetail.jsx`：
- Props: `record`
- 显示：状态（正常/已撤销，用绿色/红色 badge）、货物名称、仓库、编号、规格、出库数量、出库方式、成本单价、销售总价、出库时间

**GATE**:
三个文件均存在。CheckoutForm 包含 `外销`, `外借`, `库存数量`, `成本单价` 关键字。CheckoutTab 包含 `ScanLine`, `getItemByCode`。CheckoutDetail 包含 `已撤销`。

**NEXT**:
- GATE passes → proceed to Step 12
- GATE fails → 检查组件 props 传递和 Mock 数据函数名一致性

---

## Step 12: 编写归还 Tab（扫描 + 外借人选择 + 表单 + 记录列表）

**STATUS**: [x]

**ACTION**:
创建 `src/components/Forms/ReturnForm.jsx`：
- Props: `borrowRecord`（选中的外借记录）, `onSubmit(data)`, `onClose`
- 显示字段（只读）：货物名称、外借人、仓库名称、在借数量、成本单价
- 输入字段：
  - 归还数量（数字输入）
  - 归还备注（可选）
- 校验：归还数量 > 在借数量 → 红色提示
- 提交按钮：黑色 Pill

创建 `src/components/Forms/BorrowerSelect.jsx`：
- Props: `borrowers`（外借人列表）, `onSelect(borrower)`
- 列表展示所有外借人：货物名称、外借人、仓库、借出数量、时间
- 点击选中一条，高亮黄色边框，回调 onSelect

创建 `src/pages/ReturnTab.jsx`：
- 上方扫码区域（同出库结构，文字改为 "点击扫码归还"）
- 扫码成功后流程：
  1. 用 `getItemByCode(code)` 查到 itemId
  2. 调用 `getBorrowersByItem(itemId)` 获取外借人列表
  3. 弹出 FormSheet 包裹 BorrowerSelect
  4. 用户选中外借人后，切换显示 ReturnForm
  5. 提交成功 → 关闭 → 刷新
- 下方：归还记录列表
  - icon 使用 `RotateCcw`（Lucide），badge 显示归还数量
  - 标题行：仓库 + 归还时间
  - 副标题行：货物名称
  - 附加行：外借人
  - 点击 → DetailSheet 显示归还详情

创建 `src/components/Details/ReturnDetail.jsx`：
- Props: `record`
- 显示：货物名称、仓库名称、编号、规格、归还数量、外借人、操作人、归还时间、归还备注

**GATE**:
四个文件均存在。BorrowerSelect 包含 `onSelect`。ReturnTab 包含 `getBorrowersByItem`, `RotateCcw`。ReturnDetail 包含 `外借人`, `操作人`。

**NEXT**:
- GATE passes → proceed to Step 13
- GATE fails → 检查 Mock 函数名和组件嵌套关系

---

## Step 13: 编写盘点 Tab（扫描 + 表单 + 记录列表）

**STATUS**: [x]

**ACTION**:
创建 `src/components/Forms/InventoryCheckForm.jsx`：
- Props: `item`（库存对象）, `onSubmit(data)`, `onClose`
- 显示字段（只读）：货物名称、仓库编号、规格、账面数量
- 输入字段：
  - 盘点真实数量（数字输入）
  - 自动计算显示差值（账面数量 - 盘点真实数量，正数绿色，负数红色）
  - 盘点备注（可选）
- 提交按钮：黑色 Pill

创建 `src/pages/InventoryTab.jsx`：
- 上方扫码区域（文字 "点击扫码盘点"）
- 扫码成功 → 查库存 → 弹出 FormSheet 包裹 InventoryCheckForm → 提交 → 关闭 → 刷新
- 下方：盘点记录列表
  - icon 使用 `ClipboardCheck`（Lucide），badge 显示差值（带 +/- 号）
  - 标题行：仓库名称 + 盘点时间
  - 副标题行：货物名称
  - 附加行：盘点数量
  - 点击 → DetailSheet

创建 `src/components/Details/InventoryCheckDetail.jsx`：
- Props: `record`
- 显示：货物名称、仓库名称、编号、规格、账面库存、盘点数量、差值（颜色区分）、盘点时间

**GATE**:
三个文件均存在。InventoryCheckForm 包含 `账面数量`, `差值`。InventoryTab 包含 `ClipboardCheck`。InventoryCheckDetail 包含 `账面库存`。

**NEXT**:
- GATE passes → proceed to Step 14
- GATE fails → 检查差值计算逻辑和 Mock 数据字段名

---

## Step 14: 编写 App Shell（底部导航 + 路由 + 认证流程）

**STATUS**: [x]

**ACTION**:
重写 `src/App.jsx`：
- 使用 React Router (`BrowserRouter`, `Routes`, `Route`)
- 页面结构：
  ```
  /splash  → SplashScreen（首次加载动画）
  /login   → LoginPage
  /        → AppShell（需要登录态守卫）
  ```
- 认证守卫：检查 `localStorage.getItem('currentUser')`，未登录 → 跳转 `/login`

创建 `src/pages/AppShell.jsx`：
- 顶部状态栏区域（padding-top 安全区）
- 中间内容区：使用 React Router 的嵌套路由，根据当前 Tab 渲染对应页面
- 底部 Tab Bar：
  - 4个 Tab：出库（`LogOut` icon）、归还（`RotateCcw` icon）、盘点（`ClipboardCheck` icon）、设置（`Settings` icon）
  - 纯白底色
  - 未激活：线性 icon（stroke）+ 灰色文字
  - 激活：面性 icon（fill）+ 黑色文字 + 下方有黄色小圆点指示器
  - 图标下方极小字号文本标签
  - 点击切换 Tab（不使用路由，用 state 控制当前 Tab index）

- 启动流程：
  1. App 挂载时显示 SplashScreen
  2. Splash 动画结束后检查是否有服务器配置
  3. 无服务器配置 → 跳转设置页（提示先配置服务器）
  4. 有服务器配置但未登录 → 跳转登录页
  5. 已登录 → 进入主页面

重写 `src/main.jsx`：
- 保持 React 18 createRoot 入口
- 引入 `BrowserRouter` 包裹 `App`

**GATE**:
`npm run build` 不报错（exit code 0）。`src/App.jsx` 包含 `BrowserRouter`, `Routes`, `Route`。`src/pages/AppShell.jsx` 包含 `LogOut`, `RotateCcw`, `ClipboardCheck`, `Settings`。

**NEXT**:
- GATE passes → proceed to Step 15
- GATE fails → 运行 `npm run build 2>&1 | tail -30` 查看具体编译错误，根据错误信息修复 import 路径或语法

---

## Step 15: 清理旧代码 + 集成验证

**STATUS**: [x]

**ACTION**:
1. 确认以下旧文件已删除：`src/App.css`, `src/BottomSheet.jsx`, `src/PricingCard.jsx`, `src/FeatureList.jsx`, `src/data.js`
2. 清理 `index.html` 中不需要的旧内容
3. 运行 `npm run build` 确认无编译错误
4. 运行 `npm run dev` 启动开发服务器
5. 在浏览器中验证以下流程：
   - 看到 Splash 脉冲动画 → 自动消失
   - 首次进入提示配置服务器 → 进入设置添加服务器
   - 跳转登录页 → 输入任意账号密码 → 登录成功
   - 进入主页看到 4 个底部 Tab
   - 切换到出库 Tab → 点击扫码 → 摄像头打开（如无摄像头则显示错误提示）
   - 各 Tab 记录列表正常显示
   - 点击记录弹出详情 BottomSheet
   - 设置页服务器列表 CRUD 正常
   - 退出登录回到登录页

**GATE**:
- `npm run build` exit code 0
- `npm run dev` 启动成功，控制台无报错
- 浏览器访问 `http://localhost:5173` 能看到 Splash 动画并进入正常流程
- 底部 4 个 Tab 切换正常

**NEXT**:
- GATE passes → 全部完成，执行 Step 16 提交
- GATE fails → 根据具体错误修复：编译错误修 import/语法，运行时错误查控制台 stack trace 定位组件

---

## Step 16: 提交代码

**STATUS**: [x]

**ACTION**:
```bash
git add src/ index.html
git commit -m "feat: warehouse management app with scan, forms, records, settings"
```

**GATE**:
`git log --oneline -1` 显示新的 commit 且 message 包含 "warehouse management app"。

**NEXT**:
- GATE passes → 计划完成
- GATE fails → 检查是否有文件被 `.gitignore` 排除，用 `git status` 确认暂存区
