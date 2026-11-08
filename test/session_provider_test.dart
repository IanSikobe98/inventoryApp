import 'package:flutter_test/flutter_test.dart';
import 'package:stockroom_app/models/auth.dart';
import 'package:stockroom_app/models/permissions.dart';
import 'package:stockroom_app/providers/session_provider.dart';

AuthUser userWith(List<String> perms) =>
    AuthUser(name: 'T', username: 't', role: 'X', permissions: perms);

void main() {
  test('nobody signed in: no permissions and no screens', () {
    final s = SessionProvider();
    expect(s.routes, isEmpty);
    expect(s.can(Perm.viewInventory), isFalse);
  });

  test('each tab needs its own permission', () {
    final cases = {
      Perm.viewInventory: [AppRoute.inventory],
      Perm.createSales: [AppRoute.sell],
      Perm.viewSales: [AppRoute.sales],
      Perm.viewPayment: [AppRoute.payments],
    };
    cases.forEach((perm, expected) {
      final s = SessionProvider(permissions: {perm});
      expect(s.routes, expected, reason: perm);
    });
  });

  test('buttons-only permissions open no tab', () {
    final s = SessionProvider(permissions: {
      Perm.createInventory,
      Perm.updateInventory,
      Perm.createPayment,
    });
    expect(s.routes, isEmpty);
  });

  test('the dashboard needs both stock and sales to be viewable', () {
    expect(SessionProvider(permissions: {Perm.viewInventory}).canOpen(AppRoute.dashboard), isFalse);
    expect(SessionProvider(permissions: {Perm.viewSales}).canOpen(AppRoute.dashboard), isFalse);
    expect(
        SessionProvider(permissions: {Perm.viewInventory, Perm.viewSales})
            .canOpen(AppRoute.dashboard),
        isTrue);
  });

  test('tabs come in menu order', () {
    final s = SessionProvider(permissions: Perm.all);
    expect(s.routes, [
      AppRoute.dashboard,
      AppRoute.inventory,
      AppRoute.sell,
      AppRoute.sales,
      AppRoute.payments,
    ]);
  });

  test('permission names ignore case and spaces', () {
    final s = SessionProvider();
    s.applyUser(userWith([' view_sales ', 'Create_Sales']));
    expect(s.can(Perm.viewSales), isTrue);
    expect(s.can('create_sales'), isTrue);
    expect(s.routes, [AppRoute.sell, AppRoute.sales]);
  });

  test('applyUser starts on the first allowed tab; reset clears everything', () {
    final s = SessionProvider();
    s.applyUser(userWith([Perm.viewSales, Perm.viewPayment]));
    expect(s.route, AppRoute.sales);
    s.reset();
    expect(s.routes, isEmpty);
    expect(s.can(Perm.viewSales), isFalse);
  });

  test('go() refuses a tab the person may not open', () {
    final s = SessionProvider(permissions: {Perm.viewSales, Perm.createSales});
    s.go(AppRoute.payments);
    expect(s.route, AppRoute.sell);
    s.go(AppRoute.sales);
    expect(s.route, AppRoute.sales);
  });
}
