// Scanner adapter contract — separates scanner hardware from business logic.
//
// [ScannerAdapter] is the abstract interface that all scanner implementations
// (mock, real mobile_scanner, etc.) must implement.
//
// [MockScannerAdapter] provides a test-driven implementation for development
// and unit tests.
//
// No Flutter, no mobile_scanner, no BuildContext, no Widget dependency.

import 'dart:async';

// ── Status ──

/// Lifecycle status of a [ScannerAdapter].
enum ScannerStatus {
  /// Initial state before [start] is called.
  idle,

  /// Scanner hardware is initializing.
  ready,

  /// Camera is active and decoding.
  scanning,

  /// A code was successfully decoded.
  success,

  /// An unrecoverable error occurred.
  failure,

  /// Camera permission was denied by the user.
  permissionDenied,
}

// ── Result ──

/// A successfully decoded barcode / QR code.
class ScannerResult {
  ScannerResult({
    required this.code,
    this.rawValue,
    this.format,
    DateTime? scannedAt,
  }) : scannedAt = scannedAt ?? DateTime.now();

  /// Decoded text payload (guaranteed non-empty).
  final String code;

  /// Raw barcode payload before trimming (may be null).
  final String? rawValue;

  /// Barcode format name (e.g. "qrCode", "code128").
  final String? format;

  /// Timestamp when the code was decoded.
  final DateTime scannedAt;
}

// ── Failure ──

/// A scanner failure event.
class ScannerFailure {
  const ScannerFailure({
    required this.message,
    this.code,
    this.cause,
  });

  /// Human-readable error description.
  final String message;

  /// Machine-readable error code (e.g. "camera_unavailable").
  final String? code;

  /// The original exception or error (if any).
  final Object? cause;
}

// ── Adapter interface ──

/// Abstract contract for barcode scanner hardware adapters.
///
/// Implementations wrap platform-specific scanner libraries
/// (mobile_scanner, AVFoundation, ML Kit, etc.) behind this interface
/// so that business logic never depends on a specific scanner library.
abstract interface class ScannerAdapter {
  /// Stream of successfully decoded barcodes.
  Stream<ScannerResult> get results;

  /// Stream of scanner failures / errors.
  Stream<ScannerFailure> get failures;

  /// Current lifecycle status.
  ScannerStatus get status;

  /// Start the scanner (initialize camera, begin decoding).
  Future<void> start();

  /// Stop the scanner (pause camera, stop decoding).
  Future<void> stop();

  /// Release all resources.  After this, the adapter must not be used.
  Future<void> dispose();
}

// ── Mock implementation ──

/// Test-driven [ScannerAdapter] implementation.
///
/// Use [emitResult] and [emitFailure] to simulate scan events from tests
/// or from the shell wiring layer.
class MockScannerAdapter implements ScannerAdapter {
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

  @override
  Future<void> start() async {
    if (_disposed) return;
    _status = ScannerStatus.ready;
    // Simulate async camera init.
    await Future<void>.delayed(Duration.zero);
    if (!_disposed) {
      _status = ScannerStatus.scanning;
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    _status = ScannerStatus.idle;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _status = ScannerStatus.idle;
    await _resultController.close();
    await _failureController.close();
  }

  // ── Test helpers ──

  /// Emit a successful scan result.
  ///
  /// Throws [StateError] if the adapter has been disposed.
  void emitResult(ScannerResult result) {
    if (_disposed) {
      throw StateError('Cannot emit result after dispose');
    }
    _status = ScannerStatus.success;
    _resultController.add(result);
  }

  /// Emit a scanner failure.
  ///
  /// Throws [StateError] if the adapter has been disposed.
  void emitFailure(ScannerFailure failure) {
    if (_disposed) {
      throw StateError('Cannot emit failure after dispose');
    }
    _status = ScannerStatus.failure;
    _failureController.add(failure);
  }
}
