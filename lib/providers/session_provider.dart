import 'package:flutter/material.dart';

import '../models/auth.dart';
import '../models/permissions.dart';

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

/// Which screen is showing, and what the signed-in person is allowed to see.
///
/// Permissions come from `usersPerm` at sign-in. They only decide which tabs and
/// buttons are shown: it is a UI convenience, not security. Real access control
/// belongs on the API.
class SessionProvider extends ChangeNotifier {
  SessionProvider({Set<String> permissions = const {}})
      : _perms = {for (final p in permissions) p.trim().toUpperCase()} {
    _route = _firstRoute();
  }

  Set<String> _perms;
  late AppRoute _route;

  AppRoute get route => _route;

  /// True when the person holds [permission] (for example `Perm.createSales`).
  bool can(String permission) => _perms.contains(permission.trim().toUpperCase());

  /// Whether [route] is offered to this person.
  bool canOpen(AppRoute route) => switch (route) {
        // Every signed-in person gets the dashboard.
        AppRoute.dashboard => true,
        AppRoute.inventory => can(Perm.viewInventory),
        AppRoute.sell => can(Perm.createSales),
        AppRoute.sales => can(Perm.viewSales),
        AppRoute.payments => can(Perm.viewPayment),
      };

  /// The tabs this person gets, in menu order. The dashboard is always first.
  List<AppRoute> get routes => AppRoute.values.where(canOpen).toList();

  AppRoute _firstRoute() {
    final r = routes;
    return r.isEmpty ? AppRoute.dashboard : r.first;
  }

  /// Called after sign-in.
  void applyUser(AuthUser user) {
    _perms = {for (final p in user.permissions) p.trim().toUpperCase()};
    _route = _firstRoute();
    notifyListeners();
  }

  /// Called on sign-out so the next person starts with nothing.
  void reset() {
    _perms = {};
    _route = _firstRoute();
    notifyListeners();
  }

  void go(AppRoute route) {
    if (!routes.contains(route) || _route == route) return;
    _route = route;
    notifyListeners();
  }
}
