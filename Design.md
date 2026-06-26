---
version: alpha
name: Warehouse Flutter Parity
description: Machine-readable design contract for migrating the warehouse web app to native Flutter while preserving the existing UI/UX.
colors:
  primary: "#E8986E"
  primary-soft: "#EDE2D5"
  background: "#FFFBF5"
  surface: "#FFFFFF"
  surface-muted: "#F5F0EB"
  text-primary: "#292524"
  text-secondary: "#78716C"
  border-muted: "#E5DED7"
  overlay: "rgba(41, 37, 36, 0.50)"
  scanner-dark: "#0A0A0A"
  scanner-light: "#FFFFFF"
typography:
  display:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: 700
    lineHeight: 36px
    letterSpacing: -0.02em
  title:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: 700
    lineHeight: 30px
    letterSpacing: -0.01em
  body:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: 500
    lineHeight: 24px
    letterSpacing: 0em
  label:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: 600
    lineHeight: 18px
    letterSpacing: 0.02em
  caption:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: 500
    lineHeight: 16px
    letterSpacing: 0em
rounded:
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  pill: 999px
spacing:
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 24px
  xxl: 32px
components:
  app-page:
    backgroundColor: "{colors.background}"
    textColor: "{colors.text-primary}"
    typography: "{typography.body}"
    padding: 16px
  card-default:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text-primary}"
    typography: "{typography.body}"
    rounded: "{rounded.lg}"
    padding: 16px
  card-muted:
    backgroundColor: "{colors.surface-muted}"
    textColor: "{colors.text-primary}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: 16px
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.text-primary}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    height: 52px
    padding: 16px
  button-secondary:
    backgroundColor: "{colors.primary-soft}"
    textColor: "{colors.text-primary}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    height: 48px
    padding: 16px
  input-default:
    backgroundColor: "{colors.surface-muted}"
    textColor: "{colors.text-primary}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    height: 58px
    padding: 16px
  helper-text:
    backgroundColor: "{colors.background}"
    textColor: "{colors.text-secondary}"
    typography: "{typography.caption}"
    rounded: "{rounded.sm}"
    padding: 4px
  bottom-sheet:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text-primary}"
    typography: "{typography.body}"
    rounded: "{rounded.xl}"
    padding: 24px
  segmented-control:
    backgroundColor: "{colors.surface-muted}"
    textColor: "{colors.text-primary}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    height: 44px
    padding: 4px
  segmented-control-active:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.text-primary}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    height: 36px
    padding: 12px
  divider-line:
    backgroundColor: "{colors.border-muted}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.sm}"
    height: 1px
    width: 1px
  modal-overlay:
    backgroundColor: "{colors.overlay}"
    textColor: "{colors.scanner-light}"
    rounded: "{rounded.sm}"
    padding: 0px
  scanner-surface:
    backgroundColor: "{colors.scanner-dark}"
    textColor: "{colors.scanner-light}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: 12px
---

## Overview

This file is the physical design contract for `feature/warehouse-app`.

The branch target is not a refreshed product. The target is a Flutter adaptation of the current warehouse web app with visual and interaction parity. The existing React/Vite UI is the reference implementation; Flutter is the new runtime.

First-principle constraint:

> Do not ask an AI whether the Flutter UI “looks consistent”. Encode consistency as tokens, component mappings, lint commands, analyzer rules, and repeatable gates.

Normative source order:

1. YAML front matter in this file — machine-readable design constants.
2. `design-system.html` — visual reference implementation and component behavior reference.
3. Existing React pages/components — current product interaction reference.
4. Flutter implementation — must consume the same constants; it must not invent a second design system.

Migration intent:

- Preserve the warm terracotta warehouse UI.
- Preserve mobile-first operation rhythm for 375px–428px screens.
- Preserve scanner-first flows: 出库, 归还, 盘点.
- Replace WebView-only dependency gradually with native Flutter screens.
- Make every visual constant traceable to a token.

## Colors

The palette remains the existing warm terracotta system:

