# Task Plan: Swipe Actions for Record List Items

**Goal**: 重构 RecordCard 为工业级可滑动组件（右滑确认/左滑异常），含 haptic 反馈、AnimatePresence 退出动画、layout 重排、点击/拖拽手势分离。
**Starting state**: RecordCard.jsx 是纯 motion.button 组件，三个 Tab 页面直接 map 渲染，无滑动/退出动画。
**Constraints**: Design.md 物理参数（stiffness:200, damping:25, mass:1, dragElastic:0.15）、framer-motion、无新依赖。

---

## Step 1: 重写 RecordCard 为 SwipeableRecordCard

**STATUS**: [x]

**ACTION**:
将 `src/components/Records/RecordCard.jsx` 完整重写为以下内容：

```jsx
import { useState, useRef, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronRight, Check, X } from 'lucide-react';

const SWIPE_THRESHOLD = 100;
const CLICK_THRESHOLD = 5;
const SPRING = { type: 'spring', stiffness: 200, damping: 25, mass: 1 };

export default function RecordCard({ icon: Icon, badge, title, subtitle, extra, onClick, onSwipeLeft, onSwipeRight, index = 0 }) {
  const [dismissed, setDismissed] = useState(false);
  const startX = useRef(0);
  const startY = useRef(0);
  const isDragging = useRef(false);
  const hasTriggeredHaptic = useRef({ left: false, right: false });
  const dragX = useRef(0);

  const handleDrag = useCallback((_, info) => {
    dragX.current = info.offset.x;
    const abs = Math.abs(info.offset.x);

    if (info.offset.x > SWIPE_THRESHOLD && !hasTriggeredHaptic.current.right) {
      hasTriggeredHaptic.current.right = true;
      hasTriggeredHaptic.current.left = false;
      try { navigator.vibrate?.([50]); } catch {}
    } else if (info.offset.x < -SWIPE_THRESHOLD && !hasTriggeredHaptic.current.left) {
      hasTriggeredHaptic.current.left = true;
      hasTriggeredHaptic.current.right = false;
      try { navigator.vibrate?.([50]); } catch {}
    } else if (abs < SWIPE_THRESHOLD) {
      hasTriggeredHaptic.current.left = false;
      hasTriggeredHaptic.current.right = false;
    }
  }, []);

  const handleDragEnd = useCallback((_, info) => {
    if (info.offset.x > SWIPE_THRESHOLD || info.velocity.x > 500) {
      setDismissed('right');
    } else if (info.offset.x < -SWIPE_THRESHOLD || info.velocity.x < -500) {
      setDismissed('left');
    }
    hasTriggeredHaptic.current = { left: false, right: false };
  }, []);

  const handleDragStart = useCallback(() => {
    hasTriggeredHaptic.current = { left: false, right: false };
    isDragging.current = false;
  }, []);

  const handlePointerDown = useCallback((e) => {
    startX.current = e.clientX;
    startY.current = e.clientY;
  }, []);

  const handleClick = useCallback((e) => {
    if (isDragging.current) {
      e.preventDefault();
      e.stopPropagation();
      return;
    }
    onClick?.();
  }, [onClick]);

  const handleDragDirectionLock = useCallback((e, info) => {
    const dx = Math.abs(info.offset.x);
    const dy = Math.abs(info.offset.y);
    if (dx > CLICK_THRESHOLD || dy > CLICK_THRESHOLD) {
      isDragging.current = true;
    }
  }, []);

  const onDismissComplete = useCallback(() => {
    if (dismissed === 'right') onSwipeRight?.();
    if (dismissed === 'left') onSwipeLeft?.();
    setDismissed(false);
  }, [dismissed, onSwipeLeft, onSwipeRight]);

  const exitX = dismissed === 'right' ? '100%' : dismissed === 'left' ? '-100%' : 0;

  return (
    <AnimatePresence onExitComplete={onDismissComplete}>
      {!dismissed && (
        <motion.div
          layout
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ x: exitX, opacity: 0, transition: { duration: 0.25 } }}
          transition={{ delay: index * 0.05, duration: 0.25 }}
          className="relative overflow-hidden border-b border-gray-100"
        >
          {/* Right swipe underlay (confirm) */}
          <div className="absolute inset-0 bg-brand-yellow flex items-center justify-start pl-5">
            <Check size={24} className="text-action-black" strokeWidth={3} />
          </div>

          {/* Left swipe underlay (cancel/exception) */}
          <div className="absolute inset-0 bg-red-500 flex items-center justify-end pr-5">
            <X size={24} className="text-white" strokeWidth={3} />
          </div>

          {/* Draggable content */}
          <motion.div
            drag="x"
            dragConstraints={{ left: 0, right: 0 }}
            dragElastic={0.15}
            onDragStart={handleDragStart}
            onDrag={handleDrag}
            onDragEnd={handleDragEnd}
            onPointerDown={handlePointerDown}
            onClick={handleClick}
            whileTap={{ scale: 0.98 }}
            className="relative z-10 flex items-center gap-3 px-4 py-3 bg-white cursor-pointer"
          >
            <div className="relative shrink-0">
              <div className="w-10 h-10 rounded-lg bg-bg-secondary flex items-center justify-center">
                <Icon size={20} className="text-action-black" />
              </div>
              {badge !== undefined && badge !== null && (
                <span className="absolute -top-1.5 -right-1.5 min-w-[18px] h-[18px] flex items-center justify-center bg-brand-yellow text-action-black text-[10px] font-semibold rounded-full px-1">
                  {badge}
                </span>
              )}
            </div>

            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-text-primary truncate">{title}</p>
              <p className="text-xs text-text-secondary truncate mt-0.5">{subtitle}</p>
              {extra && <p className="text-xs text-text-secondary truncate mt-0.5">{extra}</p>}
            </div>

            <ChevronRight size={16} className="text-text-secondary shrink-0" />
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
```

