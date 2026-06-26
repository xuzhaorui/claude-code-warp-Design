/// Design token spacing — Exact mapping of Design.md spacing front matter.
///
/// Base spacing is an 8px rhythm with a 4px escape hatch.
/// Flutter rule: direct EdgeInsets.all(17), SizedBox(height: 23) and random
/// dimensions are forbidden. Use token constants unless the dimension is a
/// physical device/system value (safe-area, keyboard inset, camera preview).
class AppSpacing {
  AppSpacing._();

  /// 4px — micro gaps, icon/text gap, divider insets.
  static const xs = 4.0;

  /// 8px — compact vertical spacing, tab/icon stack.
  static const sm = 8.0;

  /// 12px — card internal rhythm, row gap.
  static const md = 12.0;

  /// 16px — normal page padding and form field gap.
  static const lg = 16.0;

  /// 24px — bottom sheet / content section padding.
  static const xl = 24.0;

  /// 32px — large empty-state or splash spacing.
  static const xxl = 32.0;
}
