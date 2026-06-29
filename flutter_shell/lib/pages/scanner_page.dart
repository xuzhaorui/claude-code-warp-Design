import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
      widget.onScanResult?.call(result.code);
    });

    _failureSub = adapter.failures.listen((failure) {
      widget.onScanFailure?.call(failure);
    });
  }

  @override
  void dispose() {
    debugPrint('[ScannerPage] dispose');
    _resultSub?.cancel();
    _failureSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_completed) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final barcode = barcodes.first;
    final raw = barcode.rawValue;
    if (raw == null || raw.isEmpty) return;

    _completed = true;
    debugPrint('[ScannerPage] scan result: $raw');

    if (widget.adapter != null) {
      widget.onScanResult?.call(raw);
    } else {
      Navigator.of(context)
          .pop(ScanResult(text: raw, format: barcode.format.name));
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
