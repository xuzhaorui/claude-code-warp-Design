# Task Plan: Bottom Sheet (Bumble-Style Pricing UI)

**Goal**: A responsive bottom sheet component with pricing cards and feature comparison, matching the Bumble design spec from Design.md.
**Starting state**: Empty directory with only Design.md and bumble-1.mp4 — new Vite + React project.
**Constraints**: #FFC629 primary, 24px large radius, Spring physics (mass:1, tension:120, friction:14), no real payment logic, Tailwind CSS, Framer Motion.

---

## Step 1: Scaffold Vite + React project

**STATUS**: [x]

**ACTION**:
```
cd D:\claude-code-warp\Design
npm create vite@latest . -- --template react
npm install
```

**GATE**:
Run `npx vite --version`. Expected: version string printed (e.g., `6.x.x`). Run `ls package.json`. Expected: file exists.

**NEXT**:
- GATE passes → proceed to Step 2
- GATE fails → check Node.js is installed (`node --version`), if not, escalate to user. If Vite scaffold fails due to non-empty directory, run `npm create vite@latest temp-scaffold -- --template react` then move files into current directory.

---

## Step 2: Install Tailwind CSS, Framer Motion, and lucide-react

**STATUS**: [x]

**ACTION**:
```
cd D:\claude-code-warp\Design
npm install tailwindcss @tailwindcss/vite framer-motion lucide-react
```

**GATE**:
Run `npm ls tailwindcss framer-motion lucide-react 2>&1 | head -10`. Expected: all three packages listed without "ERR" or "missing".

**NEXT**:
- GATE passes → proceed to Step 3
- GATE fails → run `npm install` again to fix dependency tree, then retry. Escalate after 3 retries.

---

## Step 3: Configure Tailwind CSS

**STATUS**: [x]

**ACTION**:

3.1 Edit `vite.config.js` — replace entire content with:
```js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
  ],
})
```

3.2 Edit `src/index.css` — replace entire content with:
```css
@import "tailwindcss";

@theme {
  --color-bumble-yellow: #FFC629;
  --color-bumble-bg: #F2F2F2;
  --color-bumble-text: #222222;
  --color-bumble-text-secondary: #757575;
  --font-family-sans: 'Inter', system-ui, -apple-system, sans-serif;
}
```

3.3 Add Inter font to `index.html` — add inside `<head>` before closing tag:
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
```

**GATE**:
Run `npx vite build 2>&1 | tail -5`. Expected: "built in" message with no errors.

**NEXT**:
- GATE passes → proceed to Step 4
- GATE fails → check vite.config.js syntax and index.css imports. Fix any import path issues, then retry build.

---

## Step 4: Create pricing data and design tokens

**STATUS**: [x]

**ACTION**:

Create file `src/data.js` with:
```js
export const plans = [
  {
    id: 'week',
    label: '1 Week',
    price: 8.99,
    perWeek: 8.99,
    badge: null,
    popular: false,
  },
  {
    id: 'month',
    label: '1 Month',
    price: 24.99,
    perWeek: 5.77,
    badge: 'Most Popular',
    popular: true,
  },
  {
    id: 'lifetime',
    label: 'Lifetime',
    price: 149.99,
    perWeek: null,
    badge: 'Save 70%',
    popular: false,
  },
]

export const features = [
  { name: 'See who liked you', basic: false, premium: true },
  { name: 'Unlimited swipes', basic: false, premium: true },
  { name: 'Unlimited backtrack', basic: false, premium: true },
  { name: 'Advanced filters', basic: false, premium: true },
  { name: 'Incognito mode', basic: false, premium: true },
  { name: 'See who viewed your profile', basic: false, premium: true },
  { name: 'Travel mode (change location)', basic: false, premium: true },
  { name: 'Extend matches 24h', basic: false, premium: true },
]
```

**GATE**:
Run `node -e "const d = require('./src/data.js'); console.log(d.plans.length, d.features.length)"`. Expected: `3 8`. If that fails due to ESM, run `node --input-type=module -e "import { plans, features } from './src/data.js'; console.log(plans.length, features.length)"`. Expected: `3 8`.

**NEXT**:
- GATE passes → proceed to Step 5
- GATE fails → check file path and JS syntax. Escalate after 3 retries.

---

## Step 5: Build the PricingCard component

**STATUS**: [x]

**ACTION**:

Create file `src/PricingCard.jsx` with:
```jsx
import { motion } from 'framer-motion'

