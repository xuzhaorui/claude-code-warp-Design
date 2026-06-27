import 'package:flutter/material.dart';

import '../design/app_design_colors.dart';
import '../design/app_radii.dart';
import '../design/app_spacing.dart';
import '../design/app_text_styles.dart';

// ---- AppSelectCard-specific constants ----

/// Layout constants specific to AppSelectCard.
///
/// `iconSize` (18px) is consistent with AppButton and RecordCard icon scale.
/// `compactVPad` (12px) sits between AppSpacing.sm (8px) and AppSpacing.md
/// (12px); it's the natural card vertical padding when compact mode
/// removes the subtitle row's extra height.
/// `disabledOpacity` (0.5) is a standard Material disabled-activity ratio,
/// not a random value.
class _ASC {
  _ASC._();
  static const iconSize = 18.0;
  static const checkIconSize = 20.0;
  static const compactVPad = 12.0;
  static const disabledOpacity = 0.5;
}

// ---- Public widget ----

/// A themed selectable card mapped to Design.md `card-muted` and
/// `card-default` tokens, with visual states for selected / disabled / error.
///
/// Maps to Web selection patterns in `BorrowerSelect.jsx` and
/// `ServerConfig.jsx`.  All colours, typography, spacing and radii come from
/// Design.md tokens / [AppTheme].  Component-local constants in [_ASC].
///
/// States:
///   default   → surfaceMuted background, borderMuted border
///   selected  → primarySoft background, primary border, primary check icon
///   error     → surfaceMuted background, error-coloured border
///   disabled  → opacity 0.5, no tap interaction
class AppSelectCard extends StatelessWidget {
  const AppSelectCard({
    super.key,
    required this.title,
    this.subtitle,
    this.selected = false,
    this.disabled = false,
    this.error = false,
    this.leadingIcon,
    this.trailing,
    this.onTap,
    this.compact = false,
  });

  /// Primary text — always displayed.
  final String title;

  /// Optional subtitle/description line.
  final String? subtitle;

  /// When true, highlights the card with `primarySoft` background and a check
  /// icon (or custom [trailing]) in `primary`.
  final bool selected;

  /// When true, reduces opacity and prevents tap interaction.
  final bool disabled;

  /// When true, applies an error-coloured border via
  /// `colorScheme.error`.
  final bool error;

  /// Optional leading icon (displayed left of the text column).
  final IconData? leadingIcon;

  /// Custom trailing widget.  When null, a check icon is shown if [selected],
  /// otherwise nothing.
  final Widget? trailing;

  /// Tap callback.  Not called while [disabled] is true.
  final VoidCallback? onTap;

  /// Compact layout — smaller vertical padding, no subtitle gap exaggerating.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveOnTap = disabled ? null : onTap;
    final bgColor = selected
        ? AppDesignColors.primarySoft
        : AppDesignColors.surfaceMuted;

    final borderColor = error
        ? cs.error
        : selected
            ? AppDesignColors.primary
            : AppDesignColors.borderMuted;

    final vPad = compact ? _ASC.compactVPad : AppSpacing.lg;
    final hPad = compact ? AppSpacing.md : AppSpacing.lg;

    return Opacity(
      opacity: disabled ? _ASC.disabledOpacity : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.all(AppRadii.md),
          border: Border.all(color: borderColor),
        ),
        child: InkWell(
          onTap: effectiveOnTap,
          borderRadius: BorderRadius.all(AppRadii.md),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: vPad,
              horizontal: hPad,
            ),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon,
                      size: _ASC.iconSize,
                      color: AppDesignColors.textPrimary),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(child: _textColumn()),
                const SizedBox(width: AppSpacing.sm),
                _trailingOrCheck(cs),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        if (subtitle != null && !compact)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(subtitle!,
                style: AppTextStyles.caption
                    .copyWith(color: AppDesignColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }

  Widget _trailingOrCheck(ColorScheme cs) {
    if (trailing != null) return trailing!;

    if (selected) {
      return Icon(Icons.check_circle,
          size: _ASC.checkIconSize, color: AppDesignColors.primary);
    }

    return const SizedBox(width: _ASC.checkIconSize);
  }
}
