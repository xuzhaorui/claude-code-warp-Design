// Real mobile_scanner adapter implementation.
//
// Wraps [MobileScannerController] into the [ScannerAdapter] contract so that
// business logic can switch between mock and real scanner transparently.
//
// The mapper functions ([mapBarcodeToResult], [mapExceptionToFailure]) are
// pure / static and testable without a real camera.

import 'dart:async';

import 'package:mobile_scanner/mobile_scanner.dart';

import 'scanner_adapter.dart';

// ── Barcode mapper ──

/// Converts a [Barcode] to a [ScannerResult], or returns `null` if the
/// barcode has no valid raw value.
///
/// Pure function — no side effects, no BuildContext, no Widget dependency.
ScannerResult? mapBarcodeToResult(Barcode barcode) {
  final raw = barcode.rawValue;
  if (raw == null || raw.isEmpty) return null;
  return ScannerResult(
    code: raw,
    rawValue: raw,
    format: barcode.format.name,
  );
}

/// Converts an arbitrary error to a [ScannerFailure].
///
/// Pure function — no side effects.
ScannerFailure mapExceptionToFailure(
  Object error, {
  String? code,
  StackTrace? stackTrace,
}) {
  return ScannerFailure(
    message: error.toString(),
    code: code,
    cause: error,
  );
}

// ── Real adapter ──

/// [ScannerAdapter] implementation backed by a real [MobileScannerController].
///
/// The UI layer (e.g. [MobileScanner] widget) calls [onBarcodeDetected] from
/// its `onDetect` callback.  The adapter processes the barcode through
/// [mapBarcodeToResult] and pushes the result to the [results] stream.
///
/// Lifecycle ([start], [stop], [dispose]) is delegated to the controller.
class RealMobileScannerAdapter implements ScannerAdapter {
  /// Creates an adapter that will own and manage a [MobileScannerController].
  ///
  /// The [controller] parameter allows dependency injection for testing.
  /// When omitted, a default controller is created.
  RealMobileScannerAdapter({
    MobileScannerController? controller,
  }) : _controller =
            controller ?? MobileScannerController();

  final MobileScannerController _controller;
  ScannerStatus _status = ScannerStatus.idle;
  bool _disposed = false;

  final StreamController<ScannerResult> _resultController =
      StreamController<ScannerResult>.broadcast(sync: true);

  final StreamController<ScannerFailure> _failureController =
      StreamController<ScannerFailure>.broadcast(sync: true);

  @override
  ScannerStatus get status => _status;

  @override
  Stream<ScannerResult> get results => _resultController.stream;

  @override
  Stream<ScannerFailure> get failures => _failureController.stream;

  /// Called by the UI layer when a barcode is detected.
  ///
  /// This is the bridge between the [MobileScanner] widget's `onDetect`
  /// callback and the [ScannerAdapter] contract.
  void onBarcodeDetected(Barcode barcode) {
    if (_disposed) return;
    final result = mapBarcodeToResult(barcode);
    if (result != null) {
      _status = ScannerStatus.success;
      _resultController.add(result);
    }
  }

  /// Called by the UI layer when a BarcodeCapture is received.
  ///
  /// Extracts the first barcode from the capture and delegates to
  /// [onBarcodeDetected].
  void onBarcodeCapture(BarcodeCapture capture) {
    if (_disposed) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    onBarcodeDetected(barcodes.first);
  }

  @override
  Future<void> start() async {
    if (_disposed) return;
    try {
      await _controller.start();
      _status = ScannerStatus.scanning;
    } catch (e) {
      _status = ScannerStatus.failure;
      _failureController.add(mapExceptionToFailure(e, code: 'start_failed'));
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    try {
      await _controller.stop();
      _status = ScannerStatus.idle;
    } catch (e) {
      _failureController.add(mapExceptionToFailure(e, code: 'stop_failed'));
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _status = ScannerStatus.idle;
    await _controller.dispose();
    await _resultController.close();
    await _failureController.close();
  }
}
