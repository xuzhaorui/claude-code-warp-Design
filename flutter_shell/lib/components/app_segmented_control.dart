import 'package:flutter/material.dart';

import '../design/app_design_colors.dart';
import '../design/app_radii.dart';
import '../design/app_text_styles.dart';

// ---- AppSegmentedControl-specific constants ----

/// Layout constants derived from Design.md `segmented-control` /
/// `segmented-control-active` component tokens.
class _SC {
  _SC._();
  static const containerHeight = 44.0;
  static const containerPad = 4.0;
  static const activeHeight = 36.0;
  static const activePadH = 12.0;
  static const compactContainerPad = 2.0;
  static const compactActivePadH = 8.0;
}

// ---- Option data class ----

/// A single option within [AppSegmentedControl].
class AppSegmentedOption<T> {
  const AppSegmentedOption({required this.value, required this.label});

  /// The underlying value returned via [AppSegmentedControl.onChanged].
  final T value;

  /// Human-readable label displayed in the control.
  final String label;
}

// ---- Public widget ----

/// A themed segmented control mapped to Design.md `segmented-control` and
/// `segmented-control-active` tokens.
///
/// Maps to the method-selector (`外销` / `外借`) in `CheckoutForm.jsx` and
/// similar toggle patterns.  All colours, typography, spacing and radii come
/// from Design.md tokens.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.disabled = false,
    this.compact = false,
  });

  /// The list of options.  When empty, an empty [SizedBox] is rendered.
  final List<AppSegmentedOption<T>> options;

  /// Currently selected value (must equal one of [options] values).
  final T selectedValue;

  /// Called when a different option is tapped.
  final ValueChanged<T> onChanged;

  /// When true, prevents tap interaction.
  final bool disabled;

  /// Compact layout — reduced internal padding.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    final cPad = compact ? _SC.compactContainerPad : _SC.containerPad;
    final aPadH = compact ? _SC.compactActivePadH : _SC.activePadH;
    final effectiveHeight = _SC.containerHeight;

    return Container(
      height: effectiveHeight,
      decoration: BoxDecoration(
        color: AppDesignColors.surfaceMuted,
        borderRadius: BorderRadius.all(AppRadii.pill),
      ),
      padding: EdgeInsets.all(cPad),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt.value == selectedValue;
          return Expanded(
            child: _buildOption(
              option: opt,
              isSelected: isSelected,
              aPadH: aPadH,
              onTap: disabled
                  ? null
                  : () {
                      if (!isSelected) onChanged(opt.value);
                    },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOption({
    required AppSegmentedOption<T> option,
    required bool isSelected,
    required double aPadH,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _SC.activeHeight,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: aPadH),
        decoration: BoxDecoration(
          color: isSelected ? AppDesignColors.primary : Colors.transparent,
          borderRadius: BorderRadius.all(AppRadii.pill),
        ),
        child: Text(
          option.label,
          style: AppTextStyles.label.copyWith(
            color: isSelected
                ? AppDesignColors.textPrimary
                : AppDesignColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
