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

  const btnClass = 'w-12 h-12 rounded-full bg-action-black text-white flex items-center justify-center text-2xl font-bold select-none border-none cursor-pointer';
  const btnStyle = { boxShadow: '0 2px 6px rgba(0,0,0,0.2)', touchAction: 'none' };

  return (
    <div className="flex items-center">
      <motion.button
        whileTap={{ scale: 0.9 }}
        onPointerDown={() => startHold(-1)}
        onPointerUp={stopHold}
        onPointerLeave={stopHold}
        className={btnClass}
        style={btnStyle}
      >
        −
      </motion.button>
      <input
        type="number"
        value={value}
        onChange={e => onChange(() => Math.max(min, Math.min(max, Number(e.target.value) || min)))}
        className="w-20 h-12 text-center text-lg font-bold bg-transparent border-none"
        style={{ fontVariantNumeric: 'tabular-nums', outline: 'none' }}
      />
      <motion.button
        whileTap={{ scale: 0.9 }}
        onPointerDown={() => startHold(1)}
        onPointerUp={stopHold}
        onPointerLeave={stopHold}
        className={btnClass}
        style={btnStyle}
      >
        +
      </motion.button>
    </div>
  );
}
