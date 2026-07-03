import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../design/app_design_colors.dart';
import '../features/scanner/scanner_adapter.dart';

/// Result popped back to caller when a code is decoded (legacy mode).
class ScanResult {
  final String text;
  final String format;
  const ScanResult({required this.text, required this.format});
}

/// Full-screen native scanner backed by mobile_scanner (CameraX / ML Kit).
///
/// When [adapter] is provided, detected barcodes are forwarded to
/// [onScanResult] / [onScanFailure] callbacks.
/// The outer widget is expected to call [Navigator.pop] from the
/// onScanResult / onClose handlers using the scanner's own context.
///
/// A [_completed] guard prevents double-fire.
class ScannerPage extends StatefulWidget {
  final ScannerAdapter? adapter;
  final ValueChanged<String>? onScanResult;
  final ValueChanged<ScannerFailure>? onScanFailure;
  final VoidCallback? onClose;
  final String mode;

  const ScannerPage({
    super.key,
    this.adapter,
    this.onScanResult,
    this.onScanFailure,
    this.onClose,
    this.mode = '',
  });

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
    autoZoom: true,
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.itf14,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  /// Guards against double-fire from scanner callback or adapter stream.
  bool _completed = false;
  StreamSubscription<ScannerResult>? _resultSub;
  StreamSubscription<ScannerFailure>? _failureSub;

  @override
  void initState() {
    super.initState();
    debugPrint('[ScannerPage] init, adapter=${widget.adapter.runtimeType}');
    _setupAdapter();
  }

  void _setupAdapter() {
    final adapter = widget.adapter;
    if (adapter == null) return;

    _resultSub = adapter.results.listen((result) {
      if (_completed) return;
      _completed = true;
      debugPrint('[ScannerPage] adapter result: ${result.code}');
      _playSuccessFeedback();
      widget.onScanResult?.call(result.code);
    });

    _failureSub = adapter.failures.listen((failure) {
      widget.onScanFailure?.call(failure);
    });
  }

  /// Plays the scan-success feedback: a haptic buzz + a system click sound.
  ///
  /// Uses [HapticFeedback.heavyImpact] for a strong tap on devices that
  /// support amplitude-controlled vibration, then [HapticFeedback.vibrate]
  /// as a guaranteed fallback (some Android OEMs ignore `heavyImpact` but
  /// always honour the plain vibrate API).  The system click sound provides
  /// audible confirmation.
  ///
  /// Called from both the adapter-stream path and the onDetect path.
  Future<void> _playSuccessFeedback() async {
    await HapticFeedback.heavyImpact();
    await HapticFeedback.vibrate();
    await SystemSound.play(SystemSoundType.click);
  }

  @override
  void dispose() {
    debugPrint('[ScannerPage] dispose');
    _resultSub?.cancel();
    _failureSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Focus window: a centered square of side = min(screenW, screenH) * 0.6.
  /// Stored as normalized rect [0..1] in image space, computed lazily.
  static const _windowFraction = 0.6;

  /// Returns true if the barcode's center falls inside the focus window.
  /// Both the barcode corners and the window are compared in normalized
  /// [0..1] image coordinates.
  bool _isInsideFocusWindow(Barcode barcode, Size imageSize) {
    final corners = barcode.corners;
    if (corners.isEmpty) {
      // No corner data — accept (fallback to old behaviour).
      return true;
    }
    if (imageSize.isEmpty) return true;

    // Barcode center in image pixels.
    double sx = 0, sy = 0;
    for (final c in corners) {
      sx += c.dx;
      sy += c.dy;
    }
    final cx = (sx / corners.length) / imageSize.width;
    final cy = (sy / corners.length) / imageSize.height;

    // Focus window: centered square, side = _windowFraction.
    final half = _windowFraction / 2;
    return cx >= 0.5 - half &&
        cx <= 0.5 + half &&
        cy >= 0.5 - half &&
        cy <= 0.5 + half;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_completed) return;
    final imageSize = capture.size;
    // Prefer a barcode whose center is inside the focus window.
    Barcode? picked;
    for (final b in capture.barcodes) {
      if (b.rawValue == null || b.rawValue!.isEmpty) continue;
      if (_isInsideFocusWindow(b, imageSize)) {
        picked = b;
        break;
      }
    }
    // Fallback: if none inside the window, ignore (do not accept stray codes).
    if (picked == null) return;

    final raw = picked.rawValue!;
    _completed = true;
    debugPrint('[ScannerPage] scan result (in window): $raw');

    _playSuccessFeedback();

    if (widget.adapter != null) {
      widget.onScanResult?.call(raw);
    } else {
      Navigator.of(context)
          .pop(ScanResult(text: raw, format: picked.format.name));
    }
  }

