import { useEffect, useRef, useState, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X } from 'lucide-react';
import { Html5Qrcode } from 'html5-qrcode';

const SPRING = { type: 'spring', stiffness: 200, damping: 25, mass: 1 };

function playBeep() {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.value = 800;
    gain.gain.setValueAtTime(0.3, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.08);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start();
    osc.stop(ctx.currentTime + 0.08);
    setTimeout(() => ctx.close(), 200);
  } catch {}
}

export default function ScannerOverlay({ isOpen, onClose, onScanSuccess, sheetTitle, sheetContent, onSheetClose, skipCamera }) {
  const scannerRef = useRef(null);
  const [error, setError] = useState('');
  const [scanned, setScanned] = useState(false);
  const [showSheet, setShowSheet] = useState(false);
  const mountedRef = useRef(true);
  const scanningRef = useRef(false);
  const activeRef = useRef(true);
  const [sheetHeight, setSheetHeight] = useState(null);

  useEffect(() => {
    mountedRef.current = true;
    return () => { mountedRef.current = false; };
  }, []);

  // Show/hide sheet based on content
  useEffect(() => {
    if (!sheetContent && showSheet) {
      setShowSheet(false);
      setSheetHeight(null);
      const timer = setTimeout(() => {
        if (mountedRef.current) {
          setScanned(false);
          resumeScanning();
        }
      }, 350);
      return () => clearTimeout(timer);
    }
    if (sheetContent && !showSheet) {
      setSheetHeight(window.innerHeight * 0.85);
      setShowSheet(true);
    }
  }, [sheetContent]);

  // Lock sheet height against keyboard resize
  useEffect(() => {
    if (!showSheet || !sheetHeight) return;
    const vv = window.visualViewport;
    if (!vv) return;
    const onResize = () => {
      if (!mountedRef.current) return;
      const sheet = document.querySelector('[data-sheet-lock]');
      if (sheet) {
        sheet.style.maxHeight = sheetHeight + "px";
        sheet.style.top = vv.offsetTop + "px";
      }
    };
    vv.addEventListener("resize", onResize);
    vv.addEventListener("scroll", onResize);
    return () => {
      vv.removeEventListener("resize", onResize);
      vv.removeEventListener("scroll", onResize);
    };
  }, [showSheet, sheetHeight]);

  const resumeScanning = useCallback(() => {
    const scanner = scannerRef.current;
    if (!scanner) return;
    activeRef.current = true;
    scanningRef.current = false;
    try {
      scanner.resume?.();
    } catch {}
  }, []);

  useEffect(() => {
    if (!isOpen || skipCamera) return;

    let scanner = null;
    activeRef.current = true;
    setScanned(false);
    setShowSheet(false);
    setError('');
    scanningRef.current = false;

    const startScan = async () => {
      try {
        scanner = new Html5Qrcode('seamless-scanner');
        scannerRef.current = scanner;
        await scanner.start(
          { facingMode: 'environment' },
          { fps: 10, qrbox: { width: 320, height: 320 } },
          (decodedText) => {
            if (!activeRef.current || scanningRef.current) return;
            scanningRef.current = true;
            activeRef.current = false;
            setScanned(true);
            try { navigator.vibrate?.([100, 50, 100]); } catch {}
            playBeep();
            try { scanner.pause(true); } catch {}
            onScanSuccess?.(decodedText);
          },
          () => {}
        );
      } catch (err) {
        if (activeRef.current) {
          setError('无法访问摄像头，请检查权限设置');
          console.error('Scanner error:', err);
        }
      }
    };

    startScan();

    return () => {
      activeRef.current = false;
      scanningRef.current = false;
      if (scanner) {
        scanner.stop().catch(() => {});
      }
    };
  }, [isOpen]);

  const handleManualClose = useCallback(() => {
    setShowSheet(false);
    onSheetClose?.();
    onClose();
  }, [onClose, onSheetClose]);

  const handleSheetClose = useCallback(() => {
    setShowSheet(false);
    onSheetClose?.();
    const timer = setTimeout(() => {
      if (mountedRef.current) {
        setScanned(false);
        scanningRef.current = false;
        resumeScanning();
      }
    }, 350);
    return () => clearTimeout(timer);
  }, [onSheetClose, resumeScanning]);

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.2 }}
          className="fixed inset-0 bg-black/70 backdrop-blur-sm z-[60] flex flex-col"
        >
          {/* Camera view with blur on scan */}
          {!skipCamera && (
          <div className={`flex-1 relative transition-all duration-300 ${scanned ? 'blur-[5px] brightness-50' : ''}`}>
            <div className="flex-1 flex items-center justify-center h-full">
              {error ? (
                <div className="text-center text-white/80 px-8">
                  <p className="text-lg mb-2">{error}</p>
                  <button onPointerDown={onClose} className="mt-4 px-6 py-2 bg-white/20 rounded-full text-white">
                    关闭
                  </button>
                </div>
              ) : (
                <div className="relative">
                  <div id="seamless-scanner" className="w-80 h-80 rounded-2xl overflow-hidden" />
                  {/* L-shaped corner brackets */}
                  <div className="absolute inset-0 pointer-events-none">
                    <div className="absolute top-0 left-0 w-10 h-10">
                      <div style={{ position: 'absolute', top: 0, left: 0, width: 40, height: 6, background: '#D97757', borderRadius: 2 }} />
                      <div style={{ position: 'absolute', top: 0, left: 0, width: 6, height: 40, background: '#D97757', borderRadius: 2 }} />
                    </div>
                    <div className="absolute top-0 right-0 w-10 h-10">
                      <div style={{ position: 'absolute', top: 0, right: 0, width: 40, height: 6, background: '#D97757', borderRadius: 2 }} />
                      <div style={{ position: 'absolute', top: 0, right: 0, width: 6, height: 40, background: '#D97757', borderRadius: 2 }} />
                    </div>
                    <div className="absolute bottom-0 left-0 w-10 h-10">
                      <div style={{ position: 'absolute', bottom: 0, left: 0, width: 40, height: 6, background: '#D97757', borderRadius: 2 }} />
                      <div style={{ position: 'absolute', bottom: 0, left: 0, width: 6, height: 40, background: '#D97757', borderRadius: 2 }} />
                    </div>
                    <div className="absolute bottom-0 right-0 w-10 h-10">
                      <div style={{ position: 'absolute', bottom: 0, right: 0, width: 40, height: 6, background: '#D97757', borderRadius: 2 }} />
                      <div style={{ position: 'absolute', bottom: 0, right: 0, width: 6, height: 40, background: '#D97757', borderRadius: 2 }} />
                    </div>
                  </div>
                  {/* Animated scan line */}
                  {!scanned && (
                    <motion.div
                      className="absolute h-[2px]"
                      style={{
                        left: '10%',
                        right: '10%',
                        background: 'rgba(255, 60, 60, 0.8)',
                        boxShadow: '0 0 8px rgba(255,60,60,0.6), 0 0 20px rgba(255,60,60,0.3)',
                      }}
                      animate={{ top: ['0%', '95%', '0%'] }}
                      transition={{ duration: 1.2, repeat: Infinity, ease: 'easeInOut' }}
                    />
                  )}
                </div>
              )}
            </div>
          </div>
          )}

          {/* Exit button - frosted glass */}
          <button
            onPointerDown={handleManualClose}
            className="absolute top-4 left-4 px-4 py-2 rounded-full text-white text-sm font-semibold backdrop-blur-xl bg-white/15 border border-white/20 active:bg-white/25"
          >
            退出扫码
          </button>

          {/* Bottom sheet for form content */}
          <AnimatePresence>
            {showSheet && sheetContent && (
              <>
                <motion.div
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 0.3 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 0.2 }}
                  className="absolute inset-0 bg-black"
                  onPointerDown={handleSheetClose}
                />
                <motion.div
                  initial={{ y: '-100%' }}
                  animate={{ y: 0 }}
                  exit={{ y: '-100%' }}
                  transition={SPRING}
                  drag="y"
                  dragConstraints={{ bottom: 0 }}
                  dragElastic={0.15}
                  onDragEnd={(_, info) => {
                    if (info.offset.y < -150 || info.velocity.y < -500) handleSheetClose();
                  }}
                  className="absolute top-0 left-0 right-0 bg-white rounded-b-3xl flex flex-col" data-sheet-lock style={{ maxHeight: sheetHeight ? sheetHeight + "px" : "85vh" }}
                >
                  <div className="flex flex-col items-center pt-3 pb-2 border-b border-gray-100 shrink-0">
                    <div className="w-10 h-1 rounded-full bg-gray-300 mb-3" />
                    <div className="flex items-center justify-between w-full px-5">
                      <h2 className="text-lg font-bold text-text-primary">{sheetTitle}</h2>
                      <button onPointerDown={handleSheetClose} className="p-1 -mr-1 active:bg-gray-100 rounded-full">
                        <X size={20} className="text-text-secondary" />
                      </button>
                    </div>
                  </div>
                  <div className="overflow-y-auto hide-scrollbar px-5 py-4">
                    {sheetContent}
                  </div>
                </motion.div>
              </>
            )}
          </AnimatePresence>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