export default function PricingCard({ plan, isSelected, onSelect }) {
  return (
    <motion.button
      onClick={() => onSelect(plan.id)}
      whileTap={{ scale: 0.95 }}
      transition={{ type: 'spring', mass: 1, tension: 120, friction: 14 }}
      className={`
        relative flex-shrink-0 w-[140px] p-4 rounded-3xl border-2 text-left
        transition-colors duration-200 cursor-pointer
        ${isSelected
          ? 'border-bumble-yellow bg-white shadow-md'
          : 'border-transparent bg-bumble-bg'
        }
      `}
    >
      {plan.badge && (
        <span className="absolute -top-3 left-1/2 -translate-x-1/2 bg-bumble-yellow text-bumble-text text-[11px] font-bold px-3 py-0.5 rounded-full whitespace-nowrap">
          {plan.badge}
        </span>
      )}

      <p className="text-sm text-bumble-text-secondary font-medium">{plan.label}</p>
      <p className="text-2xl font-bold text-bumble-text mt-1">
        ${plan.price}
      </p>
      {plan.perWeek && (
        <p className="text-xs text-bumble-text-secondary mt-0.5">
          ${plan.perWeek.toFixed(2)}/week
        </p>
      )}

      <div className={`mt-3 w-5 h-5 rounded-full border-2 flex items-center justify-center
        ${isSelected ? 'border-bumble-yellow' : 'border-gray-300'}`}>
        {isSelected && (
          <div className="w-3 h-3 rounded-full bg-bumble-yellow" />
        )}
      </div>
    </motion.button>
  )
}
```

**GATE**:
Run `npx vite build 2>&1 | tail -5`. Expected: "built in" message with no errors.

**NEXT**:
- GATE passes → proceed to Step 6
- GATE fails → check import paths and JSX syntax. Fix and retry build.

---

## Step 6: Build the FeatureList component

**STATUS**: [x]

**ACTION**:

Create file `src/FeatureList.jsx` with:
```jsx
import { Check, X } from 'lucide-react'

export default function FeatureList({ features }) {
  return (
    <div className="w-full mt-6">
      <h3 className="text-base font-bold text-bumble-text mb-3">
        What you get
      </h3>
      <ul className="space-y-3">
        {features.map((f, i) => (
          <li key={i} className="flex items-center gap-3 text-sm">
            <span className="flex-shrink-0 w-5 h-5 rounded-full bg-bumble-yellow/20 flex items-center justify-center">
              <Check size={12} className="text-bumble-yellow stroke-[3]" />
            </span>
            <span className="text-bumble-text font-medium">{f.name}</span>
          </li>
        ))}
      </ul>
    </div>
  )
}
```

**GATE**:
Run `npx vite build 2>&1 | tail -5`. Expected: "built in" message with no errors.

**NEXT**:
- GATE passes → proceed to Step 7
- GATE fails → check lucide-react import and JSX syntax. Fix and retry build.

---

## Step 7: Build the BottomSheet main component

**STATUS**: [x]

**ACTION**:

Create file `src/BottomSheet.jsx` with:
```jsx
import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { X, ChevronDown } from 'lucide-react'
import PricingCard from './PricingCard'
import FeatureList from './FeatureList'
import { plans, features } from './data'

