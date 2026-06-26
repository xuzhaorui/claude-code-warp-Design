import 'package:flutter/painting.dart';

/// Design token colors — exact mapping of Design.md colors front matter.
///
/// Flutter rule: direct Color(0x…), Colors.orange, Colors.brown, Colors.grey,
/// Colors.white, and Colors.black are forbidden in app UI except inside this
/// file or scanner plugin boundary.
class AppDesignColors {
  AppDesignColors._();

  /// Main action, active tab, selected state, scan highlight, form focus.
  static const primary = Color(0xFFE8986E);

  /// Secondary action and soft scan/form surfaces.
  static const primarySoft = Color(0xFFEDE2D5);

  /// App page background.
  static const background = Color(0xFFFFFBF5);

  /// Cards, sheets, lists, tab shell.
  static const surface = Color(0xFFFFFFFF);

  /// Input background, segmented control base, secondary card.
  static const surfaceMuted = Color(0xFFF5F0EB);

  /// Titles, button text on terracotta, high-emphasis content.
  static const textPrimary = Color(0xFF292524);

  /// Helper text and low-emphasis labels.
  static const textSecondary = Color(0xFF78716C);

  /// Divider and low-emphasis outline.
  static const borderMuted = Color(0xFFE5DED7);

  /// Native scanner full-screen dark surface.
  static const scannerDark = Color(0xFF0A0A0A);

  /// Native scanner full-screen light controls.
  static const scannerLight = Color(0xFFFFFFFF);

  /// Bottom-sheet/modal scrim — rgba(41, 37, 36, 0.50).
  static const overlay = Color(0x80292524);
}
