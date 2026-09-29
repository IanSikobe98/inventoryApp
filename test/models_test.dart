import 'package:flutter_test/flutter_test.dart';
import 'package:stockroom_app/models/dashboard_data.dart';
import 'package:stockroom_app/models/page_result.dart';
import 'package:stockroom_app/models/payment_mode.dart';
import 'package:stockroom_app/models/sale.dart';
import 'package:stockroom_app/models/shoe_batch.dart';

import 'helpers.dart';

void main() {
  test('ShoeBatch parses the API response', () {
    final b = ShoeBatch.fromJson(batchJson(remaining: 3));
    expect(b.shoeCode, 'SB-2201');
    expect(b.title, 'Sneaker · Black');
    expect(b.retailPrice, 3200.0);
    expect(b.quantityRemaining, 3);
    expect(b.lowStock, isTrue);
    expect(b.outOfStock, isFalse);
  });

  test('ShoeBatch copes with integer prices and missing optional fields', () {
    final b = ShoeBatch.fromJson({
      'id': 5,
      'shoeCode': 'X',
      'size': '40',
      'type': 'Boot',
      'colour': 'Tan',
      'quantityReceived': 10,
      'quantityRemaining': 0,
      'costPerShoe': 1000,
      'wholesalePrice': 1500,
      'retailPrice': 2000,
    });
    expect(b.costPerShoe, 1000.0);
    expect(b.pictureUrl, isNull);
    expect(b.outOfStock, isTrue); // derived when the flag is missing
  });

  test('Sale parses amounts and the LocalDateTime timestamp', () {
    final s = Sale.fromJson(saleJson());
    expect(s.totalAmount, 6400.0);
    expect(s.paymentModeName, 'M-Pesa');
    expect(s.createdAt, isNotNull);
    expect(s.createdAt!.year, 2026);
    expect(s.remarks, isNull);
  });

  test('PaymentMode defaults to active when the flag is missing', () {
    expect(PaymentMode.fromJson({'id': 1, 'name': 'Cash'}).active, isTrue);
    expect(
        PaymentMode.fromJson({'id': 2, 'name': 'Card', 'active': false}).active,
        isFalse);
  });

  test('PageResult reads Spring Data pages', () {
    final page = PageResult.fromJson(
        {
          'content': [batchJson(id: 1), batchJson(id: 2, code: 'SB-2202')],
          'totalElements': 30,
          'totalPages': 2,
          'number': 0,
          'last': false,
        },
        ShoeBatch.fromJson);
    expect(page.content.length, 2);
    expect(page.totalElements, 30);
    expect(page.last, isFalse);
  });

  test('DashboardData parses nested lists', () {
    final d = DashboardData.fromJson({
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
        {'date': 'Mon 2026-09-28', 'total': 6000.0}
      ],
      'topSellers': [
        {'shoeDescription': 'SB-2201 · Sneaker · Black', 'quantitySold': 12}
      ],
      'todayPaymentBreakdown': [
        {'paymentModeName': 'M-Pesa', 'total': 6000.0}
      ],
    });
    expect(d.needsRestocking, 3);
    expect(d.last7Days.first.label, 'Mon');
    expect(d.topSellers.first.quantitySold, 12);
    expect(d.todayPaymentBreakdown.first.paymentModeName, 'M-Pesa');
  });
}
