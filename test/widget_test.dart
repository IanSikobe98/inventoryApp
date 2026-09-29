import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:stockroom_app/models/shoe_batch.dart';
import 'package:stockroom_app/screens/dashboard_screen.dart';
import 'package:stockroom_app/screens/inventory_screen.dart';
import 'package:stockroom_app/widgets/sale_form.dart';

import 'helpers.dart';

void main() {
  setUpAll(disableGoogleFonts);

  testWidgets('inventory screen lists batches from the API', (tester) async {
    useBigSurface(tester);
    final api = fakeApi((req) async {
      if (req.method == 'GET' && req.url.path == '/api/shoe-batches') {
        return jsonResponse(pageJson([batchJson()]));
      }
      return jsonResponse({'message': 'not mocked'}, 404);
    });

    await tester.pumpWidget(harness(api, const InventoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('SB-2201'), findsOneWidget);
    expect(find.text('Sneaker · Black'), findsOneWidget);
    expect(find.text('24 / 24 left'), findsOneWidget);
    expect(find.text('In stock'), findsOneWidget);
  });

  testWidgets('inventory screen shows an error with a retry button',
      (tester) async {
    useBigSurface(tester);
    final api = fakeApi(
        (req) async => jsonResponse({'message': 'Database is down'}, 500));

    await tester.pumpWidget(harness(api, const InventoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Database is down'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('adding a batch posts the form values', (tester) async {
    useBigSurface(tester);
    Map<String, dynamic>? posted;
    final api = fakeApi((req) async {
      if (req.method == 'POST' && req.url.path == '/api/shoe-batches') {
        posted = jsonDecode(req.body) as Map<String, dynamic>;
        return jsonResponse(batchJson(code: 'SB-9000'), 201);
      }
      if (req.method == 'GET' && req.url.path == '/api/shoe-batches') {
        return jsonResponse(pageJson([]));
      }
      return jsonResponse({'message': 'not mocked'}, 404);
    });

    await tester.pumpWidget(harness(api, const InventoryScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addBatch')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('fieldCode')), 'SB-9000');
    await tester.enterText(find.byKey(const Key('fieldSize')), '41');
    await tester.enterText(find.byKey(const Key('fieldType')), 'Loafer');
    await tester.enterText(find.byKey(const Key('fieldColour')), 'Brown');
    await tester.enterText(find.byKey(const Key('fieldQty')), '12');
    await tester.enterText(find.byKey(const Key('fieldCost')), '1800');
    await tester.enterText(find.byKey(const Key('fieldWholesale')), '2500');
    await tester.enterText(find.byKey(const Key('fieldRetail')), '3200');

    await tester.tap(find.byKey(const Key('saveBatch')));
    await tester.pumpAndSettle();

    expect(posted, isNotNull);
    expect(posted!['shoeCode'], 'SB-9000');
    expect(posted!['type'], 'Loafer');
    expect(posted!['quantityReceived'], 12);
    expect(posted!['costPerShoe'], 1800.0);
    expect(posted!['retailPrice'], 3200.0);
  });

  testWidgets('the add-batch form blocks empty required fields',
      (tester) async {
    useBigSurface(tester);
    var posts = 0;
    final api = fakeApi((req) async {
      if (req.method == 'POST') posts++;
      return jsonResponse(pageJson([]));
    });

    await tester.pumpWidget(harness(api, const InventoryScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addBatch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveBatch')));
    await tester.pumpAndSettle();

    expect(find.text('Shoe code is required'), findsOneWidget);
    expect(posts, 0);
  });

  group('SaleForm', () {
    final batch = ShoeBatch.fromJson(batchJson());

    Future<void> pumpForm(
      WidgetTester tester,
      Future<http.Response> Function(http.Request req) handler, {
      required VoidCallback onSold,
    }) async {
      useBigSurface(tester);
      final api = fakeApi(handler);
      await tester.pumpWidget(harness(
        api,
        SingleChildScrollView(
          child: SaleForm(batch: batch, onSold: onSold),
        ),
      ));
      await tester.pumpAndSettle();
    }

    final modes = [
      {'id': 1, 'name': 'Cash', 'active': true},
      {'id': 2, 'name': 'M-Pesa', 'active': true},
      {'id': 3, 'name': 'Card', 'active': false},
    ];

    testWidgets('computes the total, hides inactive modes, and posts the sale',
        (tester) async {
      Map<String, dynamic>? posted;
      var sold = false;

      await pumpForm(tester, (req) async {
        if (req.method == 'GET' && req.url.path == '/api/payment-modes') {
          return jsonResponse(modes);
        }
        if (req.method == 'POST' && req.url.path == '/api/sales') {
          posted = jsonDecode(req.body) as Map<String, dynamic>;
          return jsonResponse(saleJson(), 201);
        }
        return jsonResponse({'message': 'not mocked'}, 404);
      }, onSold: () => sold = true);

      // inactive payment mode is not offered
      expect(find.text('Card'), findsNothing);

      // confirm is disabled until a payment mode is chosen
      final confirm = find.byKey(const Key('confirmSale'));
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.enterText(find.byKey(const Key('qtyField')), '2');
      await tester.pump();
      expect(find.text('KSh 6,400'), findsOneWidget); // 2 x 3,200

      await tester.tap(find.text('M-Pesa'));
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);

      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(posted, isNotNull);
      expect(posted!['shoeBatchId'], 1);
      expect(posted!['quantitySold'], 2);
      expect(posted!['paymentModeId'], 2);
      expect(posted!['actualSellingPrice'], 3200.0);
      expect(sold, isTrue);
    });

    testWidgets('does not allow more pairs than are in stock', (tester) async {
      await pumpForm(tester, (req) async {
        if (req.url.path == '/api/payment-modes') return jsonResponse(modes);
        return jsonResponse({'message': 'not mocked'}, 404);
      }, onSold: () {});

      await tester.enterText(find.byKey(const Key('qtyField')), '25');
      await tester.pump();

      expect(find.text('Enter a number from 1 to 24'), findsOneWidget);
      await tester.tap(find.text('Cash'));
      await tester.pump();
      expect(tester.widget<FilledButton>(find.byKey(const Key('confirmSale'))).onPressed,
          isNull);
    });

    testWidgets('shows the server message when stock ran out meanwhile',
        (tester) async {
      var sold = false;
      await pumpForm(tester, (req) async {
        if (req.method == 'GET') return jsonResponse(modes);
        return jsonResponse({
          'status': 409,
          'message': 'Only 1 pair(s) of SB-2201 remain',
        }, 409);
      }, onSold: () => sold = true);

      await tester.tap(find.text('Cash'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('confirmSale')));
      await tester.pumpAndSettle();

      expect(find.text('Only 1 pair(s) of SB-2201 remain'), findsOneWidget);
      expect(sold, isFalse);
    });
  });

  testWidgets('dashboard shows the headline numbers', (tester) async {
    useBigSurface(tester, width: 1200);
    final api = fakeApi((req) async {
      if (req.url.path == '/api/dashboard') {
        return jsonResponse({
          'stockValueRetail': 76800.0,
          'stockValueCost': 43200.0,
          'pairsInStock': 24,
          'batchCount': 1,
          'lowStockCount': 2,
          'outOfStockCount': 1,
          'todayTotalSales': 6000.0,
          'todayEstimatedProfit': 2400.0,
          'monthTotalSales': 90000.0,
          'last7Days': [
            {'date': 'Sun 2026-09-27', 'total': 0.0},
            {'date': 'Mon 2026-09-28', 'total': 6000.0},
          ],
          'topSellers': [
            {'shoeDescription': 'SB-2201 · Sneaker · Black', 'quantitySold': 12}
          ],
          'todayPaymentBreakdown': [
            {'paymentModeName': 'M-Pesa', 'total': 4000.0},
            {'paymentModeName': 'Cash', 'total': 2000.0},
          ],
        });
      }
      if (req.url.path == '/api/sales') return jsonResponse(pageJson([]));
      return jsonResponse({'message': 'not mocked'}, 404);
    });

    await tester.pumpWidget(harness(api, const DashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('KSh 76,800'), findsOneWidget); // stock value
    expect(find.text('24'), findsOneWidget); // pairs in stock
    expect(find.text('KSh 6,000'), findsOneWidget); // today's sales
    expect(find.text('3'), findsOneWidget); // 2 low + 1 out
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('M-Pesa'), findsOneWidget);
    expect(find.text('KSh 4,000'), findsOneWidget);
  });
}
