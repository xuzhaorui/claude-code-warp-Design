import 'package:flutter/material.dart';

import '../../design/app_design_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../../components/record_card.dart';
import '../settings/server_config_page.dart';
import '../settings/server_config_store.dart';

// ---- Tab enum ----

/// Available tabs in the warehouse shell.
enum WarehouseTab { checkout, returnForm, inventoryCheck, settings }

// ---- Component-local constants ----
//
// Per Design.md, component-local numeric constants (icon sizes, accent bar
// dimensions) are allowed when they are not promoting a new design token.
class _WS {
  _WS._();
  static const bottomNavHeight = 64.0;
  static const navIconSize = 28.0;
  static const scanIconSize = 56.0;
  static const accentBarW = 3.0;
  static const accentBarH = 14.0;
  static const statusIconSize = 16.0;
  static const resultIconSize = 20.0;
  static const imageHintIconSize = 16.0;
}

// ---- Public widget ----

/// Warehouse bottom navigation shell — Web parity.
///
/// Four tabs: 出库 / 归还 / 盘点 / 设置.
/// No AppBar.  Each business tab shows a restrained scan card and record
/// section.  The scan card fires [onScanRequested] with the current tab.
/// The settings tab fires [onSettingsRequested].
/// No manual "发起" buttons — the primary flow is scan → auto-open form.
class WarehouseShellMin extends StatefulWidget {
  const WarehouseShellMin({
    super.key,
    this.initialTab = WarehouseTab.checkout,
    this.lastScanCode,
    this.scanError,
    this.records,
    this.serverConfigStore,
    this.activeServerName,
    this.onScanRequested,
    this.onSettingsRequested,
  });

  final WarehouseTab initialTab;
  final String? lastScanCode;

  /// Error message from scan lookup to display in the shell.
  final String? scanError;

  /// Records to display in the current tab (after successful submit).
  final List<RecordItem>? records;

  /// Optional server config store for the settings tab.
  /// Defaults to [PersistentServerConfigStore] when null.
  final ServerConfigStore? serverConfigStore;

  /// Display name of the currently active server, shown in the small status
  /// row of each business tab.  Null/empty shows "未配置".
  final String? activeServerName;

  /// Fired when the scan card is tapped. Carries the current tab.
  final ValueChanged<WarehouseTab>? onScanRequested;

