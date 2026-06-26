import 'package:flutter/painting.dart';

/// Design token text styles — exact mapping of Design.md typography front matter.
///
/// Flutter rule: no inline TextStyle(fontSize: …) outside this file unless the
/// value is derived from a token and the exception is documented beside the widget.
class AppTextStyles {
  AppTextStyles._();

  /// Splash, major page title, empty-state headline.
  /// 28px / 700w / 36px line-height / -0.56em letter-spacing
  static const display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
    letterSpacing: -0.56,
  );

  /// Page section title, sheet title, detail title.
  /// 22px / 700w / 30px line-height / -0.22em letter-spacing
  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 30 / 22,
    letterSpacing: -0.22,
  );

  /// Form body, list title/subtitle base, normal content.
  /// 16px / 500w / 24px line-height
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 24 / 16,
  );

  /// Button text, tab label, badge text, input floating label.
  /// 13px / 600w / 18px line-height / 0.26em letter-spacing
  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 18 / 13,
    letterSpacing: 0.26,
  );

  /// Helper text, metadata, record timestamp.
  /// 12px / 500w / 16px line-height
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
  );
}
