import { useState } from 'react';
import { motion } from 'framer-motion';
import { LogOut, RotateCcw, ClipboardCheck, Settings } from 'lucide-react';
import CheckoutTab from './CheckoutTab';
import ReturnTab from './ReturnTab';
import InventoryTab from './InventoryTab';
import SettingsTab from '../components/Settings/SettingsTab';

const tabs = [
  { key: 'checkout', label: '出库', icon: LogOut, activeIcon: LogOut },
  { key: 'return', label: '归还', icon: RotateCcw, activeIcon: RotateCcw },
  { key: 'inventory', label: '盘点', icon: ClipboardCheck, activeIcon: ClipboardCheck },
  { key: 'settings', label: '设置', icon: Settings, activeIcon: Settings },
];

export default function AppShell({ onLogout }) {
  const [activeTab, setActiveTab] = useState('checkout');

  const handleLogout = () => {
    localStorage.removeItem('currentUser');
    onLogout();
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'checkout': return <CheckoutTab />;
      case 'return': return <ReturnTab />;
      case 'inventory': return <InventoryTab />;
      case 'settings': return <SettingsTab onLogout={handleLogout} />;
      default: return <CheckoutTab />;
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
          {tabs.map(tab => {
            const isActive = activeTab === tab.key;
            const Icon = tab.icon;
            return (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key)}
                className="flex-1 flex flex-col items-center py-2 pt-3"
              >
                <Icon
                  size={22}
                  className={isActive ? 'text-action-black' : 'text-text-secondary'}
                  strokeWidth={isActive ? 2.5 : 1.5}
                  fill={isActive ? 'currentColor' : 'none'}
                />
                <span className={`text-[10px] mt-1 ${isActive ? 'text-action-black font-semibold' : 'text-text-secondary'}`}>
                  {tab.label}
                </span>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
