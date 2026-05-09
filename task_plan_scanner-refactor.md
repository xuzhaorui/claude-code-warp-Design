# Task Plan: Scanner UI Refactor — Protocol 3.1 Dark Industrial Shift

**Goal**: 将 ScannerOverlay 从小窗口白底扫码重构为沉浸式全屏深色扫码界面（全屏相机 + 毛玻璃遮罩镂空 + 黄色粗体 L 角 + 暗色抽屉头），`npm run dev` 正常运行无报错。
**Starting state**: Design.md 已更新至 Protocol 3.1。ScannerOverlay.jsx 使用 256x256 小窗口 + 白色底部抽屉。表单组件保持不变。
**Constraints**: 取景框 1:1 正方形 65-70% 屏宽；表单内容区域保持白色不变；不修改任何表单组件文件。

---

## Step 1: Add Dark Palette CSS Tokens

**STATUS**: [x]

**ACTION**:
Edit `src/index.css`. Inside the existing `@theme { }` block, after line 9 (`--color-text-secondary: #757575;`), add three new tokens:

```css
  --color-bg-dark: #000000;
  --color-bg-dark-secondary: #121212;
  --color-text-dark: #FFFFFF;
```

**GATE**:
Run `npm run dev` in background. Expected: Vite compiles successfully with no errors, dev server accessible at localhost URL. Kill the dev server after confirming.

**NEXT**:
- GATE passes → proceed to Step 2
- GATE fails → check that tokens are inside the `@theme { }` block and separated by semicolons. Fix and re-run.

---

## Step 2: Rewrite ScannerOverlay.jsx — Immersive Camera + Dark Sheet

**STATUS**: [x]

**ACTION**:
Completely rewrite `src/components/Scanner/ScannerOverlay.jsx` with the following implementation. The file should export a single default component `ScannerOverlay` with these props: `{ isOpen, onClose, onScanSuccess, sheetTitle, sheetContent, onSheetClose }`.

### Architecture of the new ScannerOverlay:

**A. Imports and constants** (lines 1-7):
- Import `useEffect, useRef, useState, useCallback, useMemo` from react
- Import `motion, AnimatePresence` from framer-motion
- Import `X` from lucide-react
- Import `Html5Qrcode` from html5-qrcode
- Define `SPRING = { type: 'spring', stiffness: 200, damping: 25, mass: 1 }`
- Define `playBeep()` function: creates AudioContext, 800Hz sine oscillator, 80ms duration, gain 0.3→0.001 exponential ramp, closes ctx after 200ms timeout

**B. Cutout dimension calculation**:
- Use `useMemo` to compute cutout size based on viewport:
  ```js
  const cutoutSize = useMemo(() => {
    const vw = typeof window !== 'undefined' ? window.innerWidth : 375;
    return Math.min(Math.round(vw * 0.7), 360);
  }, []);
  ```
- Add a `useState` for cutout dimensions and a resize listener in useEffect that recomputes on window resize:
  ```js
  const [cutout, setCutout] = useState(() => {
    const vw = typeof window !== 'undefined' ? window.innerWidth : 375;
    const size = Math.min(Math.round(vw * 0.7), 360);
    return size;
  });
  ```
  In a useEffect: `window.addEventListener('resize', () => setCutout(Math.min(Math.round(window.innerWidth * 0.7), 360)))`, clean up on unmount.

**C. Four-box mask overlay**:
- The camera scanner element becomes `<div id="seamless-scanner" className="absolute inset-0" />` (full viewport).
- Immediately after the scanner element, render four overlay bars that create the masked cutout effect. All bars use `pointer-events-none`:
  - **Top bar**: `absolute top-0 left-0 right-0` with height = `calc(50% - cutout/2 px)`, `bg-black/60 backdrop-blur-[15px]`
  - **Bottom bar**: `absolute left-0 right-0 bottom-0` with height = `calc(50% - cutout/2 px)`, `bg-black/60 backdrop-blur-[15px]`
  - **Left bar**: `absolute top-[calc(50%-cutout/2 px)] left-0` with width = `calc(50% - cutout/2 px)`, height = `cutout px`, `bg-black/60 backdrop-blur-[15px]`
  - **Right bar**: `absolute top-[calc(50%-cutout/2 px)] right-0` with width = `calc(50% - cutout/2 px)`, height = `cutout px`, `bg-black/60 backdrop-blur-[15px]`

  Position values use inline `style` prop with computed pixel values:
  ```jsx
  const half = cutout / 2;
  const topH = `calc(50% - ${half}px)`;
  // etc.
  ```

**D. Suppress library shading**:
- After `scanner.start()` resolves, run:
  ```js
  document.getElementById('qr-shaded-region')?.style?.display = 'none';
  ```
- Also in `resumeScanning()`, after calling `scanner.start()`, run the same suppression.
- Wrap this in a helper function `hideShading()` called in both places.

**E. Update qrbox config**:
- In both `start()` calls and `resumeScanning()`, change `qrbox: { width: 250, height: 250 }` to `qrbox: { width: cutout, height: cutout }`.

