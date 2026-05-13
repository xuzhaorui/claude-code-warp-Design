import { useState, useEffect, useCallback, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { RotateCcw, ImageUp } from 'lucide-react';
import ScannerOverlay from '../components/Scanner/ScannerOverlay';
import DetailSheet from '../components/BottomSheet/DetailSheet';
import BorrowerSelect from '../components/Forms/BorrowerSelect';
import ReturnForm from '../components/Forms/ReturnForm';
import ReturnDetail from '../components/Details/ReturnDetail';
import RecordCard from '../components/Records/RecordCard';
import PullToRefresh from '../components/Shared/PullToRefresh';
import { getBorrowersByQrcode, getReturnRecords, submitReturn } from '../api/return';
import { showToast } from '../components/Shared/Toast';
import ScanFrameIcon from '../components/Shared/ScanFrameIcon';

export default function ReturnTab({ showCostPrice = true }) {
  const [scanning, setScanning] = useState(false);
  const [showDetail, setShowDetail] = useState(false);
  const [selectedRecord, setSelectedRecord] = useState(null);
  const [borrowers, setBorrowers] = useState([]);
  const [selectedBorrower, setSelectedBorrower] = useState(null);
  const [records, setRecords] = useState([]);
  const [scanError, setScanError] = useState('');
  const [submitError, setSubmitError] = useState('');
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [skipCamera, setSkipCamera] = useState(false);
  const fileInputRef = useRef(null);

  const handleFileUpload = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const { Html5Qrcode } = await import('html5-qrcode');
      const scanner = new Html5Qrcode('return-file-scanner');
      const code = await scanner.scanFile(file, false);
      scanner.clear();
      setSkipCamera(true);
      setScanning(true);
      await handleScan(code);
    } catch {
      setScanError('无法识别图片中的二维码');
    }
    e.target.value = '';
  };

  const loadRecords = useCallback(async () => {
    const data = await getReturnRecords();
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
      const borrowerList = await getBorrowersByQrcode(code);
      if (borrowerList.length === 0) {
        setScanError('该货物暂无外借记录');
        return;
      }
      setBorrowers(borrowerList);
      setSelectedBorrower(null);
      setScanError('');
    } catch {
      setScanError('未找到该编号对应的外借记录');
    }
  }, []);

  const handleSubmitReturn = async (record) => {
    try {
      await submitReturn(record);
      setScanning(false);
      showToast('归还成功');
      setBorrowers([]);
      setSelectedBorrower(null);
      setSubmitError('');
      await loadRecords();
    } catch (err) {
      setSubmitError(err.message || '归还提交失败');
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

  const sheetTitle = selectedBorrower ? '归还登记' : borrowers.length > 0 ? '选择外借人' : scanError ? '提示' : '';

  const sheetContent = scanError ? (
    <div className="text-center py-6">
      <p className="text-red-500 text-sm">{scanError}</p>
    </div>
  ) : borrowers.length > 0 && !selectedBorrower ? (
    <BorrowerSelect borrowers={borrowers} onSelect={(b) => setSelectedBorrower(b)} />
  ) : selectedBorrower ? (
    <>
      <ReturnForm
        borrowRecord={selectedBorrower}
        operatorName={operatorName}
        showCostPrice={showCostPrice}
        onSubmit={handleSubmitReturn}
        onClose={() => { setBorrowers([]); setSelectedBorrower(null); setSubmitError(''); }}
      />
      {submitError && (
        <div className="mt-3 rounded-2xl bg-amber-50 px-4 py-3">
          <p className="text-sm text-amber-800">{submitError}</p>
        </div>
      )}
    </>
  ) : null;

  return (
    <div className="h-full flex flex-col bg-bg-main">
      <div className="px-5 pt-5 pb-4">
        <motion.div
          whileTap={{ scale: 0.97, transition: { duration: 0.1 } }}
          onPointerDown={() => { setScanning(true); setBorrowers([]); setSelectedBorrower(null); setScanError(''); }}
          className="w-full rounded-[20px] flex flex-col relative cursor-pointer"
          style={{ background: '#3B82F6', padding: '20px' }}
        >
          <span
            className="relative z-10 self-start rounded-[10px] font-black italic"
            style={{ background: '#1E3A5F', color: '#3B82F6', padding: '6px 14px', fontSize: '20px' }}
          >
            归还
          </span>
          <div
            className="absolute flex items-center justify-center"
            style={{ top: '50%', left: '50%', transform: 'translate(-50%, -50%)', width: '115px', height: '115px', background: '#1E3A5F', borderRadius: '16px' }}
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
      <div id="return-file-scanner" style={{ display: 'none' }} />

      <PullToRefresh
        onRefresh={handleRefresh}
        isRefreshing={isRefreshing}
        className="flex-1 overflow-y-auto hide-scrollbar"
      >
        <div className="px-5 pb-2 flex items-center gap-2.5">
          <div className="w-1 h-5 rounded-full bg-brand-yellow" />
          <h2 className="text-base font-bold text-text-primary">归还记录</h2>
        </div>
        {records.length === 0 ? (
          <p className="text-center text-text-secondary text-base py-8">暂无归还记录</p>
        ) : (
          <div className="px-5 flex flex-col" style={{ gap: '12px' }}>
            <AnimatePresence mode="popLayout">
              {records.map((record, idx) => (
                <RecordCard
                  key={record.id}
                  title={record.itemName}
                  detail={`${record.returnQty} 件 · ${record.borrower}`}
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
        onClose={() => { setScanning(false); setBorrowers([]); setSelectedBorrower(null); setScanError(''); setSkipCamera(false); }}
        onScanSuccess={handleScan}
        sheetTitle={sheetTitle}
        sheetContent={sheetContent}
        onSheetClose={() => { setBorrowers([]); setSelectedBorrower(null); setScanError(''); setSkipCamera(false); }}
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
