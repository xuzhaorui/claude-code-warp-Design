import 'package:flutter/material.dart';

import '../../components/app_button.dart';
import '../../components/app_form_section.dart';
import '../../components/app_segmented_control.dart';
import '../../components/app_stepper.dart';
import '../../components/app_text_field.dart';
import '../../design/app_design_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import 'checkout_form_rules.dart';

/// Minimal checkout (出库) form UI widget.
///
/// Composes [AppSegmentedControl], [AppStepper], [AppTextField], and
/// [AppButton] inside [AppFormSection] containers.  All business logic
/// (overStock, isLoss, canSubmit, payload) delegates to
/// [CheckoutFormRules.evaluate] / [buildPayload] — the Widget layer never
/// duplicates rules.
///
/// Maps to `src/components/Forms/CheckoutForm.jsx`.
class CheckoutFormMin extends StatefulWidget {
  const CheckoutFormMin({
    super.key,
    required this.item,
    this.operatorName,
    this.showCostPrice = true,
    this.onSubmit,
    this.onClose,
  });

  /// The item being checked out.
  final CheckoutItemSnapshot item;

  /// Operator name (displayed but not submitted).
  final String? operatorName;

  /// Whether to show and check cost price (default true).
  final bool showCostPrice;

  /// Called with the submit payload when the form is submitted.
  final ValueChanged<CheckoutSubmitPayload>? onSubmit;

  /// Callback for the close/dismiss action.
  final VoidCallback? onClose;

  @override
  State<CheckoutFormMin> createState() => _CheckoutFormMinState();
}

class _CheckoutFormMinState extends State<CheckoutFormMin> {
  String _quantity = '';
  CheckoutMethod _method = CheckoutMethod.sale;
  String _saleTotalPrice = '';
  String _remark = '';
  bool _confirmLoss = false;

  CheckoutFormInput get _input => CheckoutFormInput(
        quantity: _quantity,
        method: _method,
        saleTotalPrice: _saleTotalPrice,
        remark: _remark,
        confirmLoss: _confirmLoss,
        showCostPrice: widget.showCostPrice,
      );

  late CheckoutFormEvaluation _evaluation;

  @override
  void initState() {
    super.initState();
    _evaluation = CheckoutFormRules.evaluate(
      input: _input,
      item: widget.item,
    );
  }

  void _recompute() {
    setState(() {
      _evaluation = CheckoutFormRules.evaluate(
        input: _input,
        item: widget.item,
      );
    });
  }

  void _onQuantityChanged(num v) {
    _quantity = v.toString();
    _confirmLoss = false;
    _recompute();
  }

  void _onMethodChanged(CheckoutMethod m) {
    _method = m;
    _confirmLoss = false;
    _recompute();
  }

  void _onSaleTotalChanged(String v) {
    _saleTotalPrice = v;
    _confirmLoss = false;
    _recompute();
  }

  void _onRemarkChanged(String v) {
    _remark = v;
    _recompute();
  }

  void _handleSubmit() {
    final payload = CheckoutFormRules.buildPayload(
      input: _input,
      item: widget.item,
    );
    if (payload != null) {
      widget.onSubmit?.call(payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final ev = _evaluation;
    final isSale = _method == CheckoutMethod.sale;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Item info card ──
            AppFormSection(
              title: '$itemCode(item)',
              subtitle: item.itemName,
              child: _itemInfoContent(item),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Method selector ──
            AppSegmentedControl<CheckoutMethod>(
              options: const [
                AppSegmentedOption(value: CheckoutMethod.sale, label: '外销'),
                AppSegmentedOption(
                    value: CheckoutMethod.borrow, label: '外借'),
              ],
              selectedValue: _method,
              onChanged: _onMethodChanged,
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Quantity stepper ──
            AppStepper(
              value: _parseIntForStepper(_quantity),
              min: 1,
              max: item.stockQty,
              onChanged: _onQuantityChanged,
              label: '出库数量',
            ),
            // over-stock warning
            if (ev.overStock)
              Padding(
                padding:
                    const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.xs),
                child: Text(
                  '超出库存数量（库存: ${item.stockQty}）',
                  style: AppTextStyles.caption.copyWith(
                    color: AppDesignColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // ── Sale section ──
            if (isSale) ...[
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: '销售总价',
                hint: '0',
                keyboardType: TextInputType.number,
                onChanged: _onSaleTotalChanged,
              ),
              const SizedBox(height: AppSpacing.sm),
              // Sale unit price display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppDesignColors.surfaceMuted,
                  borderRadius: BorderRadius.all(
                    AppRadii.md,
                  ),
                ),
                child: Row(
                  children: [
                    Text('销售单价：',
                        style: AppTextStyles.caption.copyWith(
                          color: AppDesignColors.textSecondary,
                        )),
                    const Spacer(),
                    Text(
                      '¥${ev.saleUnitPrice.toStringAsFixed(2)}',
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              // Loss warning
              if (ev.isLoss && !_confirmLoss) ...[
                const SizedBox(height: AppSpacing.sm),
                _LossWarning(
                  costPrice: item.costPrice,
                  onConfirm: () => setState(() => _confirmLoss = true),
                ),
              ],
              if (ev.isLoss && _confirmLoss)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    '已确认亏损操作',
                    style: AppTextStyles.caption.copyWith(
                      color: AppDesignColors.textSecondary,
                    ),
                  ),
                ),
            ],

            // ── Borrow section ──
            if (!isSale) ...[
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: '出库备注（选填）',
                onChanged: _onRemarkChanged,
              ),
            ],

            // ── Cost price display ──
            if (widget.showCostPrice) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                '成本单价：¥${item.costPrice.toStringAsFixed(2)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppDesignColors.textSecondary,
                ),
              ),
            ],

            // ── Submit button ──
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: '提交',
                onPressed: ev.canSubmit ? _handleSubmit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String itemCode(CheckoutItemSnapshot item) {
    final parts = [item.itemName, item.code].where((s) => s.isNotEmpty);
    return parts.isNotEmpty ? parts.join(' / ') : '货物信息';
  }

  Widget _itemInfoContent(CheckoutItemSnapshot item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _infoRow('库存', '${item.stockQty}'),
        _infoRow('编号', item.code),
        _infoRow('仓库', item.warehouse),
        _infoRow('规格', item.spec),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 56,
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

// ---- Loss warning widget ----

class _LossWarning extends StatelessWidget {
  const _LossWarning({
    required this.costPrice,
    required this.onConfirm,
  });

  final double costPrice;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.all(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '销售单价低于成本单价（¥${costPrice.toStringAsFixed(2)}），存在亏损风险',
            style: AppTextStyles.caption.copyWith(color: cs.error),
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: onConfirm,
            child: Text(
              '确认继续',
              style: AppTextStyles.caption.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