**GATE**:
执行 `grep -c "drag=\"x\"" src/components/Records/RecordCard.jsx`，输出 ≥ 1。
执行 `grep -c "SWIPE_THRESHOLD" src/components/Records/RecordCard.jsx`，输出 ≥ 1。
执行 `grep -c "navigator.vibrate" src/components/Records/RecordCard.jsx`，输出 ≥ 1。
执行 `grep -c "onSwipeLeft" src/components/Records/RecordCard.jsx`，输出 ≥ 1。
执行 `grep -c "onSwipeRight" src/components/Records/RecordCard.jsx`，输出 ≥ 1。
执行 `grep -c "AnimatePresence" src/components/Records/RecordCard.jsx`，输出 ≥ 1。

**NEXT**:
- GATE passes → proceed to Step 2
- GATE fails → 检查文件是否写入成功，重新写入完整内容

---

## Step 2: 给 mockData 添加删除记录辅助函数

**STATUS**: [x]

**ACTION**:
在 `src/data/mockData.js` 中，在文件末尾（所有 `export async function` 之后）追加以下三个函数：

```js
export async function removeCheckoutRecord(id) {
  await delay(100);
  checkoutRecords = checkoutRecords.filter(r => r.id !== id);
}

export async function removeReturnRecord(id) {
  await delay(100);
  returnRecords = returnRecords.filter(r => r.id !== id);
}

export async function removeInventoryCheckRecord(id) {
  await delay(100);
  inventoryCheckRecords = inventoryCheckRecords.filter(r => r.id !== id);
}
```

**GATE**:
执行 `grep -c "removeCheckoutRecord" src/data/mockData.js`，输出 ≥ 1。
执行 `grep -c "removeReturnRecord" src/data/mockData.js`，输出 ≥ 1。
执行 `grep -c "removeInventoryCheckRecord" src/data/mockData.js`，输出 ≥ 1。