**F. Corner brackets** (always yellow, 4px, 40px arms):
- Wrap in a centered absolute div matching cutout dimensions:
  ```jsx
  <div className="absolute top-1/2 left-1/2 pointer-events-none" style={{ width: cutout, height: cutout, transform: 'translate(-50%, -50%)' }}>
  ```
- Four corner divs, each with `border-[4px] border-brand-yellow`, NO border-radius:
  - Top-left: `absolute top-0 left-0 w-10 h-10 border-t-[4px] border-l-[4px] border-brand-yellow`
  - Top-right: `absolute top-0 right-0 w-10 h-10 border-t-[4px] border-r-[4px] border-brand-yellow`
  - Bottom-left: `absolute bottom-0 left-0 w-10 h-10 border-b-[4px] border-l-[4px] border-brand-yellow`
  - Bottom-right: `absolute bottom-0 right-0 w-10 h-10 border-b-[4px] border-r-[4px] border-brand-yellow`

**G. Scan line** (inside the same cutout wrapper as corners):
- Only show when `!scanned`:
  ```jsx
  <motion.div
    className="absolute left-4 right-4 h-[2px]"
    style={{
      background: 'linear-gradient(90deg, transparent, #FFC629, transparent)',
      boxShadow: '0 0 12px 3px rgba(255, 198, 41, 0.4)',
    }}
    animate={{ top: ['0%', '95%', '0%'] }}
    transition={{ duration: 2.5, repeat: Infinity, ease: 'easeInOut' }}
  />
  ```

**H. Hint text**:
- Show when `!scanned && !error`:
  ```jsx
  <div className="absolute bottom-8 left-0 right-0 text-center text-white/60 text-sm font-semibold tracking-wide">
    将二维码对准扫描框
  </div>
  ```

**I. Exit button** (frosted glass, unchanged from current):
- Keep current styling: `absolute top-4 left-4 px-4 py-2 rounded-full text-white text-sm font-semibold backdrop-blur-xl bg-white/15 border border-white/20 active:bg-white/25`

**J. Camera blur on scan**:
- Wrap the entire camera section (scanner element + mask overlay + corners + scan line) in a div:
  `className={flex-1 relative overflow-hidden transition-all duration-300 ${scanned ? 'blur-[5px] brightness-50' : ''}}`

**K. Dark bottom sheet**:
- The bottom sheet container changes from `bg-white` to `bg-bg-dark-secondary`:
  ```jsx
  <motion.div className="absolute bottom-0 left-0 right-0 bg-bg-dark-secondary rounded-t-3xl max-h-[85vh] flex flex-col">
  ```
- **Header section** (handle + title + close):
  - Handle pill: `bg-white/20` (instead of `bg-gray-300`)
  - Border: `border-white/10` (instead of `border-gray-100`)
  - Title text: `text-white` with `font-bold` (instead of `text-text-primary`)
  - Close button: `active:bg-white/10` (instead of `active:bg-gray-100`)
  - X icon: `text-white/60` (instead of `text-text-secondary`)
- **Content section** (scrollable form area):
  - Add `bg-white rounded-t-3xl -mt-3` to the scrollable div to create a white content area sitting below the dark header
  - Keep all other classes (`overflow-y-auto hide-scrollbar px-5 py-4`)
  - This means forms render on white background — no form changes needed

**L. Scanner lifecycle** (keep existing logic):
- Keep the existing `isOpen` useEffect for scanner start/stop
- Keep `resumeScanning` callback
- Keep `handleManualClose` and `handleSheetClose`
- Keep `sheetContent` show/hide effect
- Keep all refs (`scannerRef`, `mountedRef`, `scanningRef`)

**GATE**:
Run `npm run dev` in background. Expected: Vite compiles successfully with no errors, no React warnings about missing keys or invalid props. Run `curl -s http://localhost:5173 | head -5` and verify HTML is returned. Kill dev server.

**NEXT**:
- GATE passes → proceed to Step 3
- GATE fails → run `npm run dev 2>&1` and capture the error output. If compilation error: check JSX syntax, missing imports, or mismatched tags. Fix and re-run. If runtime error: check browser console output. Escalate to user after 3 retries.

---

## Step 3: End-to-End Verification

**STATUS**: [x]

**ACTION**:
1. Run `npm run dev` in background.
2. Wait for "ready" message, then open browser to the dev URL.
3. Verify the following in browser:
   - Login to the app (any username/password).
   - Navigate to 出库 tab → tap scan button → full black screen with camera feed.
   - Four dark mask bars visible around a centered transparent square cutout.
   - Yellow (#FFC629) L-shaped corner brackets visible at all four corners of cutout.
   - Yellow glowing scan line sweeping vertically inside cutout.
   - Frosted glass "退出扫码" button visible top-left.
   - "将二维码对准扫描框" hint visible at bottom.
4. If camera is not available (desktop browser without camera), verify the layout still renders correctly with the error message inside the dark overlay.
5. Kill dev server.

**GATE**:
Run `npm run build`. Expected: build completes with exit code 0, no errors.

**NEXT**:
- GATE passes → report "task_plan_scanner-refactor.md complete — all 3 steps passed GATE."
- GATE fails → run `npm run build 2>&1 | tail -30` to capture build error. Fix the specific file mentioned in the error, then re-run from Step 3. Escalate after 3 retries.
