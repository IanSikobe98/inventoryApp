import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:stockroom_app/services/api_client.dart';

import 'helpers.dart';

void main() {
  test('searchBatches sends shoeSize (not size) as the filter', () async {
    late Uri seen;
    final api = fakeApi((req) async {
      seen = req.url;
      return jsonResponse(pageJson([batchJson()]));
    });

    final page = await api.searchBatches(
        query: ' nike ', shoeSize: '42', lowStockOnly: true, pageSize: 50);

    expect(seen.path, '/api/shoe-batches');
    expect(seen.queryParameters['query'], 'nike');
    expect(seen.queryParameters['shoeSize'], '42');
    expect(seen.queryParameters['lowStockOnly'], 'true');
    expect(seen.queryParameters['size'], '50'); // page size
    expect(seen.queryParameters.containsKey('outOfStockOnly'), isFalse);
    expect(page.content.single.shoeCode, 'SB-2201');
  });

  test('searchSales formats dates and skips empty filters', () async {
    late Uri seen;
    final api = fakeApi((req) async {
      seen = req.url;
      return jsonResponse(pageJson([]));
    });

    await api.searchSales(
        from: DateTime(2026, 9, 1), to: DateTime(2026, 9, 22), paymentModeId: 2);

    expect(seen.path, '/api/sales');
    expect(seen.queryParameters['from'], '2026-09-01');
    expect(seen.queryParameters['to'], '2026-09-22');
    expect(seen.queryParameters['paymentModeId'], '2');
    expect(seen.queryParameters.containsKey('query'), isFalse);
    expect(seen.queryParameters.containsKey('shoeBatchId'), isFalse);
  });

  test('createSale posts the expected JSON body', () async {
    late http.Request seen;
    final api = fakeApi((req) async {
      seen = req;
      return jsonResponse(saleJson(), 201);
    });

    final sale = await api.createSale(
      shoeBatchId: 1,
      actualSellingPrice: 3200,
      quantitySold: 2,
      paymentModeId: 2,
      remarks: '  discount  ',
    );

    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/sales');
    final body = jsonDecode(seen.body) as Map<String, dynamic>;
    expect(body['shoeBatchId'], 1);
    expect(body['quantitySold'], 2);
    expect(body['paymentModeId'], 2);
    expect(body['remarks'], 'discount');
    expect(sale.totalAmount, 6400.0);
  });

  test('createSale leaves blank remarks out', () async {
    late Map<String, dynamic> body;
    final api = fakeApi((req) async {
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return jsonResponse(saleJson(), 201);
    });
    await api.createSale(
        shoeBatchId: 1,
        actualSellingPrice: 100,
        quantitySold: 1,
        paymentModeId: 1,
        remarks: '   ');
    expect(body.containsKey('remarks'), isFalse);
  });

  test('a 409 becomes an ApiException carrying the server message', () async {
    final api = fakeApi((req) async => jsonResponse({
          'status': 409,
          'error': 'Conflict',
          'message': 'Only 1 pair(s) of SB-2201 remain',
        }, 409));

    await expectLater(
      api.createSale(
          shoeBatchId: 1,
          actualSellingPrice: 100,
          quantitySold: 5,
          paymentModeId: 1),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 409)
          .having((e) => e.message, 'message', contains('Only 1 pair'))),
    );
  });

  test('a 400 exposes field-level validation errors', () async {
    final api = fakeApi((req) async => jsonResponse({
          'status': 400,
          'message': 'Validation failed',
          'fieldErrors': [
            {'field': 'shoeCode', 'message': 'shoeCode is required'}
          ],
        }, 400));

    try {
      await api.createBatch({'shoeCode': ''});
      fail('should have thrown');
    } on ApiException catch (e) {
      expect(e.fieldErrors['shoeCode'], 'shoeCode is required');
      expect(e.fullMessage, contains('Validation failed'));
      expect(e.fullMessage, contains('shoeCode is required'));
    }
  });

  test('a non-JSON error body still gives a readable message', () async {
    final api =
        fakeApi((req) async => http.Response('<html>Bad gateway</html>', 502));
    await expectLater(
      api.getDashboard(),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', contains('502'))),
    );
  });

  test('an unreachable server gives a helpful message', () async {
    final api = fakeApi((req) async => throw http.ClientException('refused'));
    await expectLater(
      api.getDashboard(),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', contains('Cannot reach'))),
    );
  });

  test('deleteBatch accepts an empty 204 response', () async {
    final api = fakeApi((req) async => http.Response('', 204));
    await api.deleteBatch(1); // should not throw
  });
}
