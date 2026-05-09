import { useRef } from 'react';
import { motion } from 'framer-motion';

export default function Stepper({ value, onChange, min = 1, max = 9999 }) {
  const holdTimer = useRef(null);
  const intervalTimer = useRef(null);

  const step = (dir) => {
    onChange(v => Math.min(max, Math.max(min, v + dir)));
  };

  const startHold = (dir) => {
    step(dir);
    let speed = 200;
    holdTimer.current = setTimeout(() => {
      const tick = () => {
        step(dir);
        speed = Math.max(30, speed * 0.8);
        intervalTimer.current = setTimeout(tick, speed);
      };
      tick();
    }, 500);
  };

  const stopHold = () => {
    clearTimeout(holdTimer.current);
    clearTimeout(intervalTimer.current);
  };

  return (
    <div className="flex items-center">
      <motion.button
        whileTap={{ scale: 0.94 }}
        onPointerDown={() => startHold(-1)}
        onPointerUp={stopHold}
        onPointerLeave={stopHold}
        className="w-12 h-12 rounded-l-2xl bg-bg-secondary flex items-center justify-center text-xl font-bold select-none border-none cursor-pointer"
        style={{ touchAction: 'none' }}
      >
        −
      </motion.button>
      <input
        type="number"
        value={value}
        onChange={e => onChange(() => Math.max(min, Math.min(max, Number(e.target.value) || min)))}
        className="w-16 h-12 text-center text-lg font-bold bg-white border-y border-gray-100"
        style={{ fontVariantNumeric: 'tabular-nums', boxShadow: 'none', outline: 'none' }}
      />
      <motion.button
        whileTap={{ scale: 0.94 }}
        onPointerDown={() => startHold(1)}
        onPointerUp={stopHold}
        onPointerLeave={stopHold}
        className="w-12 h-12 rounded-r-2xl bg-bg-secondary flex items-center justify-center text-xl font-bold select-none border-none cursor-pointer"
        style={{ touchAction: 'none' }}
      >
        +
      </motion.button>
    </div>
  );
}
