# Task Plan: Pixel & Tactile Polish Pass

**Goal**: Fine-tune drag elasticity, reorder card text hierarchy, add drag-to-dismiss gesture, enhance selected card shadow, and restyle the badge — all in existing files.
**Starting state**: Working project with BottomSheet.jsx (drag="x" cards, spring damping:25/stiffness:200), PricingCard.jsx (layoutId highlight, radio dot), FeatureList.jsx (staggered entrance).
**Constraints**: Keep layoutId animations, unified springs, existing FeatureList unchanged.

---

## Step 1: Rewrite PricingCard.jsx — text hierarchy, shadow, badge styling

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
      {/* Selection highlight */}
      {isSelected && (
        <motion.div
          layoutId="card-highlight"
          className="absolute inset-0 rounded-3xl border-2 border-bumble-yellow bg-white"
          style={{
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
            transition: 'box-shadow 0.3s ease',
          }}
          transition={spring}
        />
      )}

      {!isSelected && (
        <div
          className="absolute inset-0 rounded-3xl border-2 border-transparent bg-bumble-bg"
          style={{ boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}
        />
      )}

      {/* Badge — pill shape, compact typography */}
      {plan.badge && (
        <span className="relative z-10 absolute -top-3 left-1/2 -translate-x-1/2 bg-bumble-yellow text-bumble-text text-[10px] font-bold tracking-wider px-3 py-0.5 rounded-full whitespace-nowrap">
          {plan.badge}
        </span>
      )}

      {/* Content — per-week is primary, total is secondary */}
      <div className="relative z-10">
        <p className="text-sm text-bumble-text-secondary font-medium">{plan.label}</p>
        {plan.perWeek ? (
          <>
            <p className="text-2xl font-bold text-bumble-text mt-1">
              ${plan.perWeek.toFixed(2)}<span className="text-sm font-medium text-bumble-text-secondary">/week</span>
            </p>
            <p className="text-xs text-bumble-text-secondary mt-0.5">
              Total ${plan.price}
            </p>
          </>
        ) : (
          <p className="text-2xl font-bold text-bumble-text mt-1">
            ${plan.price}
          </p>
        )}
      </div>

      {/* Radio indicator */}
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
- GATE passes → proceed to Step 2
- GATE fails → run `npx vite build 2>&1 | grep -i error` to get the specific error. Check JSX syntax around the ternary in the content section. Fix and retry. Escalate after 3 retries.

---

## Step 2: Rewrite BottomSheet.jsx — dragElastic 0.15, drag-to-dismiss, synced overlay exit

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

  const CARD_W = 152

  const snapTo = (id) => {
    setSelectedPlan(id)
    const idx = plans.findIndex(p => p.id === id)
    const cw = containerRef.current?.offsetWidth ?? 0
    const maxDrag = Math.max(0, plans.length * CARD_W - cw + 24)
    const target = Math.max(-maxDrag, Math.min(0, -idx * CARD_W))
    animate(x, target, spring)
  }

  const handleCardDragEnd = (_, info) => {
    const currentX = x.get()
    const velocity = info.velocity.x
    const offset = currentX + velocity * 0.2
    let idx = Math.round(-offset / CARD_W)
    idx = Math.max(0, Math.min(plans.length - 1, idx))
    snapTo(plans[idx].id)
  }

  const handleSheetDragEnd = (_, info) => {
    if (info.offset.y > 150) setIsOpen(false)
  }

  return (
    <>
      {/* Overlay — exit synced with sheet using same spring */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            key="overlay"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={spring}
            className="fixed inset-0 bg-black/50 z-40"
            onClick={() => setIsOpen(false)}
          />
        )}
      </AnimatePresence>

      {/* Bottom Sheet with drag-to-dismiss */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            key="sheet"
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={spring}
            drag="y"
            dragConstraints={{ top: 0, bottom: 0 }}
            dragElastic={0.1}
            onDragEnd={handleSheetDragEnd}
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

              {/* Drag-swipe pricing cards — elastic 0.15 */}
              <div ref={containerRef} className="overflow-hidden">
                <motion.div
                  className="flex gap-3 pb-2 cursor-grab active:cursor-grabbing"
                  style={{ x }}
                  drag="x"
                  dragConstraints={{ left: 0, right: 0 }}
                  dragElastic={0.15}
                  onDragEnd={handleCardDragEnd}
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

      {/* Re-open trigger */}
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
Run `npx vite build 2>&1 | tail -3`. Expected: `✓ built in` with zero errors.

**NEXT**:
- GATE passes → proceed to Step 3
- GATE fails → check that `handleCardDragEnd` and `handleSheetDragEnd` are both defined before the return. Check import paths. Fix and retry. Escalate after 3 retries.

---

## Step 3: Final build verification

**STATUS**: [x]

**ACTION**:
```
npx vite build
```

**GATE**:
Run `npx vite build 2>&1`. Expected: exit code 0, output ends with `✓ built in`, no warnings about missing modules.

**NEXT**:
- GATE passes → proceed to Step 4
- GATE fails → run `npx vite build 2>&1 | grep -i error` to extract the specific error. Cross-reference with the file changed in Step 1 or 2. Fix and retry. Escalate after 3 retries.

---

## Step 4: Dev server smoke test

**STATUS**: [x]

**ACTION**:
```
npx vite --host
```

**GATE**:
Run in a separate terminal: `curl -s http://localhost:5173 | head -5`. Expected: HTML containing `<div id="root">`.

Then visually confirm in browser at `http://localhost:5173`:
- Card text shows per-week price as large/bold primary, total as small gray secondary
- Selected card has prominent floating shadow `0 20px 25px -5px rgba(0,0,0,0.1)`
- "Most Popular" badge uses text-[10px] font-bold tracking-wider with pill shape
- Dragging cards horizontally has noticeable rubber-band edge resistance (dragElastic 0.15)
- Dragging sheet downward > 150px triggers close; dragging < 150px snaps back
- Overlay and sheet exit simultaneously when closing

**NEXT**:
- GATE passes → STOP dev server, plan complete
- GATE fails → check browser console (F12) for runtime errors. If drag-to-dismiss doesn't work, verify that `drag="y"` and `dragConstraints={{ top: 0, bottom: 0 }}` are on the sheet's motion.div. If overlay doesn't sync, verify overlay exit transition uses `spring` not `duration`. Escalate after 3 retries.
