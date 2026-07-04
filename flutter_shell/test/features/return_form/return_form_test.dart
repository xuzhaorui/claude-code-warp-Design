import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/components/form_widgets.dart';
import 'package:wms_app/design/app_theme.dart';
import 'package:wms_app/features/api/mock_warehouse_api_client.dart';
import 'package:wms_app/features/return_form/return_form.dart';
import 'package:wms_app/features/return_form/return_form_rules.dart';

const _record = ReturnBorrowRecordSnapshot(
  loanId: 101,
  freightId: 202,
  storageId: 303,
  borrowQty: 50,
  costPrice: 30.0,
  itemName: '娴嬭瘯璐х墿',
  borrower: '寮犱笁',
  warehouse: '涓讳粨搴?',
);

Widget wrapApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  group('ReturnFormMin', () {
    testWidgets('renders item basic info', (tester) async {
      await tester.pumpWidget(wrapApp(const ReturnFormMin(record: _record)));
      expect(find.text('娴嬭瘯璐х墿'), findsAtLeast(1));
      expect(find.text('寮犱笁'), findsOneWidget);
    });

    testWidgets('renders borrow qty in badge', (tester) async {
      await tester.pumpWidget(wrapApp(const ReturnFormMin(record: _record)));
      expect(find.byType(StockBadge), findsWidgets);
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('quantity stepper changes value', (tester) async {
      await tester.pumpWidget(wrapApp(const ReturnFormMin(record: _record)));
      await tester.tap(find.text('+'));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('over qty warning at max stays clear', (tester) async {
      await tester.pumpWidget(wrapApp(const ReturnFormMin(record: _record)));
      final stepper = tester.widget<BlackStepper>(
        find.byType(BlackStepper).first,
      );
      expect(stepper.error, isFalse);
    });

    testWidgets(
      'manual qty above borrow amount shows warning and blocks submit',
      (tester) async {
        ReturnSubmitPayload? captured;
        await tester.pumpWidget(
          wrapApp(
            ReturnFormMin(record: _record, onSubmit: (p) => captured = p),
          ),
        );

        await tester.enterText(find.byType(TextField).first, '51');
        await tester.pump();

        final stepper = tester.widget<BlackStepper>(
          find.byType(BlackStepper).first,
        );
        final submit = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton).last,
        );
        expect(stepper.error, isTrue);
        expect(submit.onPressed, isNull);
        expect(captured, isNull);
      },
    );

    testWidgets('renders remark field', (tester) async {
      await tester.pumpWidget(wrapApp(const ReturnFormMin(record: _record)));
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('submit button renders', (tester) async {
      await tester.pumpWidget(wrapApp(const ReturnFormMin(record: _record)));
      expect(find.byType(BlackSubmitButton), findsOneWidget);
    });

    testWidgets('form renders with submit', (tester) async {
      await tester.pumpWidget(wrapApp(const ReturnFormMin(record: _record)));
      expect(find.byType(ReturnFormMin), findsOneWidget);
    });

    testWidgets('submit calls onSubmit with return payload', (tester) async {
      ReturnSubmitPayload? captured;
      await tester.pumpWidget(
        wrapApp(ReturnFormMin(record: _record, onSubmit: (p) => captured = p)),
      );

      await tester.tap(find.text('+'));
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pump();

      expect(captured, isNotNull);
      expect(captured!.loanId, 101);
      expect(captured!.freightId, 202);
      expect(captured!.storageId, 303);
      expect(captured!.returnQty, 2);
    });

    testWidgets('submit includes remark', (tester) async {
      ReturnSubmitPayload? captured;
      await tester.pumpWidget(
        wrapApp(ReturnFormMin(record: _record, onSubmit: (p) => captured = p)),
      );

      await tester.enterText(find.byType(TextFormField), '閮ㄥ垎褰掕繕');
      await tester.pump();
      await tester.tap(find.text('+'));
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pump();

      expect(captured, isNotNull);
      expect(captured!.remark, '閮ㄥ垎褰掕繕');
    });

    testWidgets('showCostPrice=false hides cost badge', (tester) async {
      await tester.pumpWidget(
        wrapApp(const ReturnFormMin(record: _record, showCostPrice: false)),
      );
      expect(find.byType(CostBadge), findsNothing);
    });

    testWidgets('showCostPrice=true shows cost badge', (tester) async {
      await tester.pumpWidget(
        wrapApp(const ReturnFormMin(record: _record, showCostPrice: true)),
      );
      expect(find.byType(CostBadge), findsOneWidget);
    });

    testWidgets('long item info does not crash', (tester) async {
      final longRecord = ReturnBorrowRecordSnapshot(
        loanId: 1,
        freightId: 1,
        storageId: 1,
        borrowQty: 10,
        costPrice: 50.0,
        itemName: '瓒呴暱璐х墿鍚嶇О' * 20,
        borrower: '瓒呴暱濮撳悕' * 20,
        warehouse: '瓒呴暱浠撳簱' * 20,
      );
      await tester.pumpWidget(wrapApp(ReturnFormMin(record: longRecord)));
      expect(find.byType(ReturnFormMin), findsOneWidget);
    });

    testWidgets('renders with onClose callback', (tester) async {
      await tester.pumpWidget(
        wrapApp(ReturnFormMin(record: _record, onClose: () {})),
      );
      expect(find.byType(ReturnFormMin), findsOneWidget);
    });

    testWidgets('apiClient renders without crash', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ReturnFormMin(record: _record, apiClient: MockWarehouseApiClient()),
        ),
      );
      expect(find.byType(ReturnFormMin), findsOneWidget);
    });

    testWidgets('two-column layout shows item fields and submit button', (
      tester,
    ) async {
      await tester.pumpWidget(wrapApp(const ReturnFormMin(record: _record)));
      await tester.pump();
      expect(find.byType(ItemInfoPanel), findsOneWidget);
      expect(find.byType(InfoField), findsNWidgets(3));
      expect(find.byType(BlackSubmitButton), findsOneWidget);
    });
  });
}
