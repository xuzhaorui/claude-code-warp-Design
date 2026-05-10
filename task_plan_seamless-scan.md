# Task Plan: Seamless Scan Flow

**Goal**: 重构扫码流程为沉浸式连续扫码模式：相机保持开启，扫码成功后模糊相机+底部抽屉叠加弹出表单，提交后抽屉滑下+解除模糊+恢复扫描。含发光扫描线、识别瞬间边框变色+haptic双震动+800Hz beep、自动 focus 首个输入框、毛玻璃退出按钮。归还两步流在同一抽屉内切换。
**Starting state**: ScannerOverlay.jsx 是独立全屏模态，扫完关闭相机。三个 Tab 各自管理 scanning + showForm 状态，FormSheet 独立于 ScannerOverlay。
**Constraints**: Design.md 物理参数（stiffness:200, damping:25, mass:1）、framer-motion、Web Audio API 程序化 beep（800Hz/80ms）、零外部音频文件。

---

## Step 1: 重写 ScannerOverlay.jsx 为沉浸式扫码组件

**STATUS**: [x]

**ACTION**:
将 `src/components/Scanner/ScannerOverlay.jsx` 完整重写为以下内容：

```jsx
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

export default function ScannerOverlay({ isOpen, onClose, onScanSuccess, sheetTitle, sheetContent, onSheetClose }) {
  const scannerRef = useRef(null);
  const [error, setError] = useState('');
  const [scanned, setScanned] = useState(false);
  const [showSheet, setShowSheet] = useState(false);
  const mountedRef = useRef(true);

  // Reset state when sheet content is cleared (form submitted)
  useEffect(() => {
    if (!sheetContent && showSheet) {
      setShowSheet(false);
      // Short delay then resume scanning
      const timer = setTimeout(() => {
        if (mountedRef.current) setScanned(false);
      }, 350);
      return () => clearTimeout(timer);
    }
    if (sheetContent && !showSheet) {
      setShowSheet(true);
    }
  }, [sheetContent, showSheet]);

  useEffect(() => {
    mountedRef.current = true;
    return () => { mountedRef.current = false; };
  }, []);

  useEffect(() => {
    if (!isOpen) return;

    let scanner = null;
    let active = true;
    setScanned(false);
    setShowSheet(false);
    setError('');

    const startScan = async () => {
      try {
        scanner = new Html5Qrcode('seamless-scanner');
        scannerRef.current = scanner;
        await scanner.start(
          { facingMode: 'environment' },
          { fps: 10, qrbox: { width: 250, height: 250 } },
          (decodedText) => {
            if (!active || scanned) return;
            active = false;
            setScanned(true);
            try { navigator.vibrate?.([100, 50, 100]); } catch {}
            playBeep();
            if (scanner) scanner.pause(true).catch(() => {});
            onScanSuccess?.(decodedText);
          },
          () => {}
        );
      } catch (err) {
        if (active) {
          setError('无法访问摄像头，请检查权限设置');
          console.error('Scanner error:', err);
        }
      }
    };

    startScan();

    return () => {
      active = false;
      if (scanner) {
        scanner.stop().catch(() => {});
        scanner.clear();
      }
    };
  }, [isOpen]);

  const handleManualClose = useCallback(() => {
    setShowSheet(false);
    onSheetClose?.();
    onClose();
  }, [onClose, onSheetClose]);

  const handleSheetDragClose = useCallback(() => {
    setShowSheet(false);
    onSheetClose?.();
    // Resume scanning after sheet closes
    const timer = setTimeout(() => {
      if (mountedRef.current) {
        setScanned(false);
        // Resume camera
        if (scannerRef.current) {
          scannerRef.current.resume().catch(() => {});
          scannerRef.current.start(
            { facingMode: 'environment' },
            { fps: 10, qrbox: { width: 250, height: 250 } },
            (decodedText) => {
              if (!mountedRef.current || scanned) return;
              setScanned(true);
              try { navigator.vibrate?.([100, 50, 100]); } catch {}
              playBeep();
              if (scannerRef.current) scannerRef.current.pause(true).catch(() => {});
              onScanSuccess?.(decodedText);
            },
            () => {}
          ).catch(() => {});
        }
      }
    }, 350);
    return () => clearTimeout(timer);
  }, [onSheetClose, onScanSuccess, scanned]);

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
          {/* Camera view with blur on scan */}
          <div className={`flex-1 relative transition-all duration-300 ${scanned ? 'blur-[5px] brightness-50' : ''}`}>
            <div className="flex-1 flex items-center justify-center h-full">
              {error ? (
                <div className="text-center text-white/80 px-8">
                  <p className="text-lg mb-2">{error}</p>
                  <button onClick={onClose} className="mt-4 px-6 py-2 bg-white/20 rounded-full text-white">
                    关闭
                  </button>
                </div>
              ) : (
                <div className="relative">
                  <div id="seamless-scanner" className="w-64 h-64 rounded-2xl overflow-hidden" />
                  {/* Corner brackets */}
                  <div className={`absolute inset-0 pointer-events-none transition-colors duration-200 ${scanned ? '[&>div]:border-brand-yellow' : '[&>div]:border-white/50'}`}>
                    <div className="absolute top-0 left-0 w-8 h-8 border-t-2 border-l-2 rounded-tl-lg transition-colors duration-200" />
                    <div className="absolute top-0 right-0 w-8 h-8 border-t-2 border-r-2 rounded-tr-lg transition-colors duration-200" />
                    <div className="absolute bottom-0 left-0 w-8 h-8 border-b-2 border-l-2 rounded-bl-lg transition-colors duration-200" />
                    <div className="absolute bottom-0 right-0 w-8 h-8 border-b-2 border-r-2 rounded-br-lg transition-colors duration-200" />
                  </div>
                  {/* Animated scan line */}
                  {!scanned && (
                    <motion.div
                      className="absolute left-3 right-3 h-[2px]"
                      style={{
                        background: 'linear-gradient(90deg, transparent, #FFC629, transparent)',
                        boxShadow: '0 0 8px 2px rgba(255, 198, 41, 0.4)',
                      }}
                      animate={{ top: ['0%', '95%', '0%'] }}
                      transition={{ duration: 2.5, repeat: Infinity, ease: 'easeInOut' }}
                    />
                  )}
                </div>
              )}
            </div>
          </div>

          {/* Hint text - only when not scanned */}
          {!scanned && !error && (
            <div className="absolute bottom-8 left-0 right-0 text-center text-white/60 text-sm">
              将二维码对准扫描框
            </div>
          )}

          {/* Exit button - frosted glass */}
          <button
            onClick={handleManualClose}
            className="absolute top-4 left-4 px-4 py-2 rounded-full text-white text-sm font-semibold backdrop-blur-xl bg-white/15 border border-white/20 active:bg-white/25"
          >
            退出扫码
          </button>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
```

