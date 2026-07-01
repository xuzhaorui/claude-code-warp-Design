import 'package:flutter/material.dart';

import '../../components/app_bottom_sheet.dart';
import '../../components/record_card.dart';
import '../../design/app_design_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../api/warehouse_api_models.dart';
import '../settings/server_config_page.dart';
import '../settings/server_config_store.dart';

// ---- Tab enum ----

/// Available tabs in the warehouse shell.
enum WarehouseTab { checkout, returnForm, inventoryCheck, settings }

/// Which kind of business record a [RecordItem] carries.  Drives the record
/// detail BottomSheet layout.
enum RecordKind { checkout, returnForm, inventoryCheck }

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
  static const detailRowVPad = 12.0;
  static const detailMetaIconSize = 14.0;
}

// ---- Public widget ----

/// Warehouse bottom navigation shell — Web parity.
///
/// Four tabs: 出库 / 归还 / 盘点 / 设置.
/// No AppBar.  Each business tab shows a restrained scan card (with a
/// per-tab call-to-action), and a record section.  Tapping a record opens
/// a detail BottomSheet.  The scan card fires [onScanRequested] with the
/// current tab.
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
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow(),
          const SizedBox(height: AppSpacing.md),
          _buildScanCard(tabInfo.scanCta),
          const SizedBox(height: AppSpacing.xl),
          _buildRecordSection(
            sectionTitle: tabInfo.recordTitle,
            emptyText: tabInfo.emptyText,
          ),
        ],
      ),
    );
  }

  // ── Status row ──
  //
  // Per task-041: top large title removed.  Only the compact server status
  // line remains.

  Widget _buildStatusRow() {
    final serverName = (widget.activeServerName == null || widget.activeServerName!.isEmpty)
        ? '未配置'
        : widget.activeServerName!;
    return Row(
      children: [
        Icon(Icons.cloud_outlined, size: _WS.statusIconSize, color: AppDesignColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '当前服务器：$serverName',
          style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary),
        ),
      ],
    );
  }

  // ── Scan card ──
  //
  // Restrained outline card with a per-tab call-to-action.  No subtitle,
  // no image-recognition hint (removed in task-041 for Web parity).

  Widget _buildScanCard(String ctaText) {
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
            Text(ctaText, style: AppTextStyles.title),
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
          ...widget.records!.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: RecordCard(
              title: entry.value.title,
              detail: entry.value.detail,
              status: entry.value.status,
              index: entry.key,
              onTap: () => _openRecordDetail(entry.value),
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

  // ── Record detail BottomSheet ──

  void _openRecordDetail(RecordItem record) {
    final info = _tabInfo(_activeTab);
    showAppBottomSheet(
      context: context,
      title: info.detailTitle,
      child: _buildRecordDetail(record),
    );
  }

  /// Renders Web-parity detail rows for the given record.  Switches on
  /// [RecordItem.kind] and reads the typed [RecordItem.source] DTO.
  /// Missing fields render "-" rather than fabricated data.
  Widget _buildRecordDetail(RecordItem record) {
    switch (record.kind) {
      case RecordKind.checkout:
        final r = record.source as CheckoutRecord?;
        return r == null ? _detailHeader(record.title, '', '') : _checkoutDetail(r);
      case RecordKind.returnForm:
        final r = record.source as ReturnRecord?;
        return r == null ? _detailHeader(record.title, '', '') : _returnDetail(r);
      case RecordKind.inventoryCheck:
        final r = record.source as InventoryCheckRecord?;
        return r == null ? _detailHeader(record.title, '', '') : _inventoryDetail(r);
    }
  }

  Widget _checkoutDetail(CheckoutRecord r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailHeader(r.itemName, r.spec, r.code),
        _DetailRow(label: '数量', value: '${r.quantity} 件 · ${r.method}'),
        if (r.costPrice > 0) _DetailRow(label: '成本单价', value: '¥${r.costPrice.toStringAsFixed(2)}'),
        _DetailRow(label: '状态', value: _orDash(r.status)),
        _DetailRow(label: '仓库', value: _orDash(r.warehouse)),
        if (r.type == 1) ...[
          _DetailRow(label: '销售总价', value: '¥${r.saleTotalPrice.toStringAsFixed(2)}'),
          _DetailRow(label: '销售单价', value: '¥${r.saleUnitPrice.toStringAsFixed(2)}'),
        ],
        _DetailMeta(operatorName: r.operatorName, time: r.time, remark: r.remark),
      ],
    );
  }

  Widget _returnDetail(ReturnRecord r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailHeader(r.itemName, r.spec, r.code),
        _DetailRow(label: '归还数量', value: '${r.returnQty} 件'),
        _DetailRow(label: '外借人', value: _orDash(r.borrower)),
        _DetailRow(label: '状态', value: _orDash(r.status)),
        _DetailRow(label: '仓库', value: _orDash(r.warehouse)),
        _DetailMeta(operatorName: r.operatorName, time: r.time, remark: r.remark),
      ],
    );
  }

  Widget _inventoryDetail(InventoryCheckRecord r) {
    final diff = r.difference;
    final diffText = diff > 0 ? '+$diff' : '$diff';
    final loss = diff != 0 ? (diff.abs() * r.costPrice) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailHeader(r.itemName, r.spec, r.code),
        _DetailRow(label: '实盘数量', value: '${r.actualQty} 件'),
        _DetailRow(label: '账面库存', value: '${r.bookQty} 件'),
        _DetailRow(label: '盘点差值', value: '$diffText 件'),
        if (r.costPrice > 0) _DetailRow(label: '成本单价', value: '¥${r.costPrice.toStringAsFixed(2)}'),
        if (r.costPrice > 0 && diff != 0)
          _DetailRow(label: diff < 0 ? '损失' : '溢价', value: '¥${loss.toStringAsFixed(2)}'),
        _DetailRow(label: '仓库', value: _orDash(r.warehouse)),
        _DetailMeta(operatorName: r.operatorName, time: r.time, remark: r.remark),
      ],
    );
  }

  /// Header block: item name (title) + "spec · code" subtitle line.
  Widget _detailHeader(String itemName, String spec, String code) {
    final sub = [spec, code].where((s) => s.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(itemName.isEmpty ? '-' : itemName, style: AppTextStyles.title),
          if (sub.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                sub,
                style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  String _orDash(String value) => value.isEmpty ? '-' : value;

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
        return _TabInfo(
          scanCta: '点击扫码出库',
          recordTitle: '出库记录',
          emptyText: '暂无出库记录',
          detailTitle: '出库详情',
        );
      case WarehouseTab.returnForm:
        return _TabInfo(
          scanCta: '点击扫码归还',
          recordTitle: '归还记录',
          emptyText: '暂无归还记录',
          detailTitle: '归还详情',
        );
      case WarehouseTab.inventoryCheck:
        return _TabInfo(
          scanCta: '点击扫码盘点',
          recordTitle: '盘点记录',
          emptyText: '暂无盘点记录',
          detailTitle: '盘点详情',
        );
      case WarehouseTab.settings:
        return _TabInfo(
          scanCta: '',
          recordTitle: '',
          emptyText: '设置页面',
          detailTitle: '',
        );
    }
  }
}