  void _onClosePressed() {
    if (_completed) return;
    _completed = true;
    debugPrint('[ScannerPage] close button');
    if (widget.adapter != null) {
      widget.onClose?.call();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Focus-window overlay.
          Positioned.fill(child: _FocusOverlay(fraction: _windowFraction)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _onClosePressed,
                      child: const Text('退出扫码'),
                    ),
                    const Spacer(),
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _controller,
                      builder: (context, state, _) => IconButton(
                        tooltip: state.torchState == TorchState.on
                            ? '关闭补光'
                            : '开启补光',
                        color: Colors.white,
                        style: IconButton.styleFrom(
                            backgroundColor: Colors.black54),
                        icon: Icon(
                          state.torchState == TorchState.on
                              ? Icons.flash_on
                              : Icons.flash_off,
                        ),
                        onPressed: _controller.toggleTorch,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A semi-transparent scrim with a transparent centered square cut-out and
/// an orange corner-bracket frame, signalling the scan focus area.  Includes
/// an animated scan line that travels top→bottom inside the window.
class _FocusOverlay extends StatefulWidget {
  const _FocusOverlay({required this.fraction});
  final double fraction;

  @override
  State<_FocusOverlay> createState() => _FocusOverlayState();
}

class _FocusOverlayState extends State<_FocusOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scan;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scan = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final side = math.min(w, h) * widget.fraction;
        final left = (w - side) / 2;
        final top = (h - side) / 2;
        final window = Rect.fromLTWH(left, top, side, side);
        return Stack(
          children: [
            // Scrim with a hole for the focus window.
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.45),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(color: Colors.black.withValues(alpha: 0.45)),
                  Positioned(
                    left: window.left,
                    top: window.top,
                    width: window.width,
                    height: window.height,
                    child: Container(color: Colors.black),
                  ),
                ],
              ),
            ),
            // Orange corner brackets around the window.
            Positioned(
              left: window.left,
              top: window.top,
              width: window.width,
              height: window.height,
              child: CustomPaint(painter: _BracketPainter()),
            ),
            // Animated scan line (top → bottom inside the window).
            Positioned(
              left: window.left,
              top: window.top,
              width: window.width,
              height: window.height,
              child: AnimatedBuilder(
                animation: _scan,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ScanLinePainter(progress: _scan.value),
                  );
                },
              ),
            ),
            // Hint text below the window.
            Positioned(
              left: 0,
              right: 0,
              top: window.bottom + 24,
              child: Center(
                child: Text(
                  '将二维码对准框内',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Draws the moving horizontal scan line inside the focus window.
class _ScanLinePainter extends CustomPainter {
  _ScanLinePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final linePaint = Paint()
      ..color = AppDesignColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), linePaint);
    // Soft glow trail.
    final glowPaint = Paint()
      ..color = AppDesignColors.primary.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(8, y - 8, size.width - 16, 8),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppDesignColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const len = 32.0;
    final w = size.width;
    final h = size.height;
    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, 0)
        ..lineTo(len, 0),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(w - len, 0)
        ..lineTo(w, 0)
        ..lineTo(w, len),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, h - len)
        ..lineTo(0, h)
        ..lineTo(len, h),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(w - len, h)
        ..lineTo(w, h)
        ..lineTo(w, h - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
