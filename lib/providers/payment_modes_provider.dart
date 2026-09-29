import 'package:flutter/foundation.dart';

import '../models/payment_mode.dart';
import '../services/api_client.dart';

class PaymentModesProvider extends ChangeNotifier {
  PaymentModesProvider(this._api);

  final ApiClient _api;

  List<PaymentMode> modes = [];
  bool loading = false;
  String? error;
  bool _loadedOnce = false;

  List<PaymentMode> get activeModes => modes.where((m) => m.active).toList();

  /// Cheap call for screens that just need the list to exist.
  Future<void> loadIfNeeded() async {
    if (_loadedOnce || loading) return;
    await load();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      modes = await _api.listPaymentModes();
      _loadedOnce = true;
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> create(String name) async {
    await _api.createPaymentMode(name);
    await load(silent: true);
  }

  Future<void> setActive(PaymentMode mode, bool active) async {
    await _api.setPaymentModeActive(mode.id, active);
    await load(silent: true);
  }
}
