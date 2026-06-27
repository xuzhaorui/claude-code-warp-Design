import 'package:flutter/material.dart';

import '../../components/app_button.dart';
import '../../components/app_form_section.dart';
import '../../components/app_stepper.dart';
import '../../components/app_text_field.dart';
import '../../design/app_design_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import 'inventory_check_form_rules.dart';

/// Minimal inventory check (盘点) form UI widget.
///
/// Composes [AppStepper], [AppTextField], and [AppButton] inside
/// [AppFormSection] containers.  All business logic (diffQty, diffType)
/// delegates to [InventoryCheckFormRules.evaluate] / [buildPayload] —
/// the Widget layer never duplicates rules.
///
/// Maps to `src/components/Forms/InventoryCheckForm.jsx`.
class InventoryCheckFormMin extends StatefulWidget {
  const InventoryCheckFormMin({
    super.key,
    required this.item,
    this.operatorName,
    this.onSubmit,
    this.onClose,
  });

  /// The inventory item being checked.
  final InventoryCheckItemSnapshot item;

  /// Operator name (displayed but not submitted).
  final String? operatorName;

  /// Called with the submit payload.
  final ValueChanged<InventoryCheckSubmitPayload>? onSubmit;

  /// Callback for the close/dismiss action.
  final VoidCallback? onClose;

  @override
  State<InventoryCheckFormMin> createState() => _InventoryCheckFormMinState();
}

class _InventoryCheckFormMinState extends State<InventoryCheckFormMin> {
  String _actualQty = '';
  String _remark = '';

  @override
  void initState() {
    super.initState();
    _actualQty = widget.item.stockQty.toString();
  }

  InventoryCheckFormInput get _input => InventoryCheckFormInput(
        actualQty: _actualQty,
        remark: _remark,
      );

  InventoryCheckFormEvaluation get evaluation =>
      InventoryCheckFormRules.evaluate(
        input: _input,
        item: widget.item,
      );

  void _onQtyChanged(num v) {
    setState(() {
      _actualQty = v.toString();
    });
  }

  void _onRemarkChanged(String v) {
    setState(() {
      _remark = v;
    });
  }

  void _handleSubmit() {
    final payload = InventoryCheckFormRules.buildPayload(
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
    final cs = Theme.of(context).colorScheme;
    final ev = evaluation;

    // Diff display color (theme-derived, no hardcoded hex)
    final diffColor = ev.diffQty > 0
        ? cs.primary
        : ev.diffQty < 0
            ? cs.error
            : AppDesignColors.textPrimary;

    // Diff display text
    final diffText = ev.diffQty > 0
        ? '+${ev.diffQty}'
        : '${ev.diffQty}';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Item info card ──
            AppFormSection(
              title: item.itemName.isNotEmpty ? item.itemName : '盘点货物',
              subtitle: '账面数量：${item.stockQty}',
              child: _itemInfoContent(item),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Actual qty stepper ──
            AppStepper(
              value: _parseIntForStepper(_actualQty),
              min: 0,
              max: 99999,
              onChanged: _onQtyChanged,
              label: '盘点真实数量',
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Difference display ──
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
                  Text('差值',
                      style: AppTextStyles.caption.copyWith(
                        color: AppDesignColors.textSecondary,
                      )),
                  const Spacer(),
                  Text(
                    diffText,
                    style: AppTextStyles.title.copyWith(color: diffColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Remark field ──
            AppTextField(
              label: '盘点备注（选填）',
              onChanged: _onRemarkChanged,
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Submit button ──
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: '提交盘点',
                onPressed: ev.canSubmit ? _handleSubmit : null,
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
        _infoRow('货物名称', item.itemName),
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
    if (s.isEmpty) return 0;
    final n = int.tryParse(s);
    return n ?? 0;
  }
}