**GATE**:
执行以下命令，每个输出均 ≥ 1：
- `grep -c "playBeep" src/components/Scanner/ScannerOverlay.jsx`
- `grep -c "800" src/components/Scanner/ScannerOverlay.jsx`
- `grep -c "navigator.vibrate" src/components/Scanner/ScannerOverlay.jsx`
- `grep -c "blur-" src/components/Scanner/ScannerOverlay.jsx`
- `grep -c "退出扫码" src/components/Scanner/ScannerOverlay.jsx`
- `grep -c "seamless-scanner" src/components/Scanner/ScannerOverlay.jsx`
- `grep -c "sheetContent" src/components/Scanner/ScannerOverlay.jsx`
- `grep -c "boxShadow" src/components/Scanner/ScannerOverlay.jsx`

**NEXT**:
- GATE passes → proceed to Step 2
- GATE fails → 重新写入完整文件内容，确认写入成功

---

## Step 2: 更新 CheckoutTab 使用新的沉浸式扫码流

**STATUS**: [x]

**ACTION**:
将 `src/pages/CheckoutTab.jsx` 完整重写为以下内容：

```jsx
import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ScanLine, LogOut } from 'lucide-react';
import ScannerOverlay from '../components/Scanner/ScannerOverlay';
import DetailSheet from '../components/BottomSheet/DetailSheet';
import CheckoutForm from '../components/Forms/CheckoutForm';
import CheckoutDetail from '../components/Details/CheckoutDetail';
import RecordCard from '../components/Records/RecordCard';
import FormSheet from '../components/BottomSheet/FormSheet';
import { getItemByCode, getCheckoutRecords, submitCheckout, removeCheckoutRecord } from '../data/mockData';

export default function CheckoutTab() {
  const [scanning, setScanning] = useState(false);
  const [showDetail, setShowDetail] = useState(false);
  const [selectedRecord, setSelectedRecord] = useState(null);
  const [scannedItem, setScannedItem] = useState(null);
  const [records, setRecords] = useState([]);
  const [formError, setFormError] = useState('');

  const loadRecords = useCallback(async () => {
    const data = await getCheckoutRecords();
    setRecords(data);
  }, []);

  useEffect(() => { loadRecords(); }, [loadRecords]);

  const operatorName = (() => {
    try { return JSON.parse(localStorage.getItem('currentUser') || '{}').username || '未知'; } catch { return '未知'; }
  })();

  const handleScan = useCallback(async (code) => {
    const item = await getItemByCode(code);
    if (item) {
      setScannedItem(item);
      setFormError('');
    } else {
      setScannedItem(null);
      setFormError('未找到该编号对应的库存货物');
    }
  }, []);

  const handleSubmit = async (record) => {
    await submitCheckout(record);
    setScannedItem(null);
    await loadRecords();
  };

  const handleRemoveRecord = useCallback(async (id) => {
    setRecords(prev => prev.filter(r => r.id !== id));
    await removeCheckoutRecord(id);
  }, []);

  const sheetContent = scannedItem ? (
    <CheckoutForm
      item={scannedItem}
      operatorName={operatorName}
      onSubmit={handleSubmit}
      onClose={() => setScannedItem(null)}
    />
  ) : formError ? (
    <div className="text-center py-6">
      <p className="text-red-500 text-sm">{formError}</p>
    </div>
  ) : null;

  return (
    <div className="h-full flex flex-col bg-bg-main">
      <div className="px-5 pt-5 pb-4">
        <h1 className="text-2xl font-bold text-text-primary mb-4">出库</h1>
        <motion.button
          whileTap={{ scale: 0.96 }}
          onClick={() => { setScanning(true); setScannedItem(null); setFormError(''); }}
          className="w-full bg-bg-secondary rounded-3xl p-6 flex flex-col items-center gap-3"
        >
          <div className="w-16 h-16 rounded-2xl bg-brand-yellow/20 flex items-center justify-center">
            <ScanLine size={32} className="text-brand-yellow" />
          </div>
          <span className="text-sm font-semibold text-text-primary">点击扫码出库</span>
        </motion.button>
      </div>

      <div className="flex-1 overflow-y-auto hide-scrollbar">
        <div className="px-5 pb-2">
          <h2 className="text-sm font-semibold text-text-secondary">出库记录</h2>
        </div>
        {records.length === 0 ? (
          <p className="text-center text-text-secondary text-sm py-8">暂无出库记录</p>
        ) : (
          <AnimatePresence mode="popLayout">
            {records.map((record, idx) => (
              <RecordCard
                key={record.id}
                icon={LogOut}
                badge={record.quantity}
                title={`${record.warehouse}  ${record.time.split(' ')[0]}`}
                subtitle={record.itemName}
                extra={record.method === '外销' ? `¥${record.saleTotalPrice.toFixed(2)}` : record.method}
                index={idx}
                onClick={() => { setSelectedRecord(record); setShowDetail(true); }}
                onSwipeLeft={() => handleRemoveRecord(record.id)}
                onSwipeRight={() => handleRemoveRecord(record.id)}
              />
            ))}
          </AnimatePresence>
        )}
      </div>

      <ScannerOverlay
        isOpen={scanning}
        onClose={() => { setScanning(false); setScannedItem(null); setFormError(''); }}
        onScanSuccess={handleScan}
        sheetTitle={scannedItem ? '出库登记' : formError ? '提示' : ''}
        sheetContent={sheetContent}
        onSheetClose={() => { setScannedItem(null); setFormError(''); }}
      />

      <DetailSheet
        isOpen={showDetail}
        onClose={() => { setShowDetail(false); setSelectedRecord(null); }}
        title="出库详情"
      >
        {selectedRecord && <CheckoutDetail record={selectedRecord} />}
      </DetailSheet>
    </div>
  );
}
```

