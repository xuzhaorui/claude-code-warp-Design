import 'package:flutter/material.dart';

import '../design/app_design_colors.dart';
import '../design/app_radii.dart';
import '../design/app_spacing.dart';
import '../design/app_text_styles.dart';

// ---- AppFormSection-specific constants ----

/// Layout constants specific to AppFormSection.
///
/// `disabledOpacity` (0.5) is the standard Material disabled-activity ratio,
/// consistent with AppSelectCard.
/// `compactVPad` (12px) sits between AppSpacing.sm (8px) and AppSpacing.md
/// (12px); it's the natural vertical padding when compact mode removes the
/// subtitle row's extra height.
class _AFS {
  _AFS._();
  static const disabledOpacity = 0.5;
  static const compactVPad = 12.0;
}

// ---- Public widget ----

/// A themed form-section card that groups a title, optional subtitle,
/// content [child], optional error/actions/footer, and leading/trailing slots.
///
/// Maps to the section-level layout pattern seen in `CheckoutForm.jsx`,
/// `ReturnForm.jsx`, and `InventoryCheckForm.jsx`.  Each form is built from
/// one or more [AppFormSection] cards.
///
/// Uses Design.md `card-muted` tokens (surfaceMuted background, md rounded)
/// for the default appearance.  Colours, typography, spacing and radii all
/// come from Design.md tokens / [AppTheme].
class AppFormSection extends StatelessWidget {
  const AppFormSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.errorText,
    this.disabled = false,
    this.compact = false,
    this.leading,
    this.trailing,
    this.footer,
  });

  /// Section title — always displayed.
  final String title;

  /// Required body content.
  final Widget child;

  /// Optional subtitle displayed below the title.
  final String? subtitle;

  /// Optional action buttons displayed at the bottom of the section.
  final List<Widget>? actions;

  /// When non-null, shows an error message below the child content using
  /// `theme.colorScheme.error` colour.
  final String? errorText;

  /// When true, reduces opacity and applies visual disabled styling.
  final bool disabled;

  /// Compact layout — smaller padding, no subtitle.
  final bool compact;

  /// Optional leading widget (displayed before the title column).
  final Widget? leading;

  /// Optional trailing widget (displayed after the title column).
  final Widget? trailing;

  /// Optional footer widget (displayed after child, before actions).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vPad = compact ? _AFS.compactVPad : AppSpacing.lg;
    final hPad = compact ? AppSpacing.md : AppSpacing.lg;

    return Opacity(
      opacity: disabled ? _AFS.disabledOpacity : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppDesignColors.surfaceMuted,
          borderRadius: BorderRadius.all(AppRadii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header row ──
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (subtitle != null && !compact)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(subtitle!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppDesignColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    trailing!,
                  ],
                ],
              ),
            ),
            // ── Content ──
            Padding(
              padding: EdgeInsets.all(hPad),
              child: child,
            ),
            // ── Error text ──
            if (errorText != null && errorText!.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, vPad),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(errorText!,
                          style: AppTextStyles.caption.copyWith(
                            color: cs.error,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            // ── Footer ──
            if (footer != null)
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, vPad),
                child: footer!,
              ),
            // ── Actions ──
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, vPad),
                child: Row(
                  children: [
                    for (int i = 0; i < actions!.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.md),
                      Expanded(child: actions![i]),
                    ],
                  ],
                ),
              ),
            // ── Bottom spacer ──
            if (actions == null || actions!.isEmpty)
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
