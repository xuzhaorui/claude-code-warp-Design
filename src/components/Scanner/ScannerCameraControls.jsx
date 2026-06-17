import { motion } from 'framer-motion';
import { Flashlight, ZoomIn, ZoomOut } from 'lucide-react';

const TAP = { scale: 0.96 };

function ControlButton({ active, children, label, onPointerDown }) {
  return (
    <motion.button
      type="button"
      whileTap={TAP}
      onPointerDown={onPointerDown}
      className={`h-11 px-4 rounded-full border backdrop-blur-xl flex items-center gap-2 text-sm font-semibold ${
        active
          ? 'bg-brand-yellow text-white border-brand-yellow'
          : 'bg-white/15 text-white border-white/25'
      }`}
    >
      {children}
      <span>{label}</span>
    </motion.button>
  );
}

export function ScannerCameraControls({ controls, onToggleTorch, onToggleZoom }) {
  const hasControls = controls.torchSupported || controls.zoomSupported;

  return (
    <div className="flex flex-col items-center gap-3 px-4">
      {hasControls && (
        <div className="flex items-center justify-center gap-3">
          {controls.torchSupported && (
            <ControlButton
              active={controls.torchEnabled}
              label={controls.torchEnabled ? '补光开' : '补光'}
              onPointerDown={onToggleTorch}
            >
              <Flashlight size={17} />
            </ControlButton>
          )}
          {controls.zoomSupported && (
            <ControlButton
              active={controls.zoomEnabled}
              label={controls.zoomEnabled ? '放大中' : '放大'}
              onPointerDown={onToggleZoom}
            >
              {controls.zoomEnabled ? <ZoomOut size={17} /> : <ZoomIn size={17} />}
            </ControlButton>
          )}
        </div>
      )}
      <p className="max-w-[300px] text-center text-xs leading-5 text-white/75">
        二维码占满方框一半以上，轻微倾斜避开反光
      </p>
    </div>
  );
}
