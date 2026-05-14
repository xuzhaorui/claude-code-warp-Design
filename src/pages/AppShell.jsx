import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { LogOut, RotateCcw, ClipboardCheck, Settings } from 'lucide-react';
import CheckoutTab from './CheckoutTab';
import ReturnTab from './ReturnTab';
import InventoryTab from './InventoryTab';
import SettingsTab from '../components/Settings/SettingsTab';
import Toast from '../components/Shared/Toast';

const allTabs = [
  { key: 'checkout', label: '出库', icon: LogOut, activeIcon: LogOut, permission: 'outbound' },
  { key: 'return', label: '归还', icon: RotateCcw, activeIcon: RotateCcw, permission: 'return' },
  { key: 'inventory', label: '盘点', icon: ClipboardCheck, activeIcon: ClipboardCheck, permission: 'inventory' },
  { key: 'settings', label: '设置', icon: Settings, activeIcon: Settings, permission: 'settings' },
];

export default function AppShell({ onLogout, onServerChanged, allowedTabs, showCostPrice }) {
  const visibleTabs = allTabs.filter(tab => allowedTabs.includes(tab.permission));
  const [activeTab, setActiveTab] = useState(visibleTabs[0]?.key || 'settings');

  useEffect(() => {
    if (!visibleTabs.some(t => t.key === activeTab)) {
      setActiveTab(visibleTabs[0]?.key || 'settings');
    }
  }, [allowedTabs]);

  const handleLogout = () => {
    localStorage.removeItem('currentUser');
    onLogout();
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'checkout': return <CheckoutTab showCostPrice={showCostPrice} />;
      case 'return': return <ReturnTab showCostPrice={showCostPrice} />;
      case 'inventory': return <InventoryTab showCostPrice={showCostPrice} />;
      case 'settings': return <SettingsTab onLogout={handleLogout} onServerChanged={onServerChanged} />;
      default: return null;
    }
  };

  return (
    <div className="h-full flex flex-col bg-bg-main">
      <div className="flex-1 overflow-hidden">
        {renderContent()}
      </div>

      {/* Bottom Tab Bar */}
      <div className="bg-white border-t border-gray-100 pb-safe">
        <div className="flex">
          {visibleTabs.map(tab => {
            const isActive = activeTab === tab.key;
            const Icon = tab.icon;
            return (
              <button
                key={tab.key}
                onPointerDown={() => setActiveTab(tab.key)}
                className="flex-1 flex flex-col items-center justify-center py-3 pt-4 active:bg-gray-100 select-none touch-none"
                style={{ minHeight: 64, WebkitTapHighlightColor: 'transparent' }}
              >
                <Icon
                  size={28}
                  className={isActive ? 'text-action-black' : 'text-text-secondary'}
                  strokeWidth={isActive ? 2.5 : 1.5}
                  fill={isActive ? 'currentColor' : 'none'}
                />
                <span className={`text-xs mt-1.5 ${isActive ? 'text-action-black font-semibold' : 'text-text-secondary'}`}>
                  {tab.label}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      <Toast />
    </div>
  );
}
