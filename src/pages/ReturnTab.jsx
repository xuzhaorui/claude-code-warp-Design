import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ScanLine, RotateCcw } from 'lucide-react';
import ScannerOverlay from '../components/Scanner/ScannerOverlay';
import DetailSheet from '../components/BottomSheet/DetailSheet';
import BorrowerSelect from '../components/Forms/BorrowerSelect';
import ReturnForm from '../components/Forms/ReturnForm';
import ReturnDetail from '../components/Details/ReturnDetail';
import RecordCard from '../components/Records/RecordCard';
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
                status={record.status}
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