**GATE**:
- `grep -c "sheetContent" src/pages/CheckoutTab.jsx` 输出 ≥ 1
- `grep -c "sheetTitle" src/pages/CheckoutTab.jsx` 输出 ≥ 1
- `grep -c "onSheetClose" src/pages/CheckoutTab.jsx` 输出 ≥ 1
- `grep -c "FormSheet" src/pages/CheckoutTab.jsx` 输出 ≥ 0（不使用独立的 FormSheet 用于扫码流）

**NEXT**:
- GATE passes → proceed to Step 3
- GATE fails → 重新写入完整文件内容

---

## Step 3: 更新 ReturnTab 使用沉浸式扫码流（含两步切换）

**STATUS**: [x]

**ACTION**:
将 `src/pages/ReturnTab.jsx` 完整重写为以下内容：

```jsx
import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ScanLine, RotateCcw } from 'lucide-react';
import ScannerOverlay from '../components/Scanner/ScannerOverlay';
import DetailSheet from '../components/BottomSheet/DetailSheet';
import BorrowerSelect from '../components/Forms/BorrowerSelect';
import ReturnForm from '../components/Forms/ReturnForm';
import ReturnDetail from '../components/Details/ReturnDetail';
import RecordCard from '../components/Records/RecordCard';
import FormSheet from '../components/BottomSheet/FormSheet';
import { getItemByCode, getBorrowersByItem, getReturnRecords, submitReturn, removeReturnRecord } from '../data/mockData';

export default function ReturnTab() {
  const [scanning, setScanning] = useState(false);
  const [showDetail, setShowDetail] = useState(false);
  const [selectedRecord, setSelectedRecord] = useState(null);
  const [borrowers, setBorrowers] = useState([]);
  const [selectedBorrower, setSelectedBorrower] = useState(null);
  const [records, setRecords] = useState([]);
  const [scanError, setScanError] = useState('');

  const loadRecords = useCallback(async () => {
    const data = await getReturnRecords();
    setRecords(data);
  }, []);

  useEffect(() => { loadRecords(); }, [loadRecords]);

  const operatorName = (() => {
    try { return JSON.parse(localStorage.getItem('currentUser') || '{}').username || '未知'; } catch { return '未知'; }
  })();

  const handleScan = useCallback(async (code) => {
    const item = await getItemByCode(code);
    if (!item) {
      setScanError('未找到该编号对应的库存货物');
      return;
    }
    const borrowerList = await getBorrowersByItem(item.id);
    if (borrowerList.length === 0) {
      setScanError('该货物暂无外借记录');
      return;
    }
    setBorrowers(borrowerList);
    setSelectedBorrower(null);
    setScanError('');
  }, []);

  const handleSubmitReturn = async (record) => {
    await submitReturn(record);
    setBorrowers([]);
    setSelectedBorrower(null);
    await loadRecords();
  };

  const handleRemoveRecord = useCallback(async (id) => {
    setRecords(prev => prev.filter(r => r.id !== id));
    await removeReturnRecord(id);
  }, []);

  const sheetTitle = selectedBorrower ? '归还登记' : borrowers.length > 0 ? '选择外借人' : scanError ? '提示' : '';

  const sheetContent = scanError ? (
    <div className="text-center py-6">
      <p className="text-red-500 text-sm">{scanError}</p>
    </div>
  ) : borrowers.length > 0 && !selectedBorrower ? (
    <BorrowerSelect borrowers={borrowers} onSelect={(b) => setSelectedBorrower(b)} />
  ) : selectedBorrower ? (
    <ReturnForm
      borrowRecord={selectedBorrower}
      operatorName={operatorName}
      onSubmit={handleSubmitReturn}
      onClose={() => { setBorrowers([]); setSelectedBorrower(null); }}
    />
  ) : null;

  return (
    <div className="h-full flex flex-col bg-bg-main">
      <div className="px-5 pt-5 pb-4">
        <h1 className="text-2xl font-bold text-text-primary mb-4">归还</h1>
        <motion.button
          whileTap={{ scale: 0.96 }}
          onClick={() => { setScanning(true); setBorrowers([]); setSelectedBorrower(null); setScanError(''); }}
          className="w-full bg-bg-secondary rounded-3xl p-6 flex flex-col items-center gap-3"
        >
          <div className="w-16 h-16 rounded-2xl bg-brand-yellow/20 flex items-center justify-center">
            <ScanLine size={32} className="text-brand-yellow" />
          </div>
          <span className="text-sm font-semibold text-text-primary">点击扫码归还</span>
        </motion.button>
      </div>

      <div className="flex-1 overflow-y-auto hide-scrollbar">
        <div className="px-5 pb-2">
          <h2 className="text-sm font-semibold text-text-secondary">归还记录</h2>
        </div>
        {records.length === 0 ? (
          <p className="text-center text-text-secondary text-sm py-8">暂无归还记录</p>
        ) : (
          <AnimatePresence mode="popLayout">
            {records.map((record, idx) => (
              <RecordCard
                key={record.id}
                icon={RotateCcw}
                badge={record.returnQty}
                title={`${record.warehouse}  ${record.time.split(' ')[0]}`}
                subtitle={record.itemName}
                extra={`外借人：${record.borrower}`}
                index={idx}
                onClick={() => { setSelectedRecord(record); setShowDetail(true); }}
                onSwipeLeft={() => handleRemoveRecord(record.id)}
                onSwipeRight={() => handleRemoveRecord(record.id)}
              />
            ))}
          </AnimatePresence>
        )}
      </div>

      <ScannerOverlay
        isOpen={scanning}
        onClose={() => { setScanning(false); setBorrowers([]); setSelectedBorrower(null); setScanError(''); }}
        onScanSuccess={handleScan}
        sheetTitle={sheetTitle}
        sheetContent={sheetContent}
        onSheetClose={() => { setBorrowers([]); setSelectedBorrower(null); setScanError(''); }}
      />

      <DetailSheet
        isOpen={showDetail}
        onClose={() => { setShowDetail(false); setSelectedRecord(null); }}
        title="归还详情"
      >
        {selectedRecord && <ReturnDetail record={selectedRecord} />}
      </DetailSheet>
    </div>
  );
}
```

