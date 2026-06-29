import 'package:flutter/material.dart';

import '../../components/app_button.dart';
import '../../components/app_form_section.dart';
import '../../components/app_stepper.dart';
import '../../components/app_text_field.dart';
import '../../design/app_design_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../api/warehouse_api_client.dart';
import 'inventory_check_form_rules.dart';

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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormSection(
              title: item.itemName.isNotEmpty ? item.itemName : '盘点货物',
              subtitle: '账面数量：${item.stockQty}',
              child: _itemInfoContent(item),
            ),
            const SizedBox(height: AppSpacing.md),
            AppStepper(value: _parseIntForStepper(_actualQty), min: 0, max: 99999, onChanged: _onQtyChanged, label: '盘点真实数量'),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppDesignColors.surfaceMuted,
                borderRadius: BorderRadius.all(AppRadii.md),
              ),
              child: Row(
                children: [
                  Text('盘点差异：', style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary)),
                  const Spacer(),
                  Text(diffText, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: diffColor)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: '盘点备注（选填）', onChanged: _onRemarkChanged),
            if (_submitError != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(_submitError!,
                    style: AppTextStyles.caption.copyWith(color: cs.error, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: _isSubmitting ? '提交中...' : '提交盘点',
                loading: _isSubmitting,
                onPressed: canSubmit ? _handleSubmit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemInfoContent(InventoryCheckItemSnapshot item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _infoRow('账面', '${item.stockQty}'),
        _infoRow('编号', item.code),
        _infoRow('规格', item.spec),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 56, child: Text(label,
              style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary))),
          Expanded(child: Text(value, style: AppTextStyles.body, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  int _parseIntForStepper(String s) {
    if (s.isEmpty) return 1;
    return int.tryParse(s) ?? 1;
  }
}
