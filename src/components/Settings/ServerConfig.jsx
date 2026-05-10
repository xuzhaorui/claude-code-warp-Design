import { useState } from 'react';
import { motion } from 'framer-motion';
import { Plus, Pencil, Trash2, Server, ChevronLeft } from 'lucide-react';
import FormSheet from '../BottomSheet/FormSheet';

export default function ServerConfig({ onBack }) {
  const [servers, setServers] = useState(() => {
    try { return JSON.parse(localStorage.getItem('servers') || '[]'); } catch { return []; }
  });
  const [activeId, setActiveId] = useState(() => localStorage.getItem('activeServer') || '');
  const [showForm, setShowForm] = useState(false);
  const [editingServer, setEditingServer] = useState(null);
  const [formName, setFormName] = useState('');
  const [formUrl, setFormUrl] = useState('');
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(null);

  const saveServers = (list, active) => {
    setServers(list);
    localStorage.setItem('servers', JSON.stringify(list));
    if (active) {
      setActiveId(active);
      localStorage.setItem('activeServer', active);
    }
  };

  const handleAdd = () => {
    setEditingServer(null);
    setFormName('');
    setFormUrl('');
    setShowForm(true);
  };

  const handleEdit = (server) => {
    setEditingServer(server);
    setFormName(server.name);
    setFormUrl(server.url);
    setShowForm(true);
  };

  const handleFormSubmit = () => {
    if (!formName.trim() || !formUrl.trim()) return;
    if (editingServer) {
      const updated = servers.map(s =>
        s.id === editingServer.id ? { ...s, name: formName.trim(), url: formUrl.trim() } : s
      );
      saveServers(updated);
    } else {
      const newServer = { id: 'srv-' + Date.now(), name: formName.trim(), url: formUrl.trim() };
      const updated = [...servers, newServer];
      const newActive = activeId || newServer.id;
      saveServers(updated, newActive);
    }
    setShowForm(false);
  };

  const handleDelete = (id) => {
    const updated = servers.filter(s => s.id !== id);
    let newActive = activeId;
    if (activeId === id) {
      newActive = updated.length > 0 ? updated[0].id : '';
    }
    saveServers(updated, newActive);
    setShowDeleteConfirm(null);
  };

  const handleSelect = (id) => {
    saveServers(servers, id);
  };

  return (
    <div className="h-full flex flex-col bg-bg-main">
      <div className="flex items-center gap-3 px-4 py-4 border-b border-gray-100">
        <button onClick={onBack} className="p-1">
          <ChevronLeft size={22} className="text-action-black" />
        </button>
        <h1 className="text-lg font-bold text-text-primary">服务器配置</h1>
      </div>

      <div className="flex-1 overflow-y-auto hide-scrollbar">
        {servers.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-64 text-text-secondary">
            <Server size={48} strokeWidth={1} className="mb-3 text-gray-300" />
            <p className="text-sm">暂无服务器配置</p>
          </div>
        ) : (
          servers.map((server, idx) => (
            <motion.div
              key={server.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: idx * 0.05 }}
              className={`flex items-center gap-3 px-4 py-3.5 border-b border-gray-100 active:bg-gray-50 cursor-pointer ${activeId === server.id ? 'bg-yellow-50/50' : ''}`}
              onClick={() => handleSelect(server.id)}
            >
              {activeId === server.id && (
                <div className="w-2 h-2 rounded-full bg-action-black shrink-0" />
              )}
              {activeId !== server.id && <div className="w-2 shrink-0" />}

              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-text-primary truncate">{server.name}</p>
                <p className="text-xs text-text-secondary truncate">{server.url}</p>
              </div>

              <button
                onClick={e => { e.stopPropagation(); handleEdit(server); }}
                className="p-2 active:bg-gray-100 rounded-full"
              >
                <Pencil size={16} className="text-text-secondary" />
              </button>
              <button
                onClick={e => { e.stopPropagation(); setShowDeleteConfirm(server.id); }}
                className="p-2 active:bg-gray-100 rounded-full"
              >
                <Trash2 size={16} className="text-text-secondary" />
              </button>
            </motion.div>
          ))
        )}
      </div>

      <div className="p-4">
        <motion.button
          whileTap={{ scale: 0.96 }}
          onClick={handleAdd}
          className="w-full py-3 bg-action-black text-white font-semibold rounded-full text-sm flex items-center justify-center gap-2"
        >
          <Plus size={18} />
          添加服务器
        </motion.button>
      </div>

      <FormSheet
        isOpen={showForm}
        onClose={() => setShowForm(false)}
        title={editingServer ? '编辑服务器' : '添加服务器'}
      >
        <div className="space-y-4">
          <div>
            <label className="text-xs font-semibold text-text-secondary mb-1 block">服务器名称</label>
            <input
              value={formName}
              onChange={e => setFormName(e.target.value)}
              placeholder="如：公司主服务器"
              className="w-full px-4 py-3 bg-bg-secondary rounded-2xl text-sm"
            />
          </div>
          <div>
            <label className="text-xs font-semibold text-text-secondary mb-1 block">IP 地址</label>
            <input
              value={formUrl}
              onChange={e => setFormUrl(e.target.value)}
              placeholder="如：192.168.1.100"
              className="w-full px-4 py-3 bg-bg-secondary rounded-2xl text-sm"
            />
          </div>
          <motion.button
            whileTap={{ scale: 0.96 }}
            onClick={handleFormSubmit}
            className="w-full py-3 bg-action-black text-white font-semibold rounded-full text-sm"
          >
            确认
          </motion.button>
        </div>
      </FormSheet>

      {/* Delete confirmation */}
      {showDeleteConfirm && (
        <>
          <div className="fixed inset-0 bg-black/50 z-40" onClick={() => setShowDeleteConfirm(null)} />
          <div className="fixed bottom-0 left-0 right-0 bg-white rounded-t-3xl z-50 p-6">
            <p className="text-center font-semibold text-text-primary mb-2">确认删除</p>
            <p className="text-center text-sm text-text-secondary mb-6">删除后无法恢复，确定要删除该服务器吗？</p>
            <div className="flex gap-3">
              <button
                onClick={() => setShowDeleteConfirm(null)}
                className="flex-1 py-3 bg-bg-secondary rounded-full text-sm font-semibold"
              >
                取消
              </button>
              <button
                onClick={() => handleDelete(showDeleteConfirm)}
                className="flex-1 py-3 bg-action-black text-white rounded-full text-sm font-semibold"
              >
                删除
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