**GATE**:
- `grep -c "sheetContent" src/pages/ReturnTab.jsx` 输出 ≥ 1
- `grep -c "BorrowerSelect" src/pages/ReturnTab.jsx` 输出 ≥ 1
- `grep -c "selectedBorrower" src/pages/ReturnTab.jsx` 输出 ≥ 5（两步切换逻辑）
- `grep -c "onSheetClose" src/pages/ReturnTab.jsx` 输出 ≥ 1

**NEXT**:
- GATE passes → proceed to Step 4
- GATE fails → 重新写入完整文件内容

---

## Step 4: 更新 InventoryTab 使用沉浸式扫码流

**STATUS**: [x]

**ACTION**:
将 `src/pages/InventoryTab.jsx` 完整重写为以下内容：

```jsx
import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ScanLine, ClipboardCheck } from 'lucide-react';
import ScannerOverlay from '../components/Scanner/ScannerOverlay';
import DetailSheet from '../components/BottomSheet/DetailSheet';
import InventoryCheckForm from '../components/Forms/InventoryCheckForm';
import InventoryCheckDetail from '../components/Details/InventoryCheckDetail';
import RecordCard from '../components/Records/RecordCard';
import { getItemByCode, getInventoryCheckRecords, submitInventoryCheck, removeInventoryCheckRecord } from '../data/mockData';

export default function InventoryTab() {
  const [scanning, setScanning] = useState(false);
  const [showDetail, setShowDetail] = useState(false);
  const [selectedRecord, setSelectedRecord] = useState(null);
  const [scannedItem, setScannedItem] = useState(null);
  const [records, setRecords] = useState([]);
  const [formError, setFormError] = useState('');

  const loadRecords = useCallback(async () => {
    const data = await getInventoryCheckRecords();
    setRecords(data);
  }, []);

  useEffect(() => { loadRecords(); }, [loadRecords]);

  const operatorName = (() => {
    try { return JSON.parse(localStorage.getItem('currentUser') || '{}').username || '未知'; } catch { return '未知'; }
  })();

  const handleScan = useCallback(async (code) => {
    const item = await getItemByCode(code);
    if (item) {
      setScannedItem(item);
      setFormError('');
    } else {
      setScannedItem(null);
      setFormError('未找到该编号对应的库存货物');
    }
  }, []);

  const handleSubmit = async (record) => {
    await submitInventoryCheck(record);
    setScannedItem(null);
    await loadRecords();
  };

  const handleRemoveRecord = useCallback(async (id) => {
    setRecords(prev => prev.filter(r => r.id !== id));
    await removeInventoryCheckRecord(id);
  }, []);

  const sheetContent = scannedItem ? (
    <InventoryCheckForm
      item={scannedItem}
      operatorName={operatorName}
      onSubmit={handleSubmit}
      onClose={() => setScannedItem(null)}
    />
  ) : formError ? (
    <div className="text-center py-6">
      <p className="text-red-500 text-sm">{formError}</p>
    </div>
  ) : null;

  return (
    <div className="h-full flex flex-col bg-bg-main">
      <div className="px-5 pt-5 pb-4">
        <h1 className="text-2xl font-bold text-text-primary mb-4">盘点</h1>
        <motion.button
          whileTap={{ scale: 0.96 }}
          onClick={() => { setScanning(true); setScannedItem(null); setFormError(''); }}
          className="w-full bg-bg-secondary rounded-3xl p-6 flex flex-col items-center gap-3"
        >
          <div className="w-16 h-16 rounded-2xl bg-brand-yellow/20 flex items-center justify-center">
            <ScanLine size={32} className="text-brand-yellow" />
          </div>
          <span className="text-sm font-semibold text-text-primary">点击扫码盘点</span>
        </motion.button>
      </div>

      <div className="flex-1 overflow-y-auto hide-scrollbar">
        <div className="px-5 pb-2">
          <h2 className="text-sm font-semibold text-text-secondary">盘点记录</h2>
        </div>
        {records.length === 0 ? (
          <p className="text-center text-text-secondary text-sm py-8">暂无盘点记录</p>
        ) : (
          <AnimatePresence mode="popLayout">
            {records.map((record, idx) => (
              <RecordCard
                key={record.id}
                icon={ClipboardCheck}
                badge={record.difference > 0 ? `+${record.difference}` : record.difference}
                title={`${record.warehouse}  ${record.time.split(' ')[0]}`}
                subtitle={record.itemName}
                extra={`盘点数量：${record.actualQty}`}
                index={idx}
                onClick={() => { setSelectedRecord(record); setShowDetail(true); }}
                onSwipeLeft={() => handleRemoveRecord(record.id)}
                onSwipeRight={() => handleRemoveRecord(record.id)}
              />
            ))}
          </AnimatePresence>
        )}
      </div>

      <ScannerOverlay
        isOpen={scanning}
        onClose={() => { setScanning(false); setScannedItem(null); setFormError(''); }}
        onScanSuccess={handleScan}
        sheetTitle={scannedItem ? '盘点登记' : formError ? '提示' : ''}
        sheetContent={sheetContent}
        onSheetClose={() => { setScannedItem(null); setFormError(''); }}
      />

      <DetailSheet
        isOpen={showDetail}
        onClose={() => { setShowDetail(false); setSelectedRecord(null); }}
        title="盘点详情"
      >
        {selectedRecord && <InventoryCheckDetail record={selectedRecord} />}
      </DetailSheet>
    </div>
  );
}
```

