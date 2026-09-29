import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'payment_modes_screen.dart';
import 'sales_log_screen.dart';
import 'sell_screen.dart';

/// Wide screens get a sidebar; phones get a bottom navigation bar.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  Widget _screenFor(AppRoute route) => switch (route) {
        AppRoute.dashboard => const DashboardScreen(),
        AppRoute.inventory => const InventoryScreen(),
        AppRoute.sell => const SellScreen(),
        AppRoute.sales => const SalesLogScreen(),
        AppRoute.payments => const PaymentModesScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final wide = MediaQuery.of(context).size.width >= 900;

    // Re-creating the screen on every route change makes each one reload
    // fresh data when you navigate to it.
    final body = KeyedSubtree(
      key: ValueKey(session.route),
      child: _screenFor(session.route),
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            const _Sidebar(),
            Expanded(child: SafeArea(child: body)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const _Brand(compact: true),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: RoleToggle()),
          ),
        ],
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.paper2,
        indicatorColor: AppColors.rustSoft,
        selectedIndex: session.routes.indexOf(session.route),
        onDestinationSelected: (i) => session.go(session.routes[i]),
        destinations: [
          for (final r in session.routes)
            NavigationDestination(icon: Icon(r.icon), label: r.shortLabel),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.rust,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.inventory_2, size: 19, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stockroom', style: AppText.display(size: 18)),
            if (!compact)
              Text('Shoe inventory & sales',
                  style: AppText.body(size: 11, color: AppColors.inkSoft)),
          ],
        ),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return Container(
      width: 236,
      decoration: const BoxDecoration(
        color: AppColors.paper2,
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 20),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: _Brand(),
            ),
            const SizedBox(height: 28),
            for (final r in session.routes)
              _NavItem(
                route: r,
                selected: session.route == r,
                onTap: () => session.go(r),
              ),
            const Spacer(),
            const Divider(),
            const SizedBox(height: 14),
            Text('VIEWING AS',
                style: AppText.body(
                        size: 10.5,
                        weight: FontWeight.w600,
                        color: AppColors.inkSoft)
                    .copyWith(letterSpacing: 0.7)),
            const SizedBox(height: 8),
            const RoleToggle(expand: true),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.route,
    required this.selected,
    required this.onTap,
  });

  final AppRoute route;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.inkSoft;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected ? AppColors.rust : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(route.icon, size: 19, color: fg),
                const SizedBox(width: 12),
                Text(route.label,
                    style: AppText.body(
                        size: 14, weight: FontWeight.w500, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Admin / Employee switch. It only changes which screens are offered.
class RoleToggle extends StatelessWidget {
  const RoleToggle({super.key, this.expand = false});

  final bool expand;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    Widget seg(String label, bool selected, VoidCallback onTap) {
      final child = InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.pine : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: AppText.body(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.inkSoft)),
        ),
      );
      return expand ? Expanded(child: child) : child;
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          seg('Admin', session.isAdmin, () => session.setAdmin(true)),
          seg('Employee', !session.isAdmin, () => session.setAdmin(false)),
        ],
      ),
    );
  }
}
