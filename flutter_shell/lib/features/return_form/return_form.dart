import 'package:flutter/material.dart';

import '../../components/app_button.dart';
import '../../components/app_form_section.dart';
import '../../components/app_stepper.dart';
import '../../components/app_text_field.dart';
import '../../design/app_design_colors.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../api/warehouse_api_client.dart';
import 'return_form_rules.dart';

class ReturnFormMin extends StatefulWidget {
  const ReturnFormMin({
    super.key,
    required this.record,
    this.operatorName,
    this.showCostPrice = true,
    this.apiClient,
    this.onSubmit,
    this.onClose,
  });

  final ReturnBorrowRecordSnapshot record;
  final String? operatorName;
  final bool showCostPrice;
  final WarehouseApiClient? apiClient;
  final ValueChanged<ReturnSubmitPayload>? onSubmit;
  final VoidCallback? onClose;

  @override
  State<ReturnFormMin> createState() => _ReturnFormMinState();
}

class _ReturnFormMinState extends State<ReturnFormMin> {
  String _returnQty = '';
  String _remark = '';
  bool _isSubmitting = false;
  String? _submitError;

  ReturnFormInput get _input => ReturnFormInput(returnQty: _returnQty, remark: _remark);

  late ReturnFormEvaluation _evaluation;

  @override
  void initState() {
    super.initState();
    _evaluation = ReturnFormRules.evaluate(input: _input, record: widget.record);
  }

  void _recompute() {
    setState(() => _evaluation = ReturnFormRules.evaluate(input: _input, record: widget.record));
  }

  void _onQtyChanged(num v) {
    _returnQty = v.toString();
    _recompute();
  }

  void _onRemarkChanged(String v) {
    _remark = v;
    _recompute();
  }

  Future<void> _handleSubmit() async {
    final payload = ReturnFormRules.buildPayload(input: _input, record: widget.record);
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

    final result = await api.submitReturn(payload);
    if (!mounted) return;

    if (result.isSuccess) {
      widget.onClose?.call();
    } else {
      setState(() {
        _isSubmitting = false;
        _submitError = result.message ?? '归还提交失败';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final ev = _evaluation;
    final canSubmit = ev.canSubmit && !_isSubmitting;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormSection(
              title: record.itemName.isNotEmpty ? record.itemName : '归还货物',
              subtitle: '在借数量：${record.borrowQty}',
              child: _itemInfoContent(record),
            ),
            if (widget.showCostPrice && record.costPrice > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text('成本单价：¥${record.costPrice.toStringAsFixed(2)}',
                    style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary)),
              ),
            AppStepper(
              value: _parseIntForStepper(_returnQty),
              min: 1,
              max: record.borrowQty,
              onChanged: _onQtyChanged,
              label: '归还数量',
            ),
            if (ev.overQty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.xs),
                child: Text('超出在借数量（在借: ${record.borrowQty}）',
                    style: AppTextStyles.caption.copyWith(
                        color: AppDesignColors.textPrimary, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: '归还备注（选填）', onChanged: _onRemarkChanged),
            if (_submitError != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(_submitError!,
                    style: AppTextStyles.caption.copyWith(
                        color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: _isSubmitting ? '提交中...' : '确认归还',
                loading: _isSubmitting,
                onPressed: canSubmit ? _handleSubmit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemInfoContent(ReturnBorrowRecordSnapshot record) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _infoRow('在借', '${record.borrowQty}'),
        _infoRow('借用人', record.borrower),
        _infoRow('仓库', record.warehouse),
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