- `primary #E8986E` — main action, active tab, selected state, scan highlight, form focus.
- `primary-soft #EDE2D5` — secondary action and soft scan/form surfaces.
- `background #FFFBF5` — app page background.
- `surface #FFFFFF` — cards, sheets, lists, tab shell.
- `surface-muted #F5F0EB` — input background, segmented control base, secondary card.
- `text-primary #292524` — titles, button text on terracotta, high-emphasis content.
- `text-secondary #78716C` — helper text and low-emphasis labels. Use on `background`, not on `surface-muted` when WCAG AA text contrast is required.
- `border-muted #E5DED7` — divider and low-emphasis outline.
- `overlay rgba(41, 37, 36, 0.50)` — bottom-sheet/modal scrim.
- `scanner-dark #0A0A0A` and `scanner-light #FFFFFF` — native scanner full-screen surface and controls.

Flutter mapping:

```dart
class AppDesignColors {
  static const primary = Color(0xFFE8986E);
  static const primarySoft = Color(0xFFEDE2D5);
  static const background = Color(0xFFFFFBF5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF5F0EB);
  static const textPrimary = Color(0xFF292524);
  static const textSecondary = Color(0xFF78716C);
  static const borderMuted = Color(0xFFE5DED7);
  static const scannerDark = Color(0xFF0A0A0A);
  static const scannerLight = Color(0xFFFFFFFF);
  static const overlay = Color(0x80292524);
}
```

Flutter rule: direct `Color(0x...)`, `Colors.orange`, `Colors.brown`, `Colors.grey`, `Colors.white`, and `Colors.black` are forbidden in app UI except inside the generated token file or scanner plugin boundary.

## Typography

Typeface stays `Inter` with system fallback. Flutter should map this into `ThemeData.textTheme`, not per-widget ad hoc styles.

Token usage:

- `display` — splash, major page title, empty-state headline.
- `title` — page section title, sheet title, detail title.
- `body` — form body, list title/subtitle base, normal content.
- `label` — button text, tab label, badge text, input floating label.
- `caption` — helper text, metadata, record timestamp.

Flutter mapping:

```dart
class AppTextStyles {
  static const display = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 36 / 28, letterSpacing: -0.56);
  static const title = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 30 / 22, letterSpacing: -0.22);
  static const body = TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 24 / 16);
  static const label = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 18 / 13, letterSpacing: 0.26);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 16 / 12);
}
```

Flutter rule: no inline `TextStyle(fontSize: ...)` outside `app_text_styles.dart` unless the value is derived from a token and the exception is documented beside the widget.

## Layout & Spacing

Base spacing is an 8px rhythm with a small 4px escape hatch.

- `xs 4px` — micro gaps, icon/text gap, divider insets.
- `sm 8px` — compact vertical spacing, tab/icon stack.
- `md 12px` — card internal rhythm, row gap.
- `lg 16px` — normal page padding and form field gap.
- `xl 24px` — bottom sheet/content section padding.
- `xxl 32px` — large empty-state or splash spacing.

Flutter mapping:

```dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}
```

Mobile invariant:

- Design width: 375px.
- Supported comfortable width: 375px–428px.
- Primary controls must be reachable with one hand.
- Bottom actions must respect safe-area insets.
- Avoid desktop/tablet-first breakpoints during Flutter migration.

Flutter rule: direct `EdgeInsets.all(17)`, `SizedBox(height: 23)`, and random dimensions are forbidden. Use token constants unless the dimension is a physical device/system value such as safe-area, keyboard inset, or camera preview size.

## Elevation & Depth

The existing UI is mostly flat, warm, and tactile. Depth is used to express active selection and sheet layering, not decoration.

Allowed shadows:

- Default cards: none or border-only.
- Active/selected cards: soft shadow equivalent to `0 20px 25px -5px rgba(0, 0, 0, 0.10)`.
- Bottom sheet: scrim + top radius, not heavy drop shadow.
- Scanner: no shadow; use contrast and overlay geometry.

Flutter mapping:

```dart
class AppElevation {
  static const none = 0.0;
  static const selected = 8.0;
  static const sheet = 0.0;
}
```

Flutter rule: `BoxShadow` is not allowed unless it maps to `selected` state or a documented bottom-sheet exception.

## Shapes

Radii preserve the previous UI feel:

- `sm 8px` — list items, small image/scan chips, internal controls.
- `md 16px` — input fields, selection cards, normal cards.
- `lg 24px` — primary cards and large panels.
- `xl 32px` — bottom sheet top corners and prominent containers.
- `pill 999px` — buttons, segmented controls, scanner toolbar buttons.

