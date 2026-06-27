import 'package:flutter/material.dart';

import '../design/app_design_colors.dart';
import '../design/app_radii.dart';
import '../design/app_spacing.dart';
import '../design/app_text_styles.dart';

// ---- AppBottomSheet-specific constants ----

/// Layout constants specific to AppBottomSheetFrame and showAppBottomSheet.
///
/// These derive from the Web FormSheet/DetailSheet dimensions:
///   dragHandleWidth  (40px) — w-10 in Tailwind
///   dragHandleHeight (4px)  — h-1 in Tailwind
///   closeIconSize    (20px) — lucide-react X size={20}
///   defaultMaxHeightFactor (0.9) — max-h-[90vh] in Tailwind
class _ABS {
  _ABS._();
  static const dragHandleWidth = 40.0;
  static const dragHandleHeight = 4.0;
  static const closeIconSize = 20.0;
  static const defaultMaxHeightFactor = 0.9;
}

// ---- Public widget ----

/// The content frame for a bottom sheet.  Use [showAppBottomSheet] to
/// display it modally, or embed directly in tests.
///
/// Maps to Web `FormSheet.jsx` / `DetailSheet.jsx`.  All colours, typography,
/// spacing, radii, and overlay come from Design.md tokens / [AppTheme].
/// Component-local constants are in [_ABS].
///
/// Layout:
/// ```text
/// ┌──────────────────────────┐  ← rounded top-left/right (AppRadii.xl)
/// │          ═══             │  ← drag handle (optional)
/// │  Title            [✕]   │  ← header (close button optional)
/// │  Subtitle               │  ← subtitle (optional)
/// │─────────────────────────│  ← divider (borderMuted)
/// │                         │
/// │  Child content          │  ← scrollable (optional), max 90% viewport
/// │                         │
/// │─────────────────────────│  ← divider (borderMuted, only with actions)
/// │  [Action 1]  [Action 2] │  ← actions bar (optional)
/// └──────────────────────────┘
/// ```
class AppBottomSheetFrame extends StatelessWidget {
  const AppBottomSheetFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.showDragHandle = true,
    this.showCloseButton = true,
    this.scrollable = true,
    this.safeArea = true,
    this.maxHeightFactor,
    this.onClose,
  });

  /// Sheet title — shown in the header row.
  final String title;

  /// The main body content.
  final Widget child;

  /// Optional subtitle displayed below the title.
  final String? subtitle;

  /// Optional action buttons displayed at the bottom of the sheet.
  final List<Widget>? actions;

  /// Whether to show a drag-handle pill at the top (default true).
  final bool showDragHandle;

  /// Whether to show a close (✕) button in the header (default true).
  final bool showCloseButton;

  /// Whether the content area is scrollable (default true).
  final bool scrollable;

  /// Whether to apply [SafeArea] (default true).
  final bool safeArea;

  /// Max height as a fraction of the viewport height (default 0.9).
  final double? maxHeightFactor;

  /// Callback when the close button is tapped.  When non-null and
  /// [showCloseButton] is true, the close button invokes this.
  /// Typically used to pop the route or dismiss the sheet.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxFactor = maxHeightFactor ?? _ABS.defaultMaxHeightFactor;

    Widget frame = Container(
      decoration: const BoxDecoration(
        color: AppDesignColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: AppRadii.xl,
          topRight: AppRadii.xl,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          if (showDragHandle)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Container(
                width: _ABS.dragHandleWidth,
                height: _ABS.dragHandleHeight,
                decoration: BoxDecoration(
                  color: AppDesignColors.borderMuted,
                  borderRadius: BorderRadius.all(Radius.circular(_ABS.dragHandleHeight / 2)),
                ),
              ),
            ),
          // ── Header: title + close ──
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              showDragHandle ? AppSpacing.sm : AppSpacing.xl,
              AppSpacing.xl,
              subtitle != null ? 0 : AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: AppTextStyles.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (showCloseButton) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _CloseButton(onTap: onClose),
                ],
              ],
            ),
          ),
          // ── Subtitle ──
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(subtitle!,
                        style: AppTextStyles.body.copyWith(
                          color: AppDesignColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          // ── Top divider ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Divider(
              color: AppDesignColors.borderMuted,
              height: 1,
              thickness: 1,
            ),
          ),
          // ── Content ──
          Expanded(
            child: scrollable
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: child,
                  )
                : Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: child,
                  ),
          ),
          // ── Actions ──
          if (actions != null && actions!.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Divider(
                color: AppDesignColors.borderMuted,
                height: 1,
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  for (int i = 0; i < actions!.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(child: actions![i]),
                  ],
                ],
              ),
            ),
          ],
          // ── Bottom safe-area spacer ──
          const SizedBox(height: 8),
        ],
      ),
    );

    if (safeArea) {
      frame = SafeArea(
        top: false,
        bottom: true,
        child: frame,
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: mq.size.height * maxFactor,
      ),
      child: frame,
    );
  }
}

// ---- Private close button ----

class _CloseButton extends StatelessWidget {
  const _CloseButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onTap,
        iconSize: _ABS.closeIconSize,
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.close, color: AppDesignColors.textSecondary),
        splashRadius: 18,
      ),
    );
  }
}

// ---- Show helper ----

/// Shows an [AppBottomSheetFrame] in a modal bottom sheet.
///
/// All parameters are forwarded to [AppBottomSheetFrame].
/// The sheet is dismissed when the close button or barrier is tapped.
/// Returns `null`.
Future<void> showAppBottomSheet({
  required BuildContext context,
  required String title,
  required Widget child,
  String? subtitle,
  List<Widget>? actions,
  bool showDragHandle = true,
  bool showCloseButton = true,
  bool scrollable = true,
  bool safeArea = true,
  double? maxHeightFactor,
  bool useSafeArea = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppDesignColors.overlay,
    builder: (_) => AppBottomSheetFrame(
      title: title,
      subtitle: subtitle,
      actions: actions,
      showDragHandle: showDragHandle,
      showCloseButton: showCloseButton,
      scrollable: scrollable,
      safeArea: safeArea,
      maxHeightFactor: maxHeightFactor,
      onClose: () => Navigator.of(context).pop(),
      child: child,
    ),
  );
}
