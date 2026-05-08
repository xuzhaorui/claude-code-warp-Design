# Task Plan: Bottom Sheet Interaction Upgrade

**Goal**: Upgrade existing BottomSheet with drag-based card swipe, unified spring physics (damping:25, stiffness:200), layoutId border transitions, staggered feature list, and AnimatePresence unmount animations.
**Starting state**: Working Vite+React+Tailwind+Framer Motion project with BottomSheet.jsx, PricingCard.jsx, FeatureList.jsx, data.js.
**Constraints**: Replace ALL old spring params with damping:25/stiffness:200; overflow:hidden + drag="x" replaces CSS scroll; layoutId for yellow border crossfade.

---

## Step 1: Rewrite BottomSheet.jsx — unified springs + drag container + AnimatePresence for button

**STATUS**: [x]

**ACTION**:

Replace the entire content of `src/BottomSheet.jsx` with:

```jsx
import { useState, useRef } from 'react'
import { motion, AnimatePresence, useMotionValue, animate } from 'framer-motion'
import { X } from 'lucide-react'
import PricingCard from './PricingCard'
import FeatureList from './FeatureList'
import { plans, features } from './data'

const spring = { type: 'spring', damping: 25, stiffness: 200 }

export default function BottomSheet() {
  const [isOpen, setIsOpen] = useState(true)
  const [selectedPlan, setSelectedPlan] = useState('month')
  const containerRef = useRef(null)
  const x = useMotionValue(0)

  const selected = plans.find(p => p.id === selectedPlan)

  const CARD_W = 152 // 140px card + 12px gap

  const snapTo = (id) => {
    setSelectedPlan(id)
    const idx = plans.findIndex(p => p.id === id)
    const cw = containerRef.current?.offsetWidth ?? 0
    const maxDrag = Math.max(0, plans.length * CARD_W - cw + 24)
    const target = Math.max(-maxDrag, Math.min(0, -idx * CARD_W))
    animate(x, target, spring)
  }

  const handleDragEnd = (_, info) => {
    const currentX = x.get()
    const velocity = info.velocity.x
    const offset = currentX + velocity * 0.2

    let idx = Math.round(-offset / CARD_W)
    idx = Math.max(0, Math.min(plans.length - 1, idx))
    snapTo(plans[idx].id)
  }

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
            transition={spring}
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
              {/* Header */}
              <div className="mb-5">
                <h2 className="text-xl font-bold text-bumble-text">
                  Get Premium
                </h2>
                <p className="text-sm text-bumble-text-secondary mt-1">
                  See who already liked you &amp; match instantly
                </p>
              </div>

              {/* Drag-swipe pricing cards */}
              <div ref={containerRef} className="overflow-hidden">
                <motion.div
                  className="flex gap-3 pb-2 cursor-grab active:cursor-grabbing"
                  style={{ x }}
                  drag="x"
                  dragConstraints={{ left: 0, right: 0 }}
                  dragElastic={0.1}
                  onDragEnd={handleDragEnd}
                >
                  {plans.map(plan => (
                    <PricingCard
                      key={plan.id}
                      plan={plan}
                      isSelected={selectedPlan === plan.id}
                      onSelect={snapTo}
                    />
                  ))}
                </motion.div>
              </div>

              {/* Feature list */}
              <FeatureList features={features} />

              {/* CTA button */}
              <motion.button
                whileTap={{ scale: 0.96 }}
                transition={spring}
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

      {/* Re-open trigger with AnimatePresence */}
      <AnimatePresence>
        {!isOpen && (
          <motion.div
            key="show-plans"
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.8 }}
            transition={spring}
            className="fixed inset-0 flex items-center justify-center"
          >
            <button
              onClick={() => setIsOpen(true)}
              className="px-6 py-3 rounded-full bg-bumble-yellow text-bumble-text font-bold shadow-lg"
            >
              Show Plans
            </button>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  )
}
```

**GATE**:
Run `npx vite build 2>&1 | tail -3`. Expected: `✓ built in` message with no errors. (Build will fail on PricingCard until Step 2, so also check: if the only errors reference `layoutId` or missing PricingCard exports, that is expected — proceed. If errors reference BottomSheet itself, fix syntax first.)

**NEXT**:
- GATE passes (BottomSheet compiles cleanly, or only PricingCard-related errors) → proceed to Step 2
- GATE fails with BottomSheet syntax errors → check import paths (framer-motion, lucide-react, ./PricingCard, ./data). Fix and retry. Escalate after 3 retries.

---

## Step 2: Rewrite PricingCard.jsx — layoutId highlight + dynamic shadow + unified springs

**STATUS**: [x]

**ACTION**:

Replace the entire content of `src/PricingCard.jsx` with:

