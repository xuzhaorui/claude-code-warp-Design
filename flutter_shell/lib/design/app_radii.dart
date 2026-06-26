import 'package:flutter/painting.dart';

/// Design token radii — exact mapping of Design.md rounded front matter.
///
/// Flutter rule: direct BorderRadius.circular(…) outside this file is
/// forbidden except for plugin camera-preview clipping when documented.
class AppRadii {
  AppRadii._();

  /// 8px — list items, small image/scan chips, internal controls.
  static const sm = Radius.circular(8);

  /// 16px — input fields, selection cards, normal cards.
  static const md = Radius.circular(16);

  /// 24px — primary cards and large panels.
  static const lg = Radius.circular(24);

  /// 32px — bottom sheet top corners and prominent containers.
  static const xl = Radius.circular(32);

  /// 999px — buttons, segmented controls, scanner toolbar buttons.
  static const pill = Radius.circular(999);
}
