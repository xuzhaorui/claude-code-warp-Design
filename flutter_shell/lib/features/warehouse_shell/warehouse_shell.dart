import 'package:flutter/material.dart';

import '../../design/app_design_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';

// ---- Tab enum ----

/// Available tabs in the warehouse shell.
enum WarehouseTab { checkout, returnForm, inventoryCheck, settings }

// ---- Component-local constants ----

class _WS {
  _WS._();
  static const bottomNavHeight = 64.0;
  static const navIconSize = 28.0;
  static const scanIconBox = 115.0;
  static const badgeHPad = 14.0;
  static const badgeVPad = 6.0;
  static const orangeBarW = 4.0;
  static const orangeBarH = 20.0;
}

// ---- Public widget ----

/// Warehouse bottom navigation shell — Web parity.
///
/// Four tabs: 出库 / 归还 / 盘点 / 设置.
/// No AppBar.  Each business tab shows a large scan card and record section.
/// The scan card fires [onScanRequested] with the current tab.
/// The settings tab fires [onSettingsRequested].
/// No manual "发起" buttons — the primary flow is scan → auto-open form.
class WarehouseShellMin extends StatefulWidget {
  const WarehouseShellMin({
    super.key,
    this.initialTab = WarehouseTab.checkout,
    this.lastScanCode,
    this.onScanRequested,
    this.onSettingsRequested,
  });

  final WarehouseTab initialTab;
  final String? lastScanCode;

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
    if (tab == WarehouseTab.settings) {
      widget.onSettingsRequested?.call();
      return;
    }
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
    final tabInfo = _tabInfo(_activeTab);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScanCard(tabInfo.badgeLabel),
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

  // ── Scan card ──

  Widget _buildScanCard(String badgeLabel) {
    return GestureDetector(
      key: const Key('scan_card'),
      onTap: () => widget.onScanRequested?.call(_activeTab),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppDesignColors.primarySoft,
          borderRadius: BorderRadius.all(AppRadii.lg),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _WS.badgeHPad,
                  vertical: _WS.badgeVPad,
                ),
                decoration: BoxDecoration(
                  color: AppDesignColors.primary,
                  borderRadius: BorderRadius.all(AppRadii.sm),
                ),
                child: Text(
                  badgeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 48, bottom: 8),
                child: Container(
                  width: _WS.scanIconBox,
                  height: _WS.scanIconBox,
                  decoration: BoxDecoration(
                    color: AppDesignColors.primary,
                    borderRadius: BorderRadius.all(AppRadii.md),
                  ),
                  child: const Icon(Icons.qr_code_scanner, size: 72, color: Colors.white),
                ),
              ),
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
            Icon(Icons.image, size: 16, color: AppDesignColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              '从图片识别',
              style: AppTextStyles.body.copyWith(color: AppDesignColors.textSecondary),
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
              width: _WS.orangeBarW,
              height: _WS.orangeBarH,
              decoration: BoxDecoration(
                color: AppDesignColors.primary,
                borderRadius: BorderRadius.all(AppRadii.pill),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(sectionTitle, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (widget.lastScanCode != null && widget.lastScanCode!.isNotEmpty)
          _buildLastScanResult(widget.lastScanCode!)
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
        border: Border.all(color: AppDesignColors.primary),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppDesignColors.primary, size: 20),
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
        return _TabInfo(badgeLabel: '出库', recordTitle: '出库记录', emptyText: '暂无出库记录');
      case WarehouseTab.returnForm:
        return _TabInfo(badgeLabel: '归还', recordTitle: '归还记录', emptyText: '暂无归还记录');
      case WarehouseTab.inventoryCheck:
        return _TabInfo(badgeLabel: '盘点', recordTitle: '盘点记录', emptyText: '暂无盘点记录');
      case WarehouseTab.settings:
        return _TabInfo(badgeLabel: '', recordTitle: '', emptyText: '设置页面');
    }
  }
}

class _TabInfo {
  final String badgeLabel;
  final String recordTitle;
  final String emptyText;

  const _TabInfo({
    required this.badgeLabel,
    required this.recordTitle,
    required this.emptyText,
  });
}
