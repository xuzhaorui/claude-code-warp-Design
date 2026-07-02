import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/app_design_colors.dart';
import '../design/app_radii.dart';
import '../design/app_spacing.dart';
import '../design/app_text_styles.dart';

// ---- Component-local constants ----
//
// Per Design.md, component-local numeric constants (panel width, badge
// rotation/skew, stepper button sizes) are allowed when mirroring the Web
// layout and not promoting a new design token.
class _FW {
  _FW._();
  static const leftPanelWidth = 135.0;
  static const badgeRotate = -0.017; // ~ -1deg, Web rotate(-1deg)
  static const badgeSkew = -0.087; // ~ -5deg, Web skewX(-5deg)
  static const badgeInnerSkew = 0.14; // ~ +8deg, Web skewX(8deg) on text
  static const stepperBtnSize = 36.0;
  static const submitHeight = 52.0;
}

/// Left item-info panel for the two-column business forms.
///
/// Fixed 135px width, white surface, right divider, vertically scrollable.
/// Mirrors Web `CheckoutForm/ReturnForm/InventoryCheckForm` left panel.
class ItemInfoPanel extends StatelessWidget {
  const ItemInfoPanel({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _FW.leftPanelWidth,
      decoration: const BoxDecoration(
        color: AppDesignColors.surface,
        border: Border(right: BorderSide(color: AppDesignColors.borderMuted)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

/// Rotated/skewed orange badge with a label above it (Web `BadgeField`).
///
/// Used in the left panel for 库存 / 在借数量 / 账面数量.
class StockBadge extends StatelessWidget {
  const StockBadge({
    super.key,
    required this.label,
    required this.value,
  });
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: AppTextStyles.caption.copyWith(
              color: AppDesignColors.textSecondary,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: AppSpacing.xs),
        Transform.rotate(
          angle: _FW.badgeRotate,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppDesignColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.skewX(_FW.badgeSkew),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppDesignColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.skewX(_FW.badgeInnerSkew),
                  child: Text(
                    value,
                    style: AppTextStyles.title.copyWith(
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: AppDesignColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Cost-price badge for the return form (Web `CostBadge`).
///
/// Same rotated-badge style as [StockBadge] but with a 成本单价 label and a
/// ¥-prefixed value. Shown in the right panel when `showCostPrice` is true.
class CostBadge extends StatelessWidget {
  const CostBadge({super.key, required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    return StockBadge(label: '成本单价', value: value);
  }
}

/// Label / value field in the left item-info panel (Web `InfoField`).
class InfoField extends StatelessWidget {
  const InfoField({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: AppTextStyles.body.copyWith(
              color: AppDesignColors.textSecondary,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value.isEmpty ? '-' : value,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Black-accent quantity stepper (Web `Stepper`).
///
/// h56 surfaceMuted container, floating primary label, gray − button +
/// center input + black + button.  Tap-to-step (hold-to-repeat omitted).
///
/// Uses an externally-owned [controller] so the parent can manage cursor
/// position and avoid TextEditingController recreation on each rebuild.
class BlackStepper extends StatelessWidget {
  const BlackStepper({
    super.key,
    required this.label,
    required this.controller,
    required this.min,
    required this.max,
    required this.onChanged,
    this.error = false,
  });
  final String label;
  final TextEditingController controller;
  final int min;
  final int max;
  final ValueChanged<num> onChanged;
  final bool error;

  int get _current {
    final val = controller.text;
    if (val.isEmpty) return min;
    return int.tryParse(val) ?? min;
  }

  void _step(int dir) {
    final next = (_current + dir).clamp(min, max);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesignColors.surfaceMuted,
        borderRadius: BorderRadius.all(AppRadii.md),
        border: error
            ? Border.all(color: Theme.of(context).colorScheme.error, width: 2)
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: AppDesignColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              _roundButton(glyph: '−', onTap: () => _step(-1), dark: false),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _roundButton(glyph: '+', onTap: () => _step(1), dark: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundButton({required String glyph, required VoidCallback onTap, required bool dark}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: _FW.stepperBtnSize,
        height: _FW.stepperBtnSize,
        decoration: BoxDecoration(
          color: dark ? AppDesignColors.primary : AppDesignColors.borderMuted,
          borderRadius: BorderRadius.all(AppRadii.sm),
        ),
        child: Center(
          child: Text(
            glyph,
            style: AppTextStyles.title.copyWith(
              fontWeight: FontWeight.w700,
              color: dark ? AppDesignColors.textPrimary : AppDesignColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width submit button (Web `提交`/`确认归还`/`提交盘点`).
///
/// primary (#E8986E) background, textPrimary (#292524) text, pill shape,
/// 40% opacity when disabled.
class BlackSubmitButton extends StatelessWidget {
  const BlackSubmitButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
  });
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: SizedBox(
        width: double.infinity,
        height: _FW.submitHeight,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppDesignColors.primary,
            foregroundColor: AppDesignColors.textPrimary,
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          child: loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppDesignColors.textPrimary),
                  ),
                )
              : Text(text, style: AppTextStyles.title),
        ),
      ),
    );
  }
}
