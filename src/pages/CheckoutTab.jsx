import { useState, useEffect, useCallback } from 'react';
import { motion } from 'framer-motion';
import { ScanLine, LogOut } from 'lucide-react';
import ScannerOverlay from '../components/Scanner/ScannerOverlay';
import FormSheet from '../components/BottomSheet/FormSheet';
import DetailSheet from '../components/BottomSheet/DetailSheet';
import CheckoutForm from '../components/Forms/CheckoutForm';
import CheckoutDetail from '../components/Details/CheckoutDetail';
import RecordCard from '../components/Records/RecordCard';
import { getItemByCode, getCheckoutRecords, submitCheckout } from '../data/mockData';

export default function CheckoutTab() {
  const [scanning, setScanning] = useState(false);
  const [showForm, setShowForm] = useState(false);
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
    setScanning(false);
    const item = await getItemByCode(code);
    if (item) {
      setScannedItem(item);
      setShowForm(true);
    } else {
      setFormError('未找到该编号对应的库存货物');
      setTimeout(() => setFormError(''), 3000);
    }
  }, []);

  const handleSubmit = async (record) => {
    await submitCheckout(record);
    setShowForm(false);
    setScannedItem(null);
    await loadRecords();
  };

  return (
    <div className="h-full flex flex-col bg-bg-main">
      {/* Scan area - 30~40% */}
      <div className="px-5 pt-5 pb-4">
        <h1 className="text-2xl font-bold text-text-primary mb-4">出库</h1>
        <motion.button
          whileTap={{ scale: 0.96 }}
          onClick={() => setScanning(true)}
          className="w-full bg-bg-secondary rounded-3xl p-6 flex flex-col items-center gap-3"
        >
          <div className="w-16 h-16 rounded-2xl bg-brand-yellow/20 flex items-center justify-center">
            <ScanLine size={32} className="text-brand-yellow" />
          </div>
          <span className="text-sm font-semibold text-text-primary">点击扫码出库</span>
        </motion.button>

        {formError && (
          <p className="text-red-500 text-xs text-center mt-2">{formError}</p>
        )}
      </div>

      {/* Records list */}
      <div className="flex-1 overflow-y-auto hide-scrollbar">
        <div className="px-5 pb-2">
          <h2 className="text-sm font-semibold text-text-secondary">出库记录</h2>
        </div>
        {records.length === 0 ? (
          <p className="text-center text-text-secondary text-sm py-8">暂无出库记录</p>
        ) : (
          records.map((record, idx) => (
            <RecordCard
              key={record.id}
              icon={LogOut}
              badge={record.quantity}
              title={`${record.warehouse}  ${record.time.split(' ')[0]}`}
              subtitle={record.itemName}
              extra={record.method === '外销' ? `¥${record.saleTotalPrice.toFixed(2)}` : record.method}
              index={idx}
              onClick={() => { setSelectedRecord(record); setShowDetail(true); }}
            />
          ))
        )}
      </div>

      {/* Scanner */}
      <ScannerOverlay
        isOpen={scanning}
        onClose={() => setScanning(false)}
        onScanSuccess={handleScan}
      />

      {/* Form */}
      <FormSheet
        isOpen={showForm}
        onClose={() => { setShowForm(false); setScannedItem(null); }}
        title="出库登记"
      >
        {scannedItem && (
          <CheckoutForm
            item={scannedItem}
            operatorName={operatorName}
            onSubmit={handleSubmit}
            onClose={() => { setShowForm(false); setScannedItem(null); }}
          />
        )}
      </FormSheet>

      {/* Detail */}
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