**NEXT**:
- GATE passes → proceed to Step 3
- GATE fails → 检查是否追加到了文件末尾（不应覆盖现有 export），重新追加

---

## Step 3: 更新 CheckoutTab 使用滑动回调 + AnimatePresence + layout

**STATUS**: [x]

**ACTION**:
编辑 `src/pages/CheckoutTab.jsx`，做以下精确修改：

1. 在 import 区域添加：
```js
import { AnimatePresence } from 'framer-motion';
```

2. 修改 import from mockData 这一行，将：
```js
import { getItemByCode, getCheckoutRecords, submitCheckout } from '../data/mockData';
```
改为：
```js
import { getItemByCode, getCheckoutRecords, submitCheckout, removeCheckoutRecord } from '../data/mockData';
```

3. 在 `handleSubmit` 函数之后（约第49行 `};` 之后），添加一个新的函数：
```js
  const handleRemoveRecord = useCallback(async (id) => {
    setRecords(prev => prev.filter(r => r.id !== id));
    await removeCheckoutRecord(id);
  }, []);
```

4. 将 records.map 渲染区域（约第80-92行）替换为：
```jsx
          <AnimatePresence mode="popLayout">
            {records.map((record, idx) => (
              <RecordCard
                key={record.id}
                icon={LogOut}
                badge={record.quantity}
                title={`${record.warehouse}  ${record.time.split(' ')[0]}`}
                subtitle={record.itemName}
                extra={record.method === '外销' ? `¥${record.saleTotalPrice.toFixed(2)}` : record.method}
                index={idx}
                onClick={() => { setSelectedRecord(record); setShowDetail(true); }}
                onSwipeLeft={() => handleRemoveRecord(record.id)}
                onSwipeRight={() => handleRemoveRecord(record.id)}
              />
            ))}
          </AnimatePresence>
```

**GATE**:
执行 `grep -c "AnimatePresence" src/pages/CheckoutTab.jsx`，输出 ≥ 1。
执行 `grep -c "removeCheckoutRecord" src/pages/CheckoutTab.jsx`，输出 ≥ 1。
执行 `grep -c "onSwipeLeft" src/pages/CheckoutTab.jsx`，输出 ≥ 1。
执行 `grep -c "onSwipeRight" src/pages/CheckoutTab.jsx`，输出 ≥ 1。
执行 `grep -c "handleRemoveRecord" src/pages/CheckoutTab.jsx`，输出 ≥ 1。

**NEXT**:
- GATE passes → proceed to Step 4
- GATE fails → 读取文件确认当前状态，定位缺失的修改并补全

---

## Step 4: 更新 ReturnTab 使用滑动回调 + AnimatePresence + layout

**STATUS**: [x]

**ACTION**:
编辑 `src/pages/ReturnTab.jsx`，做以下精确修改：

1. 在 import 区域添加：
```js
import { AnimatePresence } from 'framer-motion';
```

2. 修改 import from mockData 这一行，将：
```js
import { getItemByCode, getBorrowersByItem, getReturnRecords, submitReturn } from '../data/mockData';
```
改为：
```js
import { getItemByCode, getBorrowersByItem, getReturnRecords, submitReturn, removeReturnRecord } from '../data/mockData';
```

3. 在 `handleSubmitReturn` 函数之后，添加：
```js
  const handleRemoveRecord = useCallback(async (id) => {
    setRecords(prev => prev.filter(r => r.id !== id));
    await removeReturnRecord(id);
  }, []);
```

