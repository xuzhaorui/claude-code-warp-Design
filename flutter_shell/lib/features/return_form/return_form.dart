import 'package:flutter/material.dart';

import '../../components/app_button.dart';
import '../../components/app_form_section.dart';
import '../../components/app_stepper.dart';
import '../../components/app_text_field.dart';
import '../../design/app_design_colors.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import 'return_form_rules.dart';

/// Minimal return (归还) form UI widget.
///
/// Composes [AppStepper], [AppTextField], and [AppButton] inside
/// [AppFormSection] containers.  All business logic (overQty, canSubmit,
/// payload) delegates to [ReturnFormRules.evaluate] / [buildPayload] —
/// the Widget layer never duplicates rules.
///
/// Maps to `src/components/Forms/ReturnForm.jsx`.
class ReturnFormMin extends StatefulWidget {
  const ReturnFormMin({
    super.key,
    required this.record,
    this.operatorName,
    this.showCostPrice = true,
    this.onSubmit,
    this.onClose,
  });

  /// The borrow record being returned.
  final ReturnBorrowRecordSnapshot record;

  /// Operator name (displayed but not submitted).
  final String? operatorName;

  /// Whether to show cost price (default true).
  final bool showCostPrice;

  /// Called with the submit payload when the form is submitted.
  final ValueChanged<ReturnSubmitPayload>? onSubmit;

  /// Callback for the close/dismiss action.
  final VoidCallback? onClose;

  @override
  State<ReturnFormMin> createState() => _ReturnFormMinState();
}

class _ReturnFormMinState extends State<ReturnFormMin> {
  String _returnQty = '';
  String _remark = '';

  ReturnFormInput get _input => ReturnFormInput(
        returnQty: _returnQty,
        remark: _remark,
      );

  late ReturnFormEvaluation _evaluation;

  @override
  void initState() {
    super.initState();
    _evaluation = ReturnFormRules.evaluate(
      input: _input,
      record: widget.record,
    );
  }

  void _recompute() {
    setState(() {
      _evaluation = ReturnFormRules.evaluate(
        input: _input,
        record: widget.record,
      );
    });
  }

  void _onQtyChanged(num v) {
    _returnQty = v.toString();
    _recompute();
  }

  void _onRemarkChanged(String v) {
    _remark = v;
    _recompute();
  }

  void _handleSubmit() {
    final payload = ReturnFormRules.buildPayload(
      input: _input,
      record: widget.record,
    );
    if (payload != null) {
      widget.onSubmit?.call(payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final ev = _evaluation;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Item info card ──
            AppFormSection(
              title: record.itemName.isNotEmpty ? record.itemName : '归还货物',
              subtitle: '在借数量：${record.borrowQty}',
              child: _itemInfoContent(record),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Cost price display ──
            if (widget.showCostPrice && record.costPrice > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  '成本单价：¥${record.costPrice.toStringAsFixed(2)}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppDesignColors.textSecondary,
                  ),
                ),
              ),

            // ── Quantity stepper ──
            AppStepper(
              value: _parseIntForStepper(_returnQty),
              min: 1,
              max: record.borrowQty,
              onChanged: _onQtyChanged,
              label: '归还数量',
            ),
            // over-qty warning
            if (ev.overQty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.xs),
                child: Text(
                  '超出在借数量（在借: ${record.borrowQty}）',
                  style: AppTextStyles.caption.copyWith(
                    color: AppDesignColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.md),

            // ── Remark field ──
            AppTextField(
              label: '归还备注（选填）',
              onChanged: _onRemarkChanged,
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Submit button ──
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: '确认归还',
                onPressed: ev.canSubmit ? _handleSubmit : null,
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
        _infoRow('货物名称', record.itemName),
        _infoRow('外借人', record.borrower),
        _infoRow('仓库', record.warehouse),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(label,
                style: AppTextStyles.caption.copyWith(
                  color: AppDesignColors.textSecondary,
                )),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  int _parseIntForStepper(String s) {
    if (s.isEmpty) return 1;
    final n = int.tryParse(s);
    return n ?? 1;
  }
}
