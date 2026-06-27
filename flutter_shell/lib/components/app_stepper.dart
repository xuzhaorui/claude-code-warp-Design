import 'package:flutter/material.dart';

import '../design/app_design_colors.dart';
import '../design/app_radii.dart';
import '../design/app_spacing.dart';
import '../design/app_text_styles.dart';

// ---- AppStepper-specific constants ----

/// Layout constants specific to AppStepper.
///
/// These derive from Web Stepper.jsx dimensions:
///   containerHeight (56px) — h-14 in Tailwind
///   btnSize         (44px) — w-11 h-11 in Tailwind
///   btnIconSize     (22px) — text-[22px] in Tailwind
///   labelOffsetY    (-8px) — -top-2 in Tailwind, half the caption line-height
///   labelPadH        (4px) — horizontal padding for the floating label pill
class _AS {
  _AS._();
  static const containerHeight = 56.0;
  static const btnSize = 44.0;
  static const btnIconSize = 22.0;
  static const labelOffsetY = -8.0;
  static const labelPadH = 4.0;
}

// ---- Public widget ----

/// A numeric stepper widget with decrement / display / increment controls.
///
/// Maps to Web `Stepper.jsx`.  All colours, typography, spacing, and radii
/// come from Design.md tokens / [AppTheme].  Component-local constants are
/// in [_AS].
///
/// The stepper clamps [value] between [min] and [max] on every user
/// interaction.  If the initial [value] is outside bounds, the first
/// increment or decrement brings it within range; the controller / parent
/// is responsible for initial validation.
///
/// Long-press acceleration (present in Web Stepper.jsx) is deferred per
/// iteration scope — it can be added in a follow-up without breaking
/// the public API.
class AppStepper extends StatelessWidget {
  const AppStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 9999,
    this.step = 1,
    this.disabled = false,
    this.label,
    this.helperText,
  });

  /// Current numeric value.
  final num value;

  /// Called with the new value after increment/decrement.
  final ValueChanged<num>? onChanged;

  /// Minimum allowed value (default 1).
  final num min;

  /// Maximum allowed value (default 9999).
  final num max;

  /// Step increment/decrement amount (default 1).
  final num step;

  /// When true, buttons are disabled and interactions are blocked.
  final bool disabled;

  /// Floating label displayed at the top-left edge of the stepper.
  final String? label;

  /// Helper text displayed below the stepper (12px, secondary colour).
  final String? helperText;

  bool get _canDecrement => value > min && !disabled;
  bool get _canIncrement => value < max && !disabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Stepper control row ──
        SizedBox(
          height: _AS.containerHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background container
              Container(
                height: _AS.containerHeight,
                decoration: BoxDecoration(
                  color: AppDesignColors.surfaceMuted,
                  borderRadius: BorderRadius.all(AppRadii.md),
                ),
                child: Row(
                  children: [
                    // Decrease button
                    _StepperButton(
                      label: '−',
                      size: _AS.btnSize,
                      iconSize: _AS.btnIconSize,
                      enabled: _canDecrement,
                      bgColor: cs.surfaceContainerHighest,
                      fgColor: AppDesignColors.textPrimary,
                      onTap: () => _stepDir(context, -1),
                    ),
                    // Value display (flex-1)
                    Expanded(
                      child: Center(
                        child: Text(
                          '$value',
                          style: AppTextStyles.title,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Increase button
                    _StepperButton(
                      label: '+',
                      size: _AS.btnSize,
                      iconSize: _AS.btnIconSize,
                      enabled: _canIncrement,
                      bgColor: AppDesignColors.textPrimary,
                      fgColor: AppDesignColors.scannerLight,
                      onTap: () => _stepDir(context, 1),
                    ),
                  ],
                ),
              ),
              // Floating label
              if (label != null)
                Positioned(
                  top: _AS.labelOffsetY,
                  left: _AS.containerHeight * 0.25,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: _AS.labelPadH),
                    color: AppDesignColors.surfaceMuted,
                    child: Text(
                      label!,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppDesignColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // ── Helper text ──
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.xs),
            child: Text(
              helperText!,
              style: AppTextStyles.caption.copyWith(
                color: AppDesignColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  void _stepDir(BuildContext context, int dir) {
    if (disabled) return;
    final raw = value + dir * step;
    final clamped = raw.clamp(min, max);
    if (clamped != value) {
      onChanged?.call(clamped);
    }
  }
}

// ---- Private stepper button ----

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.label,
    required this.size,
    required this.iconSize,
    required this.enabled,
    required this.bgColor,
    required this.fgColor,
    required this.onTap,
  });

  final String label;
  final double size;
  final double iconSize;
  final bool enabled;
  final Color bgColor;
  final Color fgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: enabled ? onTap : null,
        iconSize: iconSize,
        padding: EdgeInsets.zero,
        icon: Text(
          label,
          style: AppTextStyles.title.copyWith(
            color: enabled ? fgColor : fgColor.withValues(alpha: 0.4),
          ),
        ),
        splashRadius: size * 0.4,
      ),
    );
  }
}