```jsx
import { motion } from 'framer-motion'

const spring = { type: 'spring', damping: 25, stiffness: 200 }

export default function PricingCard({ plan, isSelected, onSelect }) {
  return (
    <motion.button
      onClick={() => onSelect(plan.id)}
      whileTap={{ scale: 0.96 }}
      transition={spring}
      className="relative flex-shrink-0 w-[140px] p-4 rounded-3xl text-left cursor-pointer bg-bumble-bg"
    >
      {/* Selection highlight — shared layoutId for smooth cross-card border animation */}
      {isSelected && (
        <motion.div
          layoutId="card-highlight"
          className="absolute inset-0 rounded-3xl border-2 border-bumble-yellow bg-white"
          style={{
            boxShadow: '0 4px 20px rgba(255, 198, 41, 0.3), 0 2px 8px rgba(0,0,0,0.08)',
          }}
          transition={spring}
        />
      )}

      {/* Default subtle shadow when not selected */}
      {!isSelected && (
        <div
          className="absolute inset-0 rounded-3xl border-2 border-transparent bg-bumble-bg"
          style={{ boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}
        />
      )}

      {/* Badge */}
      {plan.badge && (
        <span className="relative z-10 absolute -top-3 left-1/2 -translate-x-1/2 bg-bumble-yellow text-bumble-text text-[11px] font-bold px-3 py-0.5 rounded-full whitespace-nowrap">
          {plan.badge}
        </span>
      )}

      {/* Content */}
      <div className="relative z-10">
        <p className="text-sm text-bumble-text-secondary font-medium">{plan.label}</p>
        <p className="text-2xl font-bold text-bumble-text mt-1">
          ${plan.price}
        </p>
        {plan.perWeek && (
          <p className="text-xs text-bumble-text-secondary mt-0.5">
            ${plan.perWeek.toFixed(2)}/week
          </p>
        )}
      </div>

      {/* Radio indicator with layout animation */}
      <motion.div
        layout
        className={`relative z-10 mt-3 w-5 h-5 rounded-full border-2 flex items-center justify-center
          ${isSelected ? 'border-bumble-yellow' : 'border-gray-300'}`}
      >
        {isSelected && (
          <motion.div
            layoutId="radio-dot"
            className="w-3 h-3 rounded-full bg-bumble-yellow"
            transition={spring}
          />
        )}
      </motion.div>
    </motion.button>
  )
}
```

**GATE**:
Run `npx vite build 2>&1 | tail -3`. Expected: `✓ built in` with zero errors.

**NEXT**:
- GATE passes → proceed to Step 3
- GATE fails → check framer-motion import and JSX syntax. The `layoutId` prop requires framer-motion ≥ 7. Run `npm ls framer-motion` to verify version. Fix and retry. Escalate after 3 retries.

---

## Step 3: Rewrite FeatureList.jsx — staggered entrance animation

**STATUS**: [x]

**ACTION**:

Replace the entire content of `src/FeatureList.jsx` with:

```jsx
import { motion } from 'framer-motion'
import { Check } from 'lucide-react'

const item = {
  hidden: { opacity: 0, x: -12 },
  visible: (i) => ({
    opacity: 1,
    x: 0,
    transition: {
      type: 'spring',
      damping: 25,
      stiffness: 200,
      delay: i * 0.06,
    },
  }),
}

export default function FeatureList({ features }) {
  return (
    <div className="w-full mt-6">
      <h3 className="text-base font-bold text-bumble-text mb-3">
        What you get
      </h3>
      <ul className="space-y-3">
        {features.map((f, i) => (
          <motion.li
            key={i}
            custom={i}
            variants={item}
            initial="hidden"
            animate="visible"
            className="flex items-center gap-3 text-sm"
          >
            <span className="flex-shrink-0 w-5 h-5 rounded-full bg-bumble-yellow/20 flex items-center justify-center">
              <Check size={12} className="text-bumble-yellow stroke-[3]" />
            </span>
            <span className="text-bumble-text font-medium">{f.name}</span>
          </motion.li>
        ))}
      </ul>
    </div>
  )
}
```

**GATE**:
Run `npx vite build 2>&1 | tail -3`. Expected: `✓ built in` with zero errors.

**NEXT**:
- GATE passes → proceed to Step 4
- GATE fails → check lucide-react import and motion.li syntax. Fix and retry. Escalate after 3 retries.

---

## Step 4: Final build verification

**STATUS**: [x]

**ACTION**:
```
npx vite build
```

**GATE**:
Run `npx vite build 2>&1`. Expected: exit code 0, output ends with `✓ built in`, no warnings about missing modules or unresolved imports.

**NEXT**:
- GATE passes → proceed to Step 5
- GATE fails → run `npx vite build 2>&1 | grep -i error` to extract the specific error. Cross-reference with the file that changed in Steps 1-3. Fix the reported file and retry. Escalate after 3 retries.

---

## Step 5: Dev server smoke test

**STATUS**: [x]

**ACTION**:
```
npx vite --host
```

**GATE**:
Run in a separate terminal: `curl -s http://localhost:5173 | head -5`. Expected: HTML containing `<div id="root">`.

Then visually confirm in browser at `http://localhost:5173`:
- Bottom sheet slides up with spring bounce (damping:25, stiffness:200)
- Cards are draggable horizontally with snap behavior
- Tapping a card or dragging to snap triggers smooth yellow border transition (layoutId)
- Selected card has warm yellow box-shadow glow
- Feature list items enter one by one with stagger
- Clicking overlay/X closes sheet; Show Plans button fades in with scale
- Re-opening: Show Plans fades out, sheet slides back up

**NEXT**:
- GATE passes → STOP dev server, plan complete
- GATE fails → check browser console (F12) for errors. If runtime error references a specific component, re-read that file and compare against the plan's code. Fix and retry. Escalate after 3 retries.
