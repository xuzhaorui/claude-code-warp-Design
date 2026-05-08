import { useEffect, useRef, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X } from 'lucide-react';
import { Html5Qrcode } from 'html5-qrcode';

export default function ScannerOverlay({ isOpen, onClose, onScanSuccess }) {
  const scannerRef = useRef(null);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!isOpen) return;

    let scanner = null;
    let mounted = true;

    const startScan = async () => {
      try {
        scanner = new Html5Qrcode('scanner-container');
        scannerRef.current = scanner;
        await scanner.start(
          { facingMode: 'environment' },
          { fps: 10, qrbox: { width: 250, height: 250 } },
          (decodedText) => {
            if (mounted) {
              scanner.stop().catch(() => {});
              onScanSuccess(decodedText);
            }
          },
          () => {}
        );
      } catch (err) {
        if (mounted) {
          setError('无法访问摄像头，请检查权限设置');
          console.error('Scanner error:', err);
        }
      }
    };

    startScan();

    return () => {
      mounted = false;
      if (scanner) {
        scanner.stop().catch(() => {});
      }
    };
  }, [isOpen, onScanSuccess]);

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.2 }}
          className="fixed inset-0 bg-black z-[60] flex flex-col"
        >
          <div className="flex justify-between items-center p-4 text-white">
            <span className="font-semibold">扫码识别</span>
            <button onClick={onClose} className="p-2 active:bg-white/10 rounded-full">
              <X size={24} />
            </button>
          </div>

          <div className="flex-1 flex items-center justify-center relative">
            {error ? (
              <div className="text-center text-white/80 px-8">
                <p className="text-lg mb-2">{error}</p>
                <button
                  onClick={onClose}
                  className="mt-4 px-6 py-2 bg-white/20 rounded-full text-white"
                >
                  关闭
                </button>
              </div>
            ) : (
              <div className="relative">
                <div id="scanner-container" className="w-64 h-64 rounded-2xl overflow-hidden" />
                <div className="absolute inset-0 pointer-events-none">
                  <div className="absolute top-0 left-0 w-8 h-8 border-t-2 border-l-2 border-brand-yellow rounded-tl-lg" />
                  <div className="absolute top-0 right-0 w-8 h-8 border-t-2 border-r-2 border-brand-yellow rounded-tr-lg" />
                  <div className="absolute bottom-0 left-0 w-8 h-8 border-b-2 border-l-2 border-brand-yellow rounded-bl-lg" />
                  <div className="absolute bottom-0 right-0 w-8 h-8 border-b-2 border-r-2 border-brand-yellow rounded-br-lg" />
                  <div
                    className="absolute left-2 right-2 h-0.5 bg-brand-yellow/70"
                    style={{ animation: 'scan-line 2s linear infinite' }}
                  />
                </div>
              </div>
            )}
          </div>

          <div className="text-center text-white/60 pb-8 text-sm">
            将二维码对准扫描框
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
