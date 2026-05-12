import { useState, useEffect, useCallback, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ScanLine, ClipboardCheck, ImageUp } from 'lucide-react';
import ScannerOverlay from '../components/Scanner/ScannerOverlay';
import DetailSheet from '../components/BottomSheet/DetailSheet';
import InventoryCheckForm from '../components/Forms/InventoryCheckForm';
import InventoryCheckDetail from '../components/Details/InventoryCheckDetail';
import RecordCard from '../components/Records/RecordCard';
import PullToRefresh from '../components/Shared/PullToRefresh';
import { getItemByCode } from '../api/outbound';
import { getInventoryCheckRecords, submitInventoryCheck } from '../api/inventory';
import { showToast } from '../components/Shared/Toast';
import ScanFrameIcon from '../components/Shared/ScanFrameIcon';

export default function InventoryTab({ showCostPrice = true }) {
  const [scanning, setScanning] = useState(false);
  const [showDetail, setShowDetail] = useState(false);
  const [selectedRecord, setSelectedRecord] = useState(null);
  const [scannedItem, setScannedItem] = useState(null);
  const [records, setRecords] = useState([]);
  const [formError, setFormError] = useState('');
  const [submitError, setSubmitError] = useState('');
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [skipCamera, setSkipCamera] = useState(false);
  const fileInputRef = useRef(null);

  const handleFileUpload = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const { Html5Qrcode } = await import('html5-qrcode');
      const scanner = new Html5Qrcode('inventory-file-scanner');
      const code = await scanner.scanFile(file, false);
      scanner.clear();
      setSkipCamera(true);
      setScanning(true);
      await handleScan(code);
    } catch {
      setFormError('无法识别图片中的二维码');
    }
    e.target.value = '';
  };

  const loadRecords = useCallback(async () => {
    const data = await getInventoryCheckRecords();
    const name = (() => { try { return JSON.parse(localStorage.getItem('currentUser') || '{}').username || '未知'; } catch { return '未知'; } })();
    setRecords(data.map(r => ({ ...r, operatorName: r.operatorName || name })));
  }, []);

  useEffect(() => { loadRecords(); }, [loadRecords]);

  const operatorName = (() => {
    try { return JSON.parse(localStorage.getItem('currentUser') || '{}').username || '未知'; } catch { return '未知'; }
  })();

  const handleScan = useCallback(async (code) => {
    try {
      const item = await getItemByCode(code);
      if (item) {
        setScannedItem(item);
        setFormError('');
      } else {
        setScannedItem(null);
        setFormError('未找到该编号对应的库存货物');
      }
    } catch {
      setScannedItem(null);
      setFormError('查询失败，请检查网络连接');
    }
  }, []);

  const handleSubmit = async (record) => {
    try {
      await submitInventoryCheck(record);
      setScanning(false);
      showToast('盘点成功');
      setScannedItem(null);
      setSubmitError('');
      await loadRecords();
    } catch (err) {
      setSubmitError(err.message || '盘点提交失败');
    }
  };

  const handleRemoveRecord = useCallback((id) => {
    setRecords(prev => prev.filter(r => r.id !== id));
  }, []);

  const handleRefresh = useCallback(async () => {
    setIsRefreshing(true);
    await loadRecords();
    setIsRefreshing(false);
  }, [loadRecords]);

  const sheetContent = scannedItem ? (
    <>
      <InventoryCheckForm
        item={scannedItem}
        operatorName={operatorName}
        onSubmit={handleSubmit}
        onClose={() => { setScannedItem(null); setSubmitError(''); }}
      />
      {submitError && (
        <div className="mt-3 rounded-2xl bg-amber-50 px-4 py-3">
          <p className="text-sm text-amber-800">{submitError}</p>
        </div>
      )}
    </>
  ) : formError ? (
    <div className="text-center py-6">
      <p className="text-red-500 text-sm">{formError}</p>
    </div>
  ) : null;

  return (
    <div className="h-full flex flex-col bg-bg-main">
      <div className="px-5 pt-5 pb-4">
        <div
          className="w-full rounded-[20px] flex items-start"
          style={{ background: '#F5C842', padding: '20px', gap: '12px' }}
        >
          <div className="flex-1 min-w-0 flex flex-col items-start">
            <span
              className="rounded-[10px] font-black italic"
              style={{ background: '#1A1A1A', color: '#F5C842', padding: '6px 14px', fontSize: '20px' }}
            >
              扫码盘点
            </span>
            <motion.button
              whileTap={{ scale: 0.97, transition: { duration: 0.1 } }}
              onPointerDown={() => { setScanning(true); setScannedItem(null); setFormError(''); }}
              className="w-full mt-4 flex items-center justify-center rounded-[14px] text-white"
              style={{ background: '#1A1A1A', height: '52px', fontSize: '16px', fontWeight: 600, gap: '8px' }}
            >
              <span className="text-white"><ScanFrameIcon size={20} animated /></span>
              点击扫码盘点
            </motion.button>
          </div>
          <div
            className="shrink-0 flex items-center justify-center"
            style={{ width: '96px', height: '96px', background: 'rgba(0,0,0,0.12)', borderRadius: '16px' }}
          >
            <span className="text-white"><ScanFrameIcon size={48} animated /></span>
          </div>
        </div>
        <button
          onClick={() => fileInputRef.current?.click()}
          className="flex items-center gap-1.5 mx-auto mt-3 text-base text-text-secondary active:opacity-60"
        >
          <ImageUp size={16} />
          <span>从图片识别</span>
        </button>
        <input ref={fileInputRef} type="file" accept="image/*" hidden onChange={handleFileUpload} />
      </div>
      <div id="inventory-file-scanner" style={{ display: 'none' }} />

      <PullToRefresh
        onRefresh={handleRefresh}
        isRefreshing={isRefreshing}
        className="flex-1 overflow-y-auto hide-scrollbar"
      >
        <div className="px-5 pb-2 flex items-center gap-2.5">
          <div className="w-1 h-5 rounded-full bg-brand-yellow" />
          <h2 className="text-base font-bold text-text-primary">盘点记录</h2>
        </div>
        {records.length === 0 ? (
          <p className="text-center text-text-secondary text-base py-8">暂无盘点记录</p>
        ) : (
          <div className="px-5 flex flex-col" style={{ gap: '12px' }}>
            <AnimatePresence mode="popLayout">
              {records.map((record, idx) => (
                <RecordCard
                  key={record.id}
                  icon={ClipboardCheck}
                  badge={record.difference > 0 ? `+${record.difference}` : record.difference}
                  title={`${record.warehouse}  ${record.time.split(' ')[0]}`}
                  subtitle={record.itemName}
                  extra={`盘点数量：${record.actualQty}`}
                  status={record.status}
                  index={idx}
                  onClick={() => { setSelectedRecord(record); setShowDetail(true); }}
                  onSwipeLeft={() => handleRemoveRecord(record.id)}
                  onSwipeRight={() => handleRemoveRecord(record.id)}
                />
              ))}
            </AnimatePresence>
          </div>
        )}
      </PullToRefresh>

      <ScannerOverlay
        isOpen={scanning}
        skipCamera={skipCamera}
        onClose={() => { setScanning(false); setScannedItem(null); setFormError(''); setSkipCamera(false); }}
        onScanSuccess={handleScan}
        sheetTitle={scannedItem ? '盘点登记' : formError ? '提示' : ''}
        sheetContent={sheetContent}
        onSheetClose={() => { setScannedItem(null); setFormError(''); setSkipCamera(false); }}
      />

      <DetailSheet
        isOpen={showDetail}
        onClose={() => { setShowDetail(false); setSelectedRecord(null); }}
        title="盘点详情"
      >
        {selectedRecord && <InventoryCheckDetail record={selectedRecord} showCostPrice={showCostPrice} />}
      </DetailSheet>
    </div>
  );
}
