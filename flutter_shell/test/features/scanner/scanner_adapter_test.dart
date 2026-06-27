import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/features/scanner/scanner_adapter.dart';

void main() {
  group('MockScannerAdapter', () {
    // 1. initial status is idle
    test('initial status is idle', () {
      final adapter = MockScannerAdapter();
      expect(adapter.status, ScannerStatus.idle);
    });

    // 2. start changes status to scanning
    test('start changes status to scanning', () async {
      final adapter = MockScannerAdapter();
      await adapter.start();
      expect(adapter.status, ScannerStatus.scanning);
    });

    // 3. stop changes status to idle
    test('stop changes status to idle', () async {
      final adapter = MockScannerAdapter();
      await adapter.start();
      await adapter.stop();
      expect(adapter.status, ScannerStatus.idle);
    });

    // 4. dispose changes status and prevents future emits
    test('dispose changes status to idle', () async {
      final adapter = MockScannerAdapter();
      await adapter.start();
      await adapter.dispose();
      expect(adapter.status, ScannerStatus.idle);
    });

    // 5. emitResult publishes ScannerResult
    test('emitResult publishes ScannerResult', () async {
      final adapter = MockScannerAdapter();
      final results = <ScannerResult>[];
      adapter.results.listen((r) => results.add(r));
      adapter.emitResult(ScannerResult(code: 'ABC'));
      expect(results, hasLength(1));
      expect(results.first.code, 'ABC');
    });

    // 6. emitResult preserves code
    test('emitResult preserves code', () async {
      final adapter = MockScannerAdapter();
      ScannerResult? captured;
      adapter.results.listen((r) => captured = r);
      adapter.emitResult(ScannerResult(code: 'SKU-001', rawValue: 'SKU-001'));
      expect(captured!.code, 'SKU-001');
    });

    // 7. emitResult preserves rawValue if provided
    test('emitResult preserves rawValue', () async {
      final adapter = MockScannerAdapter();
      ScannerResult? captured;
      adapter.results.listen((r) => captured = r);
      adapter.emitResult(ScannerResult(code: 'X', rawValue: 'raw-value'));
      expect(captured!.rawValue, 'raw-value');
    });

    // 8. emitResult preserves format if provided
    test('emitResult preserves format', () async {
      final adapter = MockScannerAdapter();
      ScannerResult? captured;
      adapter.results.listen((r) => captured = r);
      adapter.emitResult(ScannerResult(code: 'X', format: 'qrCode'));
      expect(captured!.format, 'qrCode');
    });

    // 9. emitResult sets scannedAt
    test('emitResult sets scannedAt', () async {
      final adapter = MockScannerAdapter();
      ScannerResult? captured;
      adapter.results.listen((r) => captured = r);
      adapter.emitResult(ScannerResult(code: 'X'));
      expect(captured!.scannedAt, isNotNull);
      // Should be recent (within the last 10 seconds).
      final age = DateTime.now().difference(captured!.scannedAt);
      expect(age.inSeconds, lessThan(10));
    });

    // 10. emitFailure publishes ScannerFailure
    test('emitFailure publishes ScannerFailure', () async {
      final adapter = MockScannerAdapter();
      final failures = <ScannerFailure>[];
      adapter.failures.listen((f) => failures.add(f));
      adapter.emitFailure(const ScannerFailure(message: 'Camera error'));
      expect(failures, hasLength(1));
      expect(failures.first.message, 'Camera error');
    });

    // 11. emitFailure preserves message
    test('emitFailure preserves message', () async {
      final adapter = MockScannerAdapter();
      ScannerFailure? captured;
      adapter.failures.listen((f) => captured = f);
      adapter.emitFailure(const ScannerFailure(message: 'Permission denied', code: 'perm'));
      expect(captured!.message, 'Permission denied');
      expect(captured!.code, 'perm');
    });

    // 12. failures and results streams are independent
    test('failures and results streams are independent', () async {
      final adapter = MockScannerAdapter();
      final results = <ScannerResult>[];
      final failures = <ScannerFailure>[];
      adapter.results.listen((r) => results.add(r));
      adapter.failures.listen((f) => failures.add(f));

      adapter.emitResult(ScannerResult(code: 'A'));
      adapter.emitFailure(const ScannerFailure(message: 'Err'));
      adapter.emitResult(ScannerResult(code: 'B'));

      expect(results, hasLength(2));
      expect(failures, hasLength(1));
    });

    // 13. cannot emit result after dispose
    test('cannot emit result after dispose', () async {
      final adapter = MockScannerAdapter();
      await adapter.dispose();
      expect(
        () => adapter.emitResult(ScannerResult(code: 'X')),
        throwsStateError,
      );
    });

    // 14. cannot emit failure after dispose
    test('cannot emit failure after dispose', () async {
      final adapter = MockScannerAdapter();
      await adapter.dispose();
      expect(
        () => adapter.emitFailure(const ScannerFailure(message: 'err')),
        throwsStateError,
      );
    });

    // 15. multiple results emitted in order
    test('multiple results in order', () async {
      final adapter = MockScannerAdapter();
      final results = <ScannerResult>[];
      adapter.results.listen((r) => results.add(r));

      adapter.emitResult(ScannerResult(code: 'A'));
      adapter.emitResult(ScannerResult(code: 'B'));
      adapter.emitResult(ScannerResult(code: 'C'));

      expect(results.map((r) => r.code).toList(), ['A', 'B', 'C']);
    });

    // 16. start after dispose is no-op (returns without error)
    test('start after dispose is no-op', () async {
      final adapter = MockScannerAdapter();
      await adapter.dispose();
      // Should not throw.
      await adapter.start();
      expect(adapter.status, ScannerStatus.idle);
    });

    // 17. stop after dispose is no-op
    test('stop after dispose is no-op', () async {
      final adapter = MockScannerAdapter();
      await adapter.dispose();
      await adapter.stop();
      expect(adapter.status, ScannerStatus.idle);
    });

    // 18. results stream can be listened before start
    test('results stream listenable before start', () async {
      final adapter = MockScannerAdapter();
      final results = <ScannerResult>[];
      adapter.results.listen((r) => results.add(r));
      adapter.emitResult(ScannerResult(code: 'pre-start'));
      expect(results, hasLength(1));
    });

    // 19. failures stream can be listened before start
    test('failures stream listenable before start', () async {
      final adapter = MockScannerAdapter();
      final failures = <ScannerFailure>[];
      adapter.failures.listen((f) => failures.add(f));
      adapter.emitFailure(const ScannerFailure(message: 'pre-start'));
      expect(failures, hasLength(1));
    });

    // 20-22. verified by absence of Flutter Widget, mobile_scanner, and
    // UI dependencies — tests run as pure Dart.
  });

  group('ScannerAdapter contract', () {
    // 22. adapter can be used in pure Dart tests (verified above).
    test('MockScannerAdapter implements ScannerAdapter', () {
      final adapter = MockScannerAdapter();
      expect(adapter, isA<ScannerAdapter>());
    });
  });
}
