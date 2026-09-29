import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter/foundation.dart';

import '../models/page_result.dart';
import '../models/sale.dart';
import '../services/api_client.dart';

/// The Sales Log screen's data and filters.
class SalesProvider extends ChangeNotifier {
  SalesProvider(this._api);

  static const int pageSize = 25;

  final ApiClient _api;

  List<Sale> items = [];
  int total = 0;
  int page = 0;
  bool last = true;
  bool loading = false;
  bool loadingMore = false;
  String? error;

  String query = '';
  DateTimeRange? range;
  int? paymentModeId;

  int _seq = 0;

  bool get hasFilters =>
      query.isNotEmpty || range != null || paymentModeId != null;

  /// Totals of the rows currently loaded (not necessarily every match).
  double get shownTotal => items.fold(0.0, (s, e) => s + e.totalAmount);
  int get shownPairs => items.fold(0, (s, e) => s + e.quantitySold);

  Future<void> load() async {
    final seq = ++_seq;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _fetch(0);
      if (seq != _seq) return;
      items = result.content;
      page = 0;
      total = result.totalElements;
      last = result.last;
    } on ApiException catch (e) {
      if (seq != _seq) return;
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (last || loadingMore || loading) return;
    loadingMore = true;
    notifyListeners();
    try {
      final result = await _fetch(page + 1);
      items = [...items, ...result.content];
      page = page + 1;
      total = result.totalElements;
      last = result.last;
    } on ApiException catch (e) {
      error = e.message;
    }
    loadingMore = false;
    notifyListeners();
  }

  void setQuery(String value) {
    query = value;
    load();
  }

  void setRange(DateTimeRange? value) {
    range = value;
    load();
  }

  void setPaymentMode(int? id) {
    paymentModeId = id;
    load();
  }

  void clearFilters() {
    query = '';
    range = null;
    paymentModeId = null;
    load();
  }

  Future<PageResult<Sale>> _fetch(int pageIndex) => _api.searchSales(
        from: range?.start,
        to: range?.end,
        paymentModeId: paymentModeId,
        query: query,
        page: pageIndex,
        pageSize: pageSize,
      );
}