export default function BottomSheet() {
  const [isOpen, setIsOpen] = useState(true)
  const [selectedPlan, setSelectedPlan] = useState('month')

  const selected = plans.find(p => p.id === selectedPlan)

  return (
    <>
      {/* Overlay */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            key="overlay"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 bg-black/50 z-40"
            onClick={() => setIsOpen(false)}
          />
        )}
      </AnimatePresence>

      {/* Bottom Sheet */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            key="sheet"
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{
              type: 'spring',
              mass: 1,
              tension: 120,
              friction: 14,
            }}
            className="fixed bottom-0 left-0 right-0 z-50 bg-white rounded-t-3xl max-h-[90vh] overflow-y-auto"
          >
            {/* Drag indicator */}
            <div className="flex justify-center pt-3 pb-1">
              <div className="w-10 h-1 rounded-full bg-gray-300" />
            </div>

            {/* Close button */}
            <button
              onClick={() => setIsOpen(false)}
              className="absolute top-4 right-4 p-1 rounded-full hover:bg-gray-100 transition-colors"
            >
              <X size={20} className="text-bumble-text-secondary" />
            </button>

            <div className="px-5 pb-8 pt-2">
              {/* Header — Benefit highlight */}
              <div className="mb-5">
                <h2 className="text-xl font-bold text-bumble-text">
                  Get Premium
                </h2>
                <p className="text-sm text-bumble-text-secondary mt-1">
                  See who already liked you &amp; match instantly
                </p>
              </div>

              {/* Horizontal scrolling pricing cards */}
              <div className="flex gap-3 overflow-x-auto pb-2 snap-x snap-mandatory scrollbar-hide"
                style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}
              >
                {plans.map(plan => (
                  <PricingCard
                    key={plan.id}
                    plan={plan}
                    isSelected={selectedPlan === plan.id}
                    onSelect={setSelectedPlan}
                  />
                ))}
              </div>

              {/* Feature list */}
              <FeatureList features={features} />

              {/* CTA button */}
              <motion.button
                whileTap={{ scale: 0.97 }}
                transition={{ type: 'spring', mass: 1, tension: 120, friction: 14 }}
                className="w-full mt-6 py-4 rounded-full bg-bumble-yellow text-bumble-text font-bold text-base"
              >
                Continue — ${selected?.price ?? '—'}
              </motion.button>

              <p className="text-center text-[11px] text-bumble-text-secondary mt-3">
                Cancel anytime. No hidden fees.
              </p>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Re-open trigger when closed */}
      {!isOpen && (
        <div className="fixed inset-0 flex items-center justify-center">
          <button
            onClick={() => setIsOpen(true)}
            className="px-6 py-3 rounded-full bg-bumble-yellow text-bumble-text font-bold shadow-lg"
          >
            Show Plans
          </button>
        </div>
      )}
    </>
  )
}
```

**GATE**:
Run `npx vite build 2>&1 | tail -5`. Expected: "built in" message with no errors.

**NEXT**:
- GATE passes → proceed to Step 8
- GATE fails → check all import paths (./PricingCard, ./FeatureList, ./data, framer-motion, lucide-react). Fix and retry.

---

## Step 8: Wire up App.jsx entry point

**STATUS**: [x]

**ACTION**:

Replace entire content of `src/App.jsx` with:
```jsx
import BottomSheet from './BottomSheet'

export default function App() {
  return (
    <div className="min-h-screen bg-bumble-bg font-sans">
      <BottomSheet />
    </div>
  )
}
```

Replace entire content of `src/App.css` with an empty file (remove all default Vite styles):
```
```

**GATE**:
Run `npx vite build 2>&1 | tail -5`. Expected: "built in" message with no errors.

**NEXT**:
- GATE passes → proceed to Step 9
- GATE fails → check import paths. Fix and retry.

---

## Step 9: Visual smoke test — dev server

**STATUS**: [x]

**ACTION**:
```
npx vite --host
```
Open browser to `http://localhost:5173` (or the URL Vite prints).

**GATE**:
Run in a new terminal: `curl -s http://localhost:5173 | head -20`. Expected: HTML containing `<div id="root">`. Then visually confirm:
- Bottom sheet slides up from bottom
- 3 pricing cards visible (1 Week, 1 Month, Lifetime)
- Tapping a card selects it with spring animation + 0.95x scale feedback
- Feature list with 8 items and yellow checkmark icons
- Yellow CTA button at bottom with price
- Clicking overlay or X closes sheet; "Show Plans" reopens it

**NEXT**:
- GATE passes → proceed to Step 10 (STOP dev server)
- GATE fails → check browser console for errors. If build works but runtime errors, check component imports and framer-motion version. Escalate with console error output.

---

## Step 10: Clean up default Vite boilerplate

**STATUS**: [x]

**ACTION**:

Delete unused files:
```
rm src/assets/react.svg
```
Remove the `src/assets` directory if empty after deletion.

**GATE**:
Run `ls src/assets 2>&1`. Expected: "No such file or directory" or empty. Run `npx vite build 2>&1 | tail -3`. Expected: build succeeds with no errors.

**NEXT**:
- GATE passes → plan complete
- GATE fails → the asset deletion may have broken an import. Check that no file references `src/assets/react.svg`. Fix and retry.
