import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../features/scanner/scanner_adapter.dart';

/// Result popped back to [WebShellPage] when a code is decoded.
class ScanResult {
  final String text;
  final String format;
  const ScanResult({required this.text, required this.format});
}

/// Full-screen native scanner backed by mobile_scanner (CameraX / ML Kit).
///
/// When [adapter] is provided, detected barcodes are forwarded to
/// [onScanResult] / [onScanFailure] callbacks, and the page subscribes
/// to [adapter.results] for output.  Test paths can inject a
/// [MockScannerAdapter] and simulate results via [MockScannerAdapter.emitResult].
///
/// When [adapter] is `null`, the page preserves the original behaviour:
/// single-shot decode → [Navigator.pop] with [ScanResult].
class ScannerPage extends StatefulWidget {
  /// Optional scanner adapter for testable wiring.
  final ScannerAdapter? adapter;

  /// Called when a barcode is successfully decoded (adapter mode).
  final ValueChanged<String>? onScanResult;

  /// Called when the scanner encounters a failure (adapter mode).
  final ValueChanged<ScannerFailure>? onScanFailure;

  /// Called when the user taps the close button (adapter mode).
  final VoidCallback? onClose;

  /// Operational mode label (unused by the adapter wiring; preserved for
  /// backward compatibility).
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
    // First-phase barcode set — migration spec §9.
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

  bool _returned = false;
  StreamSubscription<ScannerResult>? _resultSub;
  StreamSubscription<ScannerFailure>? _failureSub;

  @override
  void initState() {
    super.initState();
    _setupAdapter();
  }

  void _setupAdapter() {
    final adapter = widget.adapter;
    if (adapter == null) return;

    // Subscribe to adapter output streams.
    _resultSub = adapter.results.listen((result) {
      if (!_returned) {
        _returned = true;
        widget.onScanResult?.call(result.code);
      }
    });

    _failureSub = adapter.failures.listen((failure) {
      widget.onScanFailure?.call(failure);
    });
  }

  @override
  void dispose() {
    _resultSub?.cancel();
    _failureSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_returned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final barcode = barcodes.first;
    final raw = barcode.rawValue;
    if (raw == null || raw.isEmpty) return;

    _returned = true;

    if (widget.adapter != null) {
      // Adapter mode: forward result via callback.
      widget.onScanResult?.call(raw);
    } else {
      // Legacy mode: pop via Navigator.
      Navigator.of(context)
          .pop(ScanResult(text: raw, format: barcode.format.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        if (widget.adapter != null) {
                          widget.onClose?.call();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
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
