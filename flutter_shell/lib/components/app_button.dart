import 'package:flutter/material.dart';

import '../design/app_design_colors.dart';
import '../design/app_spacing.dart';
import '../design/app_text_styles.dart';

// ---- AppButton-specific constants ----

/// Layout and animation constants specific to AppButton.
///
/// `iconSize` (18px) matches the typical icon size used in the web warehouse
/// app and aligns with Material's default icon size in button context.
/// `spinnerStroke` (2.5) provides a visible but non-dominant loading indicator.
class _AB {
  _AB._();
  static const iconSize = 18.0;
  static const spinnerStroke = 2.5;
}

// ---- Variant enum ----

/// Visual variant for [AppButton].
enum AppButtonVariant {
  /// Primary action — filled pill with `primary` (#E8986E) background,
  /// `textPrimary` (#292524) label.  Height 52px (via theme `elevatedButtonTheme`).
  primary,

  /// Secondary action — filled pill with `primarySoft` (#EDE2D5) background,
  /// `textPrimary` (#292524) label.  Height 48px (via theme `filledButtonTheme`).
  secondary,
}

// ---- Public widget ----

/// A themed action button mapped to Design.md `button-primary` and
/// `button-secondary` tokens.
///
/// All colours, typography, spacing and radii come from Design.md tokens /
/// [AppTheme].  Component-local constants are in [_AB].
///
/// Loading / disabled: both pass `onPressed: null` to the underlying Material
/// button, so neither state accepts tap events.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.disabled = false,
    this.onPressed,
  });

  /// Button label text.
  final String text;

  /// Visual variant — [AppButtonVariant.primary] or [AppButtonVariant.secondary].
  final AppButtonVariant variant;

  /// Optional leading icon (shown left of label).
  final IconData? icon;

  /// When true, shows a [CircularProgressIndicator] in place of the label
  /// and disables tap interaction.
  final bool loading;

  /// When true, disables tap interaction.  Visual styling follows the
  /// Material theme's disabled appearance for the chosen variant.
  final bool disabled;

  /// Tap callback.  Not called while [loading] or [disabled] is true.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed =
        (loading || disabled) ? null : onPressed;

    return variant == AppButtonVariant.primary
        ? ElevatedButton(
            onPressed: effectiveOnPressed,
            child: _buildChild(context),
          )
        : FilledButton(
            onPressed: effectiveOnPressed,
            child: _buildChild(context),
          );
  }

  Widget _buildChild(BuildContext context) {
    if (loading) {
      // Show only a small spinner when loading.
      return SizedBox(
        width: AppTextStyles.label.fontSize! * 1.5,
        height: AppTextStyles.label.fontSize! * 1.5,
        child: CircularProgressIndicator(
          strokeWidth: _AB.spinnerStroke,
          valueColor: AlwaysStoppedAnimation(AppDesignColors.textPrimary),
        ),
      );
    }

    final label = Text(text, style: AppTextStyles.label);

    if (icon == null) return label;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: _AB.iconSize),
        SizedBox(width: AppSpacing.sm),
        label,
      ],
    );
  }
}
