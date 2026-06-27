import 'package:flutter/material.dart';

import '../../design/app_design_colors.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';

// ---- Tab enum ----

/// Available tabs in the warehouse shell.
enum WarehouseTab { checkout, returnForm, inventoryCheck }

// ---- Component-local constants ----

/// Layout constants specific to WarehouseShellMin.
///
/// `bottomNavHeight` (64px) matches the Web's `minHeight: 64` and standard
/// Material bottom navigation height.
/// `navIconSize` (28px) matches Web lucide-react `size={28}`.
class _WS {
  _WS._();
  static const bottomNavHeight = 64.0;
  static const navIconSize = 28.0;
}

// ---- Public widget ----

/// Minimal warehouse bottom navigation shell with three tabs:
///   出库 (checkout), 归还 (return), 盘点 (inventory check)
///
/// Maps to `src/pages/AppShell.jsx`.  This is a presentational shell only —
/// it does not hold real inventory data, call APIs, or open business forms.
/// User intents are forwarded via callback parameters.
class WarehouseShellMin extends StatefulWidget {
  const WarehouseShellMin({
    super.key,
    this.initialTab = WarehouseTab.checkout,
    this.onScanRequested,
    this.onCheckoutRequested,
    this.onReturnRequested,
    this.onInventoryCheckRequested,
  });

  /// Initial tab (default: checkout).
  final WarehouseTab initialTab;

  /// Fired when the user taps the scan entry point.
  final VoidCallback? onScanRequested;

  /// Fired when the user initiates a checkout action.
  final VoidCallback? onCheckoutRequested;

  /// Fired when the user initiates a return action.
  final VoidCallback? onReturnRequested;

  /// Fired when the user initiates an inventory check action.
  final VoidCallback? onInventoryCheckRequested;

  @override
  State<WarehouseShellMin> createState() => _WarehouseShellMinState();
}

class _WarehouseShellMinState extends State<WarehouseShellMin> {
  late WarehouseTab _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  void _onTabChanged(WarehouseTab tab) {
    setState(() => _activeTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignColors.background,
      appBar: AppBar(
        title: Text(
          _tabLabel(_activeTab),
          style: AppTextStyles.title,
        ),
        centerTitle: false,
      ),
      body: _buildTabContent(),
      bottomNavigationBar: SizedBox(
        height: _WS.bottomNavHeight,
        child: BottomNavigationBar(
          currentIndex: _activeTab.index,
          onTap: (i) => _onTabChanged(WarehouseTab.values[i]),
          backgroundColor: AppDesignColors.surface,
          selectedItemColor: AppDesignColors.textPrimary,
          unselectedItemColor: AppDesignColors.textSecondary,
          selectedFontSize: AppTextStyles.caption.fontSize ?? 12,
          unselectedFontSize: AppTextStyles.caption.fontSize ?? 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          type: BottomNavigationBarType.fixed,
          items: [
            _navItem(Icons.logout, '出库', WarehouseTab.checkout),
            _navItem(Icons.replay, '归还', WarehouseTab.returnForm),
            _navItem(Icons.checklist, '盘点', WarehouseTab.inventoryCheck),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(
      IconData icon, String label, WarehouseTab tab) {
    final isActive = _activeTab == tab;
    return BottomNavigationBarItem(
      icon: Icon(icon,
          size: _WS.navIconSize,
          color: isActive
              ? AppDesignColors.textPrimary
              : AppDesignColors.textSecondary),
      label: label,
    );
  }

  Widget _buildTabContent() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab description
          Text(
            _tabDescription(_activeTab),
            style: AppTextStyles.body.copyWith(
              color: AppDesignColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Scan entry button (placeholder)
          SizedBox(
            width: double.infinity,
            child: _ActionCard(
              label: _scanLabel(_activeTab),
              icon: Icons.qr_code_scanner,
              onTap: widget.onScanRequested,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Form entry button (placeholder)
          SizedBox(
            width: double.infinity,
            child: _ActionCard(
              label: _formLabel(_activeTab),
              icon: Icons.edit_note,
              onTap: _formCallback(),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _formCallback() {
    switch (_activeTab) {
      case WarehouseTab.checkout:
        return widget.onCheckoutRequested;
      case WarehouseTab.returnForm:
        return widget.onReturnRequested;
      case WarehouseTab.inventoryCheck:
        return widget.onInventoryCheckRequested;
    }
  }

  String _tabLabel(WarehouseTab tab) {
    switch (tab) {
      case WarehouseTab.checkout:
        return '出库';
      case WarehouseTab.returnForm:
        return '归还';
      case WarehouseTab.inventoryCheck:
        return '盘点';
    }
  }

  String _tabDescription(WarehouseTab tab) {
    switch (tab) {
      case WarehouseTab.checkout:
        return '扫码或选择货物后发起出库';
      case WarehouseTab.returnForm:
        return '选择外借记录后发起归还';
      case WarehouseTab.inventoryCheck:
        return '选择货物后录入实盘数量';
    }
  }

  String _scanLabel(WarehouseTab tab) {
    switch (tab) {
      case WarehouseTab.checkout:
        return '扫码出库';
      case WarehouseTab.returnForm:
        return '扫码归还';
      case WarehouseTab.inventoryCheck:
        return '扫码盘点';
    }
  }

  String _formLabel(WarehouseTab tab) {
    switch (tab) {
      case WarehouseTab.checkout:
        return '发起出库';
      case WarehouseTab.returnForm:
        return '发起归还';
      case WarehouseTab.inventoryCheck:
        return '发起盘点';
    }
  }
}

// ---- Action card widget ----

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDesignColors.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, size: 24, color: AppDesignColors.textPrimary),
              const SizedBox(width: AppSpacing.md),
              Text(label,
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
