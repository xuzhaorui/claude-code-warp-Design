import 'package:flutter/material.dart';

import '../../components/form_widgets.dart';
import '../../design/app_design_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../api/warehouse_api_client.dart';
import 'inventory_check_form_rules.dart';

/// Inventory-check (盘点) form — Web-parity two-column layout.
///
/// Left panel: 账面数量 badge + 货物名称/编号/规格.
/// Right panel: 盘点真实数量 stepper + 差值 box (green/red) + remark +
/// black 提交盘点 button.  Mirrors `src/components/Forms/InventoryCheckForm.jsx`.
class InventoryCheckFormMin extends StatefulWidget {
  const InventoryCheckFormMin({
    super.key,
    required this.item,
    this.operatorName,
    this.apiClient,
    this.onSubmit,
    this.onClose,
    this.onSubmitSuccess,
  });

  final InventoryCheckItemSnapshot item;
  final String? operatorName;
  final WarehouseApiClient? apiClient;
  final ValueChanged<InventoryCheckSubmitPayload>? onSubmit;
  final VoidCallback? onClose;
  final VoidCallback? onSubmitSuccess;

  @override
  State<InventoryCheckFormMin> createState() => _InventoryCheckFormMinState();
}

class _InventoryCheckFormMinState extends State<InventoryCheckFormMin> {
  String _actualQty = '';
  String _remark = '';
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _actualQty = widget.item.stockQty.toString();
  }

  InventoryCheckFormInput get _input => InventoryCheckFormInput(actualQty: _actualQty, remark: _remark);

  void _onQtyChanged(num v) {
    setState(() => _actualQty = v.toString());
  }

  void _onRemarkChanged(String v) {
    setState(() => _remark = v);
  }

  Future<void> _handleSubmit() async {
    final payload = InventoryCheckFormRules.buildPayload(input: _input, item: widget.item);
    if (payload == null) return;

    final api = widget.apiClient;
    if (api == null) {
      widget.onSubmit?.call(payload);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final result = await api.submitInventoryCheck(payload);
    if (!mounted) return;

    if (result.isSuccess) {
      widget.onSubmitSuccess?.call();
      widget.onClose?.call();
    } else {
      setState(() {
        _isSubmitting = false;
        _submitError = result.message ?? '盘点提交失败';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final cs = Theme.of(context).colorScheme;
    final ev = InventoryCheckFormRules.evaluate(input: _input, item: item);
    final canSubmit = ev.canSubmit && !_isSubmitting;
    final diffColor = ev.diffQty > 0 ? cs.primary : ev.diffQty < 0 ? cs.error : AppDesignColors.textPrimary;
    final diffText = ev.diffQty > 0 ? '+${ev.diffQty}' : '${ev.diffQty}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left: item info panel ──
          ItemInfoPanel(
            children: [
              StockBadge(label: '账面数量', value: '${item.stockQty}'),
              const SizedBox(height: AppSpacing.md),
              InfoField(label: '货物名称', value: item.itemName),
              const SizedBox(height: AppSpacing.sm),
              InfoField(label: '编号', value: item.code),
              const SizedBox(height: AppSpacing.sm),
              InfoField(label: '规格', value: item.spec),
            ],
          ),
          // ── Right: form panel ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  BlackStepper(
                    label: '盘点真实数量',
                    controller: TextEditingController(text: _actualQty),
                    min: 0,
                    max: 99999,
                    onChanged: _onQtyChanged,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppDesignColors.surfaceMuted,
                      borderRadius: BorderRadius.all(AppRadii.md),
                    ),
                    child: Row(
                      children: [
                        Text('差值', style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary)),
                        const Spacer(),
                        Text(diffText,
                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, color: diffColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RemarkField(value: _remark, onChanged: _onRemarkChanged),
                  if (_submitError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(_submitError!,
                          style: AppTextStyles.caption.copyWith(color: cs.error, fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  BlackSubmitButton(
                    text: _isSubmitting ? '提交中...' : '提交盘点',
                    loading: _isSubmitting,
                    onPressed: canSubmit ? _handleSubmit : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemarkField extends StatelessWidget {
  const _RemarkField({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesignColors.surfaceMuted,
        borderRadius: BorderRadius.all(AppRadii.md),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('盘点备注（选填）', style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary)),
          TextFormField(
            controller: TextEditingController(text: value),
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: AppSpacing.xs),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
