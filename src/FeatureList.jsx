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