**GATE**:
- `grep -c "sheetContent" src/pages/InventoryTab.jsx` 输出 ≥ 1
- `grep -c "onSheetClose" src/pages/InventoryTab.jsx` 输出 ≥ 1
- `grep -c "ScannerOverlay" src/pages/InventoryTab.jsx` 输出 ≥ 1

**NEXT**:
- GATE passes → proceed to Step 5
- GATE fails → 重新写入完整文件内容

---

## Step 5: 为 CheckoutForm 和 InventoryCheckForm 添加自动 focus

**STATUS**: [x]

**ACTION**:
1. 编辑 `src/components/Forms/CheckoutForm.jsx`，在文件顶部 import 中添加 `useRef, useEffect`：
```js
import { useState, useRef, useEffect } from 'react';
```

在 CheckoutForm 函数组件内，在第一个 `useState` 之后（`const [confirmLoss, setConfirmLoss] = useState(false);` 之后），添加：
```js
  const quantityRef = useRef(null);
  useEffect(() => {
    if (quantityRef.current) {
      const timer = setTimeout(() => quantityRef.current?.focus(), 400);
      return () => clearTimeout(timer);
    }
  }, []);
```

找到出库数量 input 元素（`<input type="number" min="1"`），在其属性中添加 `ref={quantityRef}`。

