import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Result popped back to [WebShellPage] when a code is decoded.
class ScanResult {
  final String text;
  final String format;
  const ScanResult({required this.text, required this.format});
}

/// Full-screen native scanner backed by mobile_scanner (CameraX / ML Kit).
/// Single-shot: first valid decode pops a [ScanResult]; back button pops null.
/// Back camera, auto-zoom for small labels, torch toggle, duplicate guard.
class ScannerPage extends StatefulWidget {
  final String mode;
  const ScannerPage({super.key, required this.mode});

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

  @override
  void dispose() {
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
    Navigator.of(context).pop(ScanResult(text: raw, format: barcode.format.name));
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
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('退出扫码'),
                    ),
                    const Spacer(),
                    // Controller is a ValueNotifier<MobileScannerState>; its
                    // value carries the current torch mode.
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _controller,
                      builder: (context, state, _) => IconButton(
                        tooltip: state.torchState == TorchState.on ? '关闭补光' : '开启补光',
                        color: Colors.white,
                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
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
