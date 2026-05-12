import { useRef, useState } from 'react';
import { motion } from 'framer-motion';

export default function Stepper({ value, onChange, min = 1, max = 9999, label, hint, error, unit }) {
  const holdTimer = useRef(null);
  const intervalTimer = useRef(null);
  const [bounce, setBounce] = useState(false);

  const step = (dir) => {
    const v = Number(value) || 0;
    const next = Math.min(max, Math.max(min, v + dir));
    onChange(next || '');
    triggerBounce();
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

  const triggerBounce = () => {
    setBounce(false);
    requestAnimationFrame(() => setBounce(true));
  };

  const handleChange = (e) => {
    const raw = e.target.value;
    if (raw === '') { onChange(''); return; }
    const n = Number(raw);
    if (!Number.isNaN(n)) onChange(Math.max(min, Math.min(max, n)));
  };

  return (
    <div>
      <div
        className={`relative flex items-center h-14 rounded-2xl px-1.5 gap-0 border-2 transition-all duration-200 ${
          error ? 'border-action-black' : 'border-transparent focus-within:border-brand-yellow focus-within:bg-white focus-within:shadow-[0_0_0_3px_rgba(255,198,41,0.15)]'
        } bg-bg-secondary`}
      >
        {label && (
          <span className="absolute -top-2 left-3.5 text-[11px] font-bold text-brand-yellow bg-bg-secondary px-1 tracking-wide pointer-events-none transition-colors duration-200 focus-within:!bg-white">
            {label}
          </span>
        )}
        <motion.button
          whileTap={{ scale: 0.9 }}
          onPointerDown={() => startHold(-1)}
          onPointerUp={stopHold}
          onPointerLeave={stopHold}
          className="w-11 h-11 rounded-xl bg-[#E8E8E8] text-text-primary flex items-center justify-center text-[22px] font-bold select-none border-none cursor-pointer shrink-0 active:bg-[#DADADA] transition-colors duration-150"
        >
          −
        </motion.button>
        <input
          type="number"
          inputMode="numeric"
          value={value}
          onChange={handleChange}
          placeholder="0"
          className={`flex-1 h-full text-center text-[22px] font-bold bg-transparent border-none outline-none text-text-primary min-w-0 placeholder:text-gray-300 placeholder:font-medium placeholder:text-base ${bounce ? 'animate-[stepperBounce_0.2s_ease]' : ''}`}
          style={{ fontVariantNumeric: 'tabular-nums', MozAppearance: 'textfield' }}
        />
        <motion.button
          whileTap={{ scale: 0.9 }}
          onPointerDown={() => startHold(1)}
          onPointerUp={stopHold}
          onPointerLeave={stopHold}
          className="w-11 h-11 rounded-xl bg-action-black text-white flex items-center justify-center text-[22px] font-bold select-none border-none cursor-pointer shrink-0 active:bg-[#333] transition-colors duration-150"
        >
          +
        </motion.button>
        {unit && (
          <span className="text-sm font-semibold text-text-secondary mr-1 shrink-0">{unit}</span>
        )}
      </div>
      {hint && !error && (
        <p className="text-[13px] text-text-secondary mt-2 pl-1">{hint}</p>
      )}
    </div>
  );
}
