import { useState, useEffect, useCallback, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ImageUp } from 'lucide-react';
import ScannerOverlay from '../components/Scanner/ScannerOverlay';
import DetailSheet from '../components/BottomSheet/DetailSheet';
import CheckoutForm from '../components/Forms/CheckoutForm';
import CheckoutDetail from '../components/Details/CheckoutDetail';
import RecordCard from '../components/Records/RecordCard';
import PullToRefresh from '../components/Shared/PullToRefresh';
import { getItemByCode, getCheckoutRecords, submitCheckout } from '../api/outbound';
import { showToast } from '../components/Shared/Toast';
import ScanFrameIcon from '../components/Shared/ScanFrameIcon';

export default function CheckoutTab({ showCostPrice = true }) {
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
      const scanner = new Html5Qrcode('checkout-file-scanner');
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
    const data = await getCheckoutRecords();
    const displayName = (() => {
      try {
        const user = JSON.parse(localStorage.getItem('currentUser') || '{}');
        const profile = user.profile || {};
        return profile.nickName || profile.user?.nickName || user.username || '未知';
      } catch { return '未知'; }
    })();
    setRecords(data.map(r => ({ ...r, operatorName: r.operatorName || displayName })));
  }, []);

  useEffect(() => { loadRecords(); }, [loadRecords]);

  const operatorName = (() => {
    try {
      const user = JSON.parse(localStorage.getItem('currentUser') || '{}');
      const profile = user.profile || {};
      return profile.nickName || profile.user?.nickName || user.username || '未知';
    } catch { return '未知'; }
  })();

  const handleScan = useCallback(async (code) => {
    try {
      const item = await getItemByCode(code);
      if (item) {
        if (item.stockQty <= 0) {
          setScannedItem(null);
          setFormError(`「${item.itemName}」库存数量为 0，无法出库`);
        } else {
          setScannedItem(item);
          setFormError('');
          setSubmitError('');
        }
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
      await submitCheckout(record);
      setScanning(false);
      showToast('出库成功');
      setScannedItem(null);
      setSubmitError('');
      await loadRecords();
    } catch (err) {
      setSubmitError(err.message || '提交失败');
    }
  };

  const handleRefresh = useCallback(async () => {
    setIsRefreshing(true);
    await loadRecords();
    setIsRefreshing(false);
  }, [loadRecords]);

  const sheetContent = scannedItem ? (
    <>
      <CheckoutForm
        item={scannedItem}
        operatorName={operatorName}
        showCostPrice={showCostPrice}
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
        <motion.div
          whileTap={{ scale: 0.97, transition: { duration: 0.1 } }}
          onPointerDown={() => { setScanning(true); setScannedItem(null); setFormError(''); }}
          className="w-full rounded-[20px] flex flex-col relative cursor-pointer"
          style={{ background: '#EDE2D5', padding: '20px' }}
        >
          <span
            className="relative z-10 self-start rounded-[10px] font-black italic"
            style={{ background: '#E8986E', color: '#FFFFFF', padding: '6px 14px', fontSize: '20px' }}
          >
            出库
          </span>
          <div
            className="absolute flex items-center justify-center"
            style={{ top: '50%', left: '50%', transform: 'translate(-50%, -50%)', width: '115px', height: '115px', background: '#E8986E', borderRadius: '16px' }}
          >
            <span className="text-white"><ScanFrameIcon size={91} animated /></span>
          </div>
          <div style={{ height: '120px' }} />
        </motion.div>
        <button
          onClick={() => fileInputRef.current?.click()}
          className="flex items-center gap-1.5 mx-auto mt-3 text-base text-text-secondary active:opacity-60"
        >
          <ImageUp size={16} />
          <span>从图片识别</span>
        </button>
        <input ref={fileInputRef} type="file" accept="image/*" hidden onChange={handleFileUpload} />
      </div>
      <div id="checkout-file-scanner" style={{ display: 'none' }} />

      <PullToRefresh
        onRefresh={handleRefresh}
        isRefreshing={isRefreshing}
        className="flex-1 overflow-y-auto hide-scrollbar"
      >
        <div className="px-5 pb-2 flex items-center gap-2.5">
          <div className="w-1 h-5 rounded-full bg-brand-yellow" />
          <h2 className="text-base font-bold text-text-primary">出库记录</h2>
        </div>
        {records.length === 0 ? (
          <p className="text-center text-text-secondary text-base py-8">暂无出库记录</p>
        ) : (
          <div className="px-5 flex flex-col" style={{ gap: '12px' }}>
            <AnimatePresence mode="popLayout">
              {records.map((record, idx) => (
                <RecordCard
                  key={record.id}
                  title={record.itemName}
                  detail={`${record.quantity} 件 · 成本 ¥${record.costPrice.toFixed(2)} · ${record.method}`}
                  status={record.status}
                  index={idx}
                  onClick={() => { setSelectedRecord(record); setShowDetail(true); }}
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
        sheetTitle={scannedItem ? '出库登记' : formError ? '提示' : ''}
        sheetContent={sheetContent}
        onSheetClose={() => { setScannedItem(null); setFormError(''); setSkipCamera(false); }}
      />

      <DetailSheet
        isOpen={showDetail}
        onClose={() => { setShowDetail(false); setSelectedRecord(null); }}
        title="出库详情"
      >
        {selectedRecord && <CheckoutDetail record={selectedRecord} showCostPrice={showCostPrice} />}
      </DetailSheet>
    </div>
  );
}
