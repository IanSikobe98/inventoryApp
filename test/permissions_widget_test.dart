import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockroom_app/models/permissions.dart';
import 'package:stockroom_app/screens/dashboard_screen.dart';
import 'package:stockroom_app/screens/inventory_screen.dart';
import 'package:stockroom_app/screens/payment_modes_screen.dart';

import 'helpers.dart';

void main() {
  setUpAll(disableGoogleFonts);

  api() => fakeApi((req) async {
        if (req.url.path == '/api/shoe-batches') {
          return jsonResponse(pageJson([batchJson()]));
        }
        if (req.url.path == '/api/payment-modes') {
          return jsonResponse([
            {'id': 1, 'name': 'Cash', 'active': true},
          ]);
        }
        return jsonResponse({'message': 'not mocked'}, 404);
      });

  Future<void> pumpInventory(WidgetTester tester, Set<String> perms) async {
    useBigSurface(tester);
    await tester.pumpWidget(
        harness(api(), const InventoryScreen(), permissions: perms));
    await tester.pumpAndSettle();
  }

  group('Inventory screen', () {
    testWidgets('everything is offered with every permission', (tester) async {
      await pumpInventory(tester, Perm.all);
      expect(find.byKey(const Key('addBatch')), findsOneWidget);
      expect(find.text('Restock'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('view only: no Add batch, Restock or Edit', (tester) async {
      await pumpInventory(tester, {Perm.viewInventory});
      expect(find.text('SB-2201'), findsOneWidget); // the batch is still listed
      expect(find.byKey(const Key('addBatch')), findsNothing);
      expect(find.text('Restock'), findsNothing);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('CREATE_INVENTORY gives only Add batch', (tester) async {
      await pumpInventory(tester, {Perm.viewInventory, Perm.createInventory});
      expect(find.byKey(const Key('addBatch')), findsOneWidget);
      expect(find.text('Restock'), findsNothing);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('UPDATE_INVENTORY gives Restock and Edit but not Add batch',
        (tester) async {
      await pumpInventory(tester, {Perm.viewInventory, Perm.updateInventory});
      expect(find.byKey(const Key('addBatch')), findsNothing);
      expect(find.text('Restock'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('the empty list does not tell a view-only person to tap Add batch',
        (tester) async {
      useBigSurface(tester);
      final empty = fakeApi((req) async => jsonResponse(pageJson([])));
      await tester.pumpWidget(harness(empty, const InventoryScreen(),
          permissions: {Perm.viewInventory}));
      await tester.pumpAndSettle();
      expect(find.text('No shoe batches yet.'), findsOneWidget);
    });
  });

  group('Payment modes screen', () {
    Future<void> pumpModes(WidgetTester tester, Set<String> perms) async {
      useBigSurface(tester);
      await tester.pumpWidget(
          harness(api(), const PaymentModesScreen(), permissions: perms));
      await tester.pumpAndSettle();
    }

    testWidgets('CREATE_PAYMENT shows Add mode and a working switch', (tester) async {
      await pumpModes(tester, {Perm.viewPayment, Perm.createPayment});
      expect(find.byKey(const Key('addPaymentMode')), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);
    });

    testWidgets('VIEW_PAYMENT alone: no Add mode, switch is disabled', (tester) async {
      await pumpModes(tester, {Perm.viewPayment});
      expect(find.text('Cash'), findsOneWidget);
      expect(find.byKey(const Key('addPaymentMode')), findsNothing);
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    });
  });

  group('Dashboard', () {
    Future<void> pumpDash(WidgetTester tester, Set<String> perms) async {
      useBigSurface(tester);
      await tester.pumpWidget(
          harness(api(), const DashboardScreen(), permissions: perms));
      await tester.pumpAndSettle();
    }

    testWidgets('"Record a sale" needs CREATE_SALES', (tester) async {
      await pumpDash(tester, {Perm.viewInventory, Perm.viewSales});
      expect(find.text('Record a sale'), findsNothing);
    });

    testWidgets('"Record a sale" shows with CREATE_SALES', (tester) async {
      await pumpDash(tester, {Perm.viewInventory, Perm.viewSales, Perm.createSales});
      expect(find.text('Record a sale'), findsOneWidget);
    });
  });
}
