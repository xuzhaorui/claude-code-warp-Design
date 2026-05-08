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