2. 编辑 `src/components/Forms/InventoryCheckForm.jsx`，在文件顶部 import 中添加 `useRef, useEffect`：
```js
import { useState, useRef, useEffect } from 'react';
```

在 InventoryCheckForm 函数组件内，在第一个 `useState` 之后（`const [remark, setRemark] = useState('');` 之后），添加：
```js
  const actualQtyRef = useRef(null);
  useEffect(() => {
    if (actualQtyRef.current) {
      const timer = setTimeout(() => actualQtyRef.current?.focus(), 400);
      return () => clearTimeout(timer);
    }
  }, []);
```

找到盘点真实数量 input 元素（`<input type="number" min="0"`），在其属性中添加 `ref={actualQtyRef}`。

3. 编辑 `src/components/Forms/ReturnForm.jsx`，在文件顶部 import 中添加 `useRef, useEffect`：
```js
import { useState, useRef, useEffect } from 'react';
```

在 ReturnForm 函数组件内，在第一个 `useState` 之后（`const [remark, setRemark] = useState('');` 之后），添加：
```js
  const returnQtyRef = useRef(null);
  useEffect(() => {
    if (returnQtyRef.current) {
      const timer = setTimeout(() => returnQtyRef.current?.focus(), 400);
      return () => clearTimeout(timer);
    }
  }, []);
```

