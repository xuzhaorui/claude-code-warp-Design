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
