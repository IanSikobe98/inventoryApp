import 'package:flutter/material.dart';

enum AppRoute { dashboard, inventory, sell, sales, payments }

extension AppRouteX on AppRoute {
  String get label => switch (this) {
        AppRoute.dashboard => 'Dashboard',
        AppRoute.inventory => 'Inventory',
        AppRoute.sell => 'Record sale',
        AppRoute.sales => 'Sales log',
        AppRoute.payments => 'Payment modes',
      };

  String get shortLabel => switch (this) {
        AppRoute.dashboard => 'Dashboard',
        AppRoute.inventory => 'Inventory',
        AppRoute.sell => 'Sell',
        AppRoute.sales => 'Sales',
        AppRoute.payments => 'Payments',
      };

  IconData get icon => switch (this) {
        AppRoute.dashboard => Icons.space_dashboard_outlined,
        AppRoute.inventory => Icons.inventory_2_outlined,
        AppRoute.sell => Icons.point_of_sale,
        AppRoute.sales => Icons.receipt_long_outlined,
        AppRoute.payments => Icons.account_balance_wallet_outlined,
      };
}

/// Which screen is showing, and whether the signed-in person is an admin or an
/// employee (taken from their role at sign-in). The role here only decides which
/// screens are offered: it is a UI convenience, not security. Real access
/// control belongs on the API.
class SessionProvider extends ChangeNotifier {
  bool _admin = true;
  AppRoute _route = AppRoute.dashboard;

  bool get isAdmin => _admin;
  AppRoute get route => _route;

  List<AppRoute> get routes =>
      _admin ? AppRoute.values : const [AppRoute.sell, AppRoute.sales];

  /// Called after sign-in: the role from the server decides which screens show.
  void applyRole({required bool admin}) {
    _admin = admin;
    _route = routes.first;
    notifyListeners();
  }

  /// Called on sign-out so the next person starts from a clean slate.
  void reset() => applyRole(admin: false);

  void setAdmin(bool value) {
    if (_admin == value) return;
    _admin = value;
    if (!routes.contains(_route)) _route = routes.first;
    notifyListeners();
  }

  void go(AppRoute route) {
    if (!routes.contains(route) || _route == route) return;
    _route = route;
    notifyListeners();
  }
}
