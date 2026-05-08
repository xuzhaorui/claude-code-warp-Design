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
