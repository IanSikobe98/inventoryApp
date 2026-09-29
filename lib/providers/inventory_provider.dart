import 'package:flutter/foundation.dart';

import '../models/shoe_batch.dart';
import '../services/api_client.dart';

class InventoryProvider extends ChangeNotifier {
  InventoryProvider(this._api);

  final ApiClient _api;

  List<ShoeBatch> batches = [];
  int total = 0;
  bool loading = false;
  String? error;

  // Filters (kept here so they survive switching screens)
  String query = '';
  String size = '';
  bool lowOnly = false;

  int _seq = 0;

  Future<void> load({bool silent = false}) async {
    final seq = ++_seq;
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final page = await _api.searchBatches(
        query: query,
        shoeSize: size,
        lowStockOnly: lowOnly,
        pageSize: 100,
      );
      if (seq != _seq) return; // a newer request superseded this one
      batches = page.content;
      total = page.totalElements;
      error = null;
    } on ApiException catch (e) {
      if (seq != _seq) return;
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  void setFilters({String? query, String? size, bool? lowOnly}) {
    if (query != null) this.query = query;
    if (size != null) this.size = size;
    if (lowOnly != null) this.lowOnly = lowOnly;
    load();
  }

  // The methods below throw ApiException so the calling form can show it.

  Future<void> create(Map<String, dynamic> body) async {
    await _api.createBatch(body);
    await load(silent: true);
  }

  Future<void> update(int id, Map<String, dynamic> body) async {
    await _api.updateBatch(id, body);
    await load(silent: true);
  }

  Future<void> restock(int id, int quantity) async {
    await _api.restockBatch(id, quantity);
    await load(silent: true);
  }

  Future<void> delete(int id) async {
    await _api.deleteBatch(id);
    await load(silent: true);
  }
}
