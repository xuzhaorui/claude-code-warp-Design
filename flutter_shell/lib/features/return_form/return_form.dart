import 'package:flutter/material.dart';

import '../../components/form_widgets.dart';
import '../../design/app_design_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../api/warehouse_api_client.dart';
import 'return_form_rules.dart';

/// Return (归还) form — Web-parity two-column layout.
///
/// Left panel: 在借数量 badge + 货物名称/外借人/仓库.
/// Right panel: 成本单价 CostBadge (if shown) + 归还数量 stepper + remark +
/// black 确认归还 button.  Mirrors `src/components/Forms/ReturnForm.jsx`.
class ReturnFormMin extends StatefulWidget {
  const ReturnFormMin({
    super.key,
    required this.record,
    this.operatorName,
    this.showCostPrice = true,
    this.apiClient,
    this.onSubmit,
    this.onClose,
    this.onSubmitSuccess,
  });

  final ReturnBorrowRecordSnapshot record;
  final String? operatorName;
  final bool showCostPrice;
  final WarehouseApiClient? apiClient;
  final ValueChanged<ReturnSubmitPayload>? onSubmit;
  final VoidCallback? onClose;
  final VoidCallback? onSubmitSuccess;

  @override
  State<ReturnFormMin> createState() => _ReturnFormMinState();
}

class _ReturnFormMinState extends State<ReturnFormMin> {
  String _returnQty = '';
  String _remark = '';
  bool _isSubmitting = false;
  String? _submitError;
  late final TextEditingController _qtyController;
  late final TextEditingController _remarkController;

  ReturnFormInput get _input =>
      ReturnFormInput(returnQty: _returnQty, remark: _remark);

  late ReturnFormEvaluation _evaluation;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController();
    _remarkController = TextEditingController();
    _qtyController.addListener(_onQtyListener);
    _remarkController.addListener(_onRemarkListener);
    _evaluation = ReturnFormRules.evaluate(
      input: _input,
      record: widget.record,
    );
  }

  @override
  void dispose() {
    _qtyController.removeListener(_onQtyListener);
    _remarkController.removeListener(_onRemarkListener);
    _qtyController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _recompute() {
    setState(
      () => _evaluation = ReturnFormRules.evaluate(
        input: _input,
        record: widget.record,
      ),
    );
  }

  void _onQtyListener() {
    _returnQty = _qtyController.text;
    _recompute();
  }

  void _onRemarkListener() {
    _remark = _remarkController.text;
    _recompute();
  }

  void _onQtyChanged(num v) {
    _returnQty = v.toString();
    _qtyController.text = _returnQty;
    _qtyController.selection = TextSelection.fromPosition(
      TextPosition(offset: _returnQty.length),
    );
    _recompute();
  }

  Future<void> _handleSubmit() async {
    final payload = ReturnFormRules.buildPayload(
      input: _input,
      record: widget.record,
    );
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
      widget.onSubmitSuccess?.call();
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

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left: item info panel ──
          ItemInfoPanel(
            children: [
              StockBadge(label: '在借数量', value: '${record.borrowQty}'),
              const SizedBox(height: AppSpacing.md),
              InfoField(label: '货物名称', value: record.itemName),
              const SizedBox(height: AppSpacing.sm),
              InfoField(label: '外借人', value: record.borrower),
              const SizedBox(height: AppSpacing.sm),
              InfoField(label: '仓库', value: record.warehouse),
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
                  if (widget.showCostPrice && record.costPrice > 0) ...[
                    CostBadge(value: '¥${record.costPrice.toStringAsFixed(2)}'),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  BlackStepper(
                    label: '归还数量',
                    controller: _qtyController,
                    min: 1,
                    max: record.borrowQty,
                    error: ev.overQty,
                    onChanged: _onQtyChanged,
                  ),
                  if (ev.overQty)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        left: AppSpacing.xs,
                      ),
                      child: Text(
                        '超出在借数量（在借: ${record.borrowQty}）',
                        style: AppTextStyles.caption.copyWith(
                          color: AppDesignColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  _RemarkField(controller: _remarkController),
                  if (_submitError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        _submitError!,
                        style: AppTextStyles.caption.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  BlackSubmitButton(
                    text: _isSubmitting ? '提交中...' : '确认归还',
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
  const _RemarkField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesignColors.surfaceMuted,
        borderRadius: BorderRadius.all(AppRadii.md),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '归还备注（选填）',
            style: AppTextStyles.caption.copyWith(
              color: AppDesignColors.textSecondary,
            ),
          ),
          TextFormField(
            controller: controller,
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: AppSpacing.xs),
            ),
          ),
        ],
      ),
    );
  }
}
