import 'package:flutter/foundation.dart';

import '../models/dashboard_data.dart';
import '../models/sale.dart';
import '../services/api_client.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._api);

  final ApiClient _api;

  DashboardData? data;
  List<Sale> recentSales = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      data = await _api.getDashboard();
      recentSales = (await _api.searchSales(pageSize: 8)).content;
    } on ApiException catch (e) {
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }
}
