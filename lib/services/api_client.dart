import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/dashboard_data.dart';
import '../models/page_result.dart';
import '../models/payment_mode.dart';
import '../models/sale.dart';
import '../models/shoe_batch.dart';
import '../utils/format.dart';

/// Any failure talking to the API, already worded for a human.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  final String message;
  final int? statusCode;

  /// Per-field validation messages from a 400 response (field -> message).
  final Map<String, String> fieldErrors;

  /// Message plus any field-level details, for showing in a banner.
  String get fullMessage {
    if (fieldErrors.isEmpty) return message;
    final details = fieldErrors.entries.map((e) => '• ${e.value}').join('\n');
    return '$message\n$details';
  }

  @override
  String toString() => message;
}

/// Thin wrapper over package:http for the Spring Boot inventory API.
/// Pass a [client] (e.g. http's MockClient) in tests.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = (baseUrl ?? Env.apiBaseUrl).replaceAll(RegExp(r'/+$'), '');

  final http.Client _client;
  final String baseUrl;

  // ---------------------------------------------------------------- dashboard

  Future<DashboardData> getDashboard() async {
    final json = await _request('GET', '/api/dashboard');
    return DashboardData.fromJson(json as Map<String, dynamic>);
  }

  // ------------------------------------------------------------- shoe batches

  Future<PageResult<ShoeBatch>> searchBatches({
    String query = '',
    String shoeSize = '',
    bool lowStockOnly = false,
    bool outOfStockOnly = false,
    int page = 0,
    int pageSize = 50,
  }) async {
    final json = await _request('GET', '/api/shoe-batches', query: {
      'query': query.trim(),
      'shoeSize': shoeSize.trim(),
      'lowStockOnly': lowStockOnly ? 'true' : null,
      'outOfStockOnly': outOfStockOnly ? 'true' : null,
      'page': page,
      'size': pageSize,
    });
    return PageResult.fromJson(json as Map<String, dynamic>, ShoeBatch.fromJson);
  }

  Future<ShoeBatch> createBatch(Map<String, dynamic> body) async {
    final json = await _request('POST', '/api/shoe-batches', body: body);
    return ShoeBatch.fromJson(json as Map<String, dynamic>);
  }

  Future<ShoeBatch> updateBatch(int id, Map<String, dynamic> body) async {
    final json = await _request('PUT', '/api/shoe-batches/$id', body: body);
    return ShoeBatch.fromJson(json as Map<String, dynamic>);
  }

  Future<ShoeBatch> restockBatch(int id, int quantity) async {
    final json = await _request('POST', '/api/shoe-batches/$id/restock',
        body: {'quantity': quantity});
    return ShoeBatch.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deleteBatch(int id) async {
    await _request('DELETE', '/api/shoe-batches/$id');
  }

  // ------------------------------------------------------------ payment modes

  Future<List<PaymentMode>> listPaymentModes({bool activeOnly = false}) async {
    final json = await _request('GET', '/api/payment-modes',
        query: {'activeOnly': activeOnly ? 'true' : null});
    return (json as List)
        .map((e) => PaymentMode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PaymentMode> createPaymentMode(String name) async {
    final json =
        await _request('POST', '/api/payment-modes', body: {'name': name});
    return PaymentMode.fromJson(json as Map<String, dynamic>);
  }

  Future<PaymentMode> setPaymentModeActive(int id, bool active) async {
    final json = await _request('PATCH', '/api/payment-modes/$id/active',
        body: {'active': active});
    return PaymentMode.fromJson(json as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------- sales

  Future<Sale> createSale({
    required int shoeBatchId,
    required double actualSellingPrice,
    required int quantitySold,
    required int paymentModeId,
    String? remarks,
  }) async {
    final json = await _request('POST', '/api/sales', body: {
      'shoeBatchId': shoeBatchId,
      'actualSellingPrice': actualSellingPrice,
      'quantitySold': quantitySold,
      'paymentModeId': paymentModeId,
      if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
    });
    return Sale.fromJson(json as Map<String, dynamic>);
  }

  Future<PageResult<Sale>> searchSales({
    DateTime? from,
    DateTime? to,
    int? paymentModeId,
    int? shoeBatchId,
    String query = '',
    int page = 0,
    int pageSize = 25,
  }) async {
    final json = await _request('GET', '/api/sales', query: {
      'from': from == null ? null : isoDate(from),
      'to': to == null ? null : isoDate(to),
      'paymentModeId': paymentModeId,
      'shoeBatchId': shoeBatchId,
      'query': query.trim(),
      'page': page,
      'size': pageSize,
    });
    return PageResult.fromJson(json as Map<String, dynamic>, Sale.fromJson);
  }

  // ------------------------------------------------------------------ plumbing

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final params = <String, String>{};
    query?.forEach((key, value) {
      if (value == null) return;
      final text = value.toString();
      if (text.isEmpty) return;
      params[key] = text;
    });
    return Uri.parse('$baseUrl$path')
        .replace(queryParameters: params.isEmpty ? null : params);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    final request = http.Request(method, _uri(path, query));
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    http.Response response;
    try {
      final streamed =
          await _client.send(request).timeout(const Duration(seconds: 20));
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException(
          'The server took too long to respond. Please try again.');
    } on http.ClientException catch (e) {
      throw ApiException(
          'Cannot reach the server at $baseUrl. Is the API running? (${e.message})');
    }

    final text = utf8.decode(response.bodyBytes);
    dynamic decoded;
    if (text.isNotEmpty) {
      try {
        decoded = jsonDecode(text);
      } on FormatException {
        decoded = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw _errorFrom(response.statusCode, decoded);
  }

  ApiException _errorFrom(int status, dynamic decoded) {
    var message = 'Request failed ($status).';
    final fieldErrors = <String, String>{};
    if (decoded is Map<String, dynamic>) {
      final m = decoded['message'];
      if (m is String && m.isNotEmpty) message = m;
      final fe = decoded['fieldErrors'];
      if (fe is List) {
        for (final item in fe) {
          if (item is Map && item['field'] != null) {
            fieldErrors['${item['field']}'] = '${item['message']}';
          }
        }
      }
    }
    return ApiException(message, statusCode: status, fieldErrors: fieldErrors);
  }
}