Flutter mapping:

```dart
class AppRadii {
  static const sm = Radius.circular(8);
  static const md = Radius.circular(16);
  static const lg = Radius.circular(24);
  static const xl = Radius.circular(32);
  static const pill = Radius.circular(999);
}
```

Flutter rule: direct `BorderRadius.circular(...)` outside `app_radii.dart` is forbidden except for plugin camera-preview clipping when documented.

## Components

Component migration map:

| Web reference | Flutter target | Contract |
| --- | --- | --- |
| `AppShell.jsx` | `WarehouseShell` | Same bottom-tab rhythm, warm background, no desktop layout. |
| `CheckoutTab.jsx` | `CheckoutPage` | Scanner-first flow, same primary action hierarchy. |
| `ReturnTab.jsx` | `ReturnPage` | Same record/detail rhythm as web. |
| `InventoryTab.jsx` | `InventoryPage` | Same check-card and status feedback logic. |
| `BottomSheet/*` | `AppBottomSheet` | 50% warm dark overlay, top radius `xl`, drag-to-dismiss physics. |
| `Forms/*` | `AppTextField`, `AppSelectCard`, flow-specific forms | Same floating-label/input behavior. |
| `Records/RecordCard.jsx` | `RecordCard` | Same title/subtitle/timestamp hierarchy. |
| `Scanner/ScannerOverlay.jsx` | `ScannerPage` overlay widgets | Native scanner may differ internally, but visual controls must use tokens. |
| `Settings/*` | `SettingsPage` | Same list cell hierarchy and server-config interaction. |
| `Splash/*` | `SplashPage` | Same launch brand color, timing, and page transition intent. |

Motion contract for Flutter:

- Tap feedback: scale to `0.96`; delay must feel under 50ms.
- Bottom sheet enter: `y: 100% -> 0`, scrim opacity `0 -> 0.50`.
- Gesture dismiss threshold: close when drag distance exceeds `150px` or downward velocity exceeds `500px/s`.
- Segmented control active state must move, not flash.
- Lists may stagger at `index * 50ms`, but must not block operation.

Native Flutter implementation boundary:

- The current `WebShellPage` can remain as a compatibility bridge during migration.
- New UI code should live under `flutter_shell/lib/` and consume generated or hand-maintained token constants.
- Do not use Material default colors as product identity.
- Do not introduce a second visual language while converting from web to Flutter.

Physical gates:

```bash
npm run design:lint
npm run physical:lint
cd flutter_shell && flutter analyze
```

`design:lint` is the first gate. If it fails, do not ask an AI whether the design is acceptable; fix the broken token, section order, reference, or contrast finding.

Recommended local file structure for Flutter migration:

```text
flutter_shell/lib/design/app_design_colors.dart
flutter_shell/lib/design/app_text_styles.dart
flutter_shell/lib/design/app_spacing.dart
flutter_shell/lib/design/app_radii.dart
flutter_shell/lib/design/app_theme.dart
flutter_shell/lib/components/
flutter_shell/lib/pages/
```

## Do's and Don'ts

Do:

- Use this file as the first design input for every Flutter UI task.
- Run `npm run design:lint` before implementation and after design-token changes.
- Keep the web app and Flutter app visually traceable to the same token names.
- Build small Flutter components that can be inspected independently.
- Treat analyzer/linter output as the evaluator.
- Escalate to a stronger model only after three failed physical attempts with logs.

Don't:

- Do not ask an AI to “make it more consistent” without changing tokens or lintable rules.
- Do not hard-code new colors, spacing, radii, or text sizes in Flutter widgets.
- Do not switch to Material default blue, default grey, or random Android platform styling.
- Do not redesign the product during migration.
- Do not judge Flutter parity by prose alone; use token lint, analyzer, screenshots, and human spot checks.
- Do not keep WebView as the final architecture if the explicit task is native Flutter adaptation.

Agent execution loop:

```text
Intent -> DESIGN.md token contract -> design.md lint -> Flutter token constants -> Flutter screens -> flutter analyze -> screenshot / human spot check -> iterate
```

Failure policy:

- 1st failure: read the linter/analyzer error and fix directly.
- 2nd failure: inspect the exact file and token/component boundary.
- 3rd failure: package the failing command, output, changed files, and this contract for top-model review.