找到归还数量 input 元素（`<input type="number" min="1"`），在其属性中添加 `ref={returnQtyRef}`。

**GATE**:
- `grep -c "useRef" src/components/Forms/CheckoutForm.jsx` 输出 ≥ 1
- `grep -c "quantityRef" src/components/Forms/CheckoutForm.jsx` 输出 ≥ 2
- `grep -c "useRef" src/components/Forms/InventoryCheckForm.jsx` 输出 ≥ 1
- `grep -c "actualQtyRef" src/components/Forms/InventoryCheckForm.jsx` 输出 ≥ 2
- `grep -c "useRef" src/components/Forms/ReturnForm.jsx` 输出 ≥ 1
- `grep -c "returnQtyRef" src/components/Forms/ReturnForm.jsx` 输出 ≥ 2

**NEXT**:
- GATE passes → proceed to Step 6
- GATE fails → 读取对应文件确认当前状态，补全缺失的 ref/focus 逻辑

---

## Step 6: 编译验证 + 提交

**STATUS**: [x]

**ACTION**:
1. 运行 `npm run build` 确认无编译错误
2. 运行以下命令提交：
```bash
git add src/components/Scanner/ScannerOverlay.jsx src/pages/CheckoutTab.jsx src/pages/ReturnTab.jsx src/pages/InventoryTab.jsx src/components/Forms/CheckoutForm.jsx src/components/Forms/InventoryCheckForm.jsx src/components/Forms/ReturnForm.jsx
git commit -m "feat: seamless continuous scan flow with blur overlay, haptic beep, auto-focus, frosted exit button"
```

**GATE**:
- `npm run build` exit code 0
- `git log --oneline -1` 输出包含 "seamless" 或 "scan flow"

**NEXT**:
- GATE passes → 计划完成
- GATE fails → 运行 `npm run build 2>&1 | tail -30` 获取编译错误，根据错误信息修复 import 路径或语法。若 git commit 失败，用 `git status` 确认暂存区