4. 将 records.map 渲染区域替换为：
```jsx
          <AnimatePresence mode="popLayout">
            {records.map((record, idx) => (
              <RecordCard
                key={record.id}
                icon={RotateCcw}
                badge={record.returnQty}
                title={`${record.warehouse}  ${record.time.split(' ')[0]}`}
                subtitle={record.itemName}
                extra={`外借人：${record.borrower}`}
                index={idx}
                onClick={() => { setSelectedRecord(record); setShowDetail(true); }}
                onSwipeLeft={() => handleRemoveRecord(record.id)}
                onSwipeRight={() => handleRemoveRecord(record.id)}
              />
            ))}
          </AnimatePresence>
```

**GATE**:
执行 `grep -c "AnimatePresence" src/pages/ReturnTab.jsx`，输出 ≥ 1。
执行 `grep -c "removeReturnRecord" src/pages/ReturnTab.jsx`，输出 ≥ 1。
执行 `grep -c "onSwipeLeft" src/pages/ReturnTab.jsx`，输出 ≥ 1。

**NEXT**:
- GATE passes → proceed to Step 5
- GATE fails → 读取文件确认当前状态，定位缺失的修改并补全

---

## Step 5: 更新 InventoryTab 使用滑动回调 + AnimatePresence + layout

**STATUS**: [x]

**ACTION**:
编辑 `src/pages/InventoryTab.jsx`，做以下精确修改：

1. 在 import 区域添加：
```js
import { AnimatePresence } from 'framer-motion';
```

2. 修改 import from mockData 这一行，将：
```js
import { getItemByCode, getInventoryCheckRecords, submitInventoryCheck } from '../data/mockData';
```
改为：
```js
import { getItemByCode, getInventoryCheckRecords, submitInventoryCheck, removeInventoryCheckRecord } from '../data/mockData';
```

3. 在 `handleSubmit` 函数之后，添加：
```js
  const handleRemoveRecord = useCallback(async (id) => {
    setRecords(prev => prev.filter(r => r.id !== id));
    await removeInventoryCheckRecord(id);
  }, []);
```

4. 将 records.map 渲染区域替换为：
```jsx
          <AnimatePresence mode="popLayout">
            {records.map((record, idx) => (
              <RecordCard
                key={record.id}
                icon={ClipboardCheck}
                badge={record.difference > 0 ? `+${record.difference}` : record.difference}
                title={`${record.warehouse}  ${record.time.split(' ')[0]}`}
                subtitle={record.itemName}
                extra={`盘点数量：${record.actualQty}`}
                index={idx}
                onClick={() => { setSelectedRecord(record); setShowDetail(true); }}
                onSwipeLeft={() => handleRemoveRecord(record.id)}
                onSwipeRight={() => handleRemoveRecord(record.id)}
              />
            ))}
          </AnimatePresence>
```

**GATE**:
执行 `grep -c "AnimatePresence" src/pages/InventoryTab.jsx`，输出 ≥ 1。
执行 `grep -c "removeInventoryCheckRecord" src/pages/InventoryTab.jsx`，输出 ≥ 1。
执行 `grep -c "onSwipeLeft" src/pages/InventoryTab.jsx`，输出 ≥ 1。

**NEXT**:
- GATE passes → proceed to Step 6
- GATE fails → 读取文件确认当前状态，定位缺失的修改并补全

---

## Step 6: 编译验证 + 提交

**STATUS**: [x]

**ACTION**:
1. 运行 `npm run build` 确认无编译错误
2. 运行以下命令提交：
```bash
git add src/components/Records/RecordCard.jsx src/data/mockData.js src/pages/CheckoutTab.jsx src/pages/ReturnTab.jsx src/pages/InventoryTab.jsx
git commit -m "feat: industrial swipe actions on record cards with haptic, AnimatePresence exit, layout reflow"
```

**GATE**:
- `npm run build` exit code 0
- `git log --oneline -1` 输出包含 "swipe actions"

**NEXT**:
- GATE passes → 计划完成
- GATE fails → 运行 `npm run build 2>&1 | tail -30` 获取编译错误，根据错误信息修复 import 路径或语法。若 git commit 失败，用 `git status` 确认暂存区状态