// ---- Record item model ----

/// Minimal record data for display in the shell's record section.
///
/// [title]/[detail]/[status] drive the list card.  [kind] + [source] carry
/// the typed DTO used to render the record detail BottomSheet.
class RecordItem {
  final String title;
  final String detail;
  final String? status;
  final RecordKind kind;
  final Object? source;

  const RecordItem({
    required this.title,
    required this.detail,
    this.status,
    this.kind = RecordKind.checkout,
    this.source,
  });
}

// ---- Detail-sheet presentational helpers (token-compliant) ----

/// A label/value row separated by a thin divider, mirroring Web `Row`.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: _WS.detailRowVPad),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppDesignColors.borderMuted),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Operator · time · remark strip, mirroring Web `MetaStrip`.
class _DetailMeta extends StatelessWidget {
  const _DetailMeta({required this.operatorName, required this.time, required this.remark});
  final String operatorName;
  final String time;
  final String remark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        children: [
          _metaItem(Icons.person_outline, operatorName, true),
          _metaItem(Icons.access_time, time, false),
          if (remark.isNotEmpty) _metaItem(Icons.notes, remark, false),
        ],
      ),
    );
  }

  Widget _metaItem(IconData icon, String text, bool emphasized) {
    final value = text.isEmpty ? '-' : text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: _WS.detailMetaIconSize, color: AppDesignColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          value,
          style: emphasized
              ? AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)
              : AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary),
        ),
      ],
    );
  }
}

// ---- Tab info data class ----

class _TabInfo {
  final String scanCta;
  final String recordTitle;
  final String emptyText;
  final String detailTitle;

  const _TabInfo({
    required this.scanCta,
    required this.recordTitle,
    required this.emptyText,
    required this.detailTitle,
  });
}