  /// Fired when settings tab requests settings page navigation.
  final VoidCallback? onSettingsRequested;

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
      body: SafeArea(
        top: false,
        child: _buildTabContent(),
      ),
      bottomNavigationBar: SizedBox(
        height: _WS.bottomNavHeight,
        child: BottomNavigationBar(
          currentIndex: WarehouseTab.values.indexOf(_activeTab),
          onTap: (i) => _onTabChanged(WarehouseTab.values[i]),
          backgroundColor: AppDesignColors.surface,
          selectedItemColor: AppDesignColors.primary,
          unselectedItemColor: AppDesignColors.textSecondary,
          selectedFontSize: AppTextStyles.caption.fontSize ?? 12,
          unselectedFontSize: AppTextStyles.caption.fontSize ?? 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          type: BottomNavigationBarType.fixed,
          items: [
            _navItem(Icons.logout, '出库'),
            _navItem(Icons.replay, '归还'),
            _navItem(Icons.checklist, '盘点'),
            _navItem(Icons.settings, '设置'),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label) {
    return BottomNavigationBarItem(icon: Icon(icon, size: _WS.navIconSize), label: label);
  }

  // ── Tab content ──

  Widget _buildTabContent() {
    if (_activeTab == WarehouseTab.settings) {
      return ServerConfigPage(store: widget.serverConfigStore);
    }
    final tabInfo = _tabInfo(_activeTab);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(tabInfo.tabName),
          const SizedBox(height: AppSpacing.lg),
          _buildScanCard(),
          const SizedBox(height: AppSpacing.sm),
          _buildImageRecognitionHint(),
          const SizedBox(height: AppSpacing.xl),
          _buildRecordSection(
            sectionTitle: tabInfo.recordTitle,
            emptyText: tabInfo.emptyText,
          ),
        ],
      ),
    );
  }

  // ── Header ──

  Widget _buildHeader(String tabName) {
    final serverName = (widget.activeServerName == null || widget.activeServerName!.isEmpty)
        ? '未配置'
        : widget.activeServerName!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tabName, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(Icons.cloud_outlined, size: _WS.statusIconSize, color: AppDesignColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '当前服务器：$serverName',
              style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  // ── Scan card ──
  //
  // Restrained outline card: white surface, thin border, centered outline
  // scan icon in primary accent, primary label + secondary helper.  No large
  // solid colour block, no heavy shadow.

  Widget _buildScanCard() {
    return GestureDetector(
      key: const Key('scan_card'),
      onTap: () => widget.onScanRequested?.call(_activeTab),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppDesignColors.surface,
          borderRadius: BorderRadius.all(AppRadii.lg),
          border: Border.all(color: AppDesignColors.borderMuted),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl,
          horizontal: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, size: _WS.scanIconSize, color: AppDesignColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text('点击扫码', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '扫描条码或二维码',
              style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ── "从图片识别" hint ──

  Widget _buildImageRecognitionHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image, size: _WS.imageHintIconSize, color: AppDesignColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '从图片识别',
              style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ── Record section ──

  Widget _buildRecordSection({
    required String sectionTitle,
    required String emptyText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: _WS.accentBarW,
              height: _WS.accentBarH,
              decoration: BoxDecoration(
                color: AppDesignColors.primary,
                borderRadius: BorderRadius.all(AppRadii.pill),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(sectionTitle, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.records != null && widget.records!.isNotEmpty)
          ...widget.records!.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: RecordCard(
              title: r.title,
              detail: r.detail,
              status: r.status,
            ),
          ))
        else if (widget.lastScanCode != null && widget.lastScanCode!.isNotEmpty)
          _buildLastScanResult(widget.lastScanCode!)
        else if (widget.scanError != null && widget.scanError!.isNotEmpty)
          _buildScanError(widget.scanError!)
        else
          _buildEmptyState(emptyText),
      ],
    );
  }

  Widget _buildLastScanResult(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppDesignColors.surface,
        borderRadius: BorderRadius.all(AppRadii.md),
        border: Border.all(color: AppDesignColors.borderMuted),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppDesignColors.primary, size: _WS.resultIconSize),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '最近扫码：$code',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '已识别',
                  style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppDesignColors.surface,
        borderRadius: BorderRadius.all(AppRadii.md),
        border: Border.all(color: AppDesignColors.borderMuted),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: AppDesignColors.textSecondary, size: _WS.resultIconSize),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppDesignColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(
          text,
          style: AppTextStyles.body.copyWith(color: AppDesignColors.textSecondary),
        ),
      ),
    );
  }

  // ── Tab data ──

  _TabInfo _tabInfo(WarehouseTab tab) {
    switch (tab) {
      case WarehouseTab.checkout:
        return _TabInfo(tabName: '出库', recordTitle: '出库记录', emptyText: '暂无出库记录');
      case WarehouseTab.returnForm:
        return _TabInfo(tabName: '归还', recordTitle: '归还记录', emptyText: '暂无归还记录');
      case WarehouseTab.inventoryCheck:
        return _TabInfo(tabName: '盘点', recordTitle: '盘点记录', emptyText: '暂无盘点记录');
      case WarehouseTab.settings:
        return _TabInfo(tabName: '设置', recordTitle: '', emptyText: '设置页面');
    }
  }
}

// ---- Record item model ----

/// Minimal record data for display in the shell's record section.
class RecordItem {
  final String title;
  final String detail;
  final String? status;
  const RecordItem({required this.title, required this.detail, this.status});
}

// ---- Tab info data class ----

class _TabInfo {
  final String tabName;
  final String recordTitle;
  final String emptyText;

  const _TabInfo({
    required this.tabName,
    required this.recordTitle,
    required this.emptyText,
  });
}
