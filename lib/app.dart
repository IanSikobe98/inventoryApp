import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/dashboard_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/payment_modes_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/session_provider.dart';
import 'screens/app_shell.dart';
import 'services/api_client.dart';
import 'theme/app_theme.dart';

/// Wires up the API client and all providers. Tests use this too, passing in
/// an [ApiClient] backed by a fake HTTP client.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, this.api, required this.child});

  final ApiClient? api;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => api ?? ApiClient()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(
            create: (c) => DashboardProvider(c.read<ApiClient>())),
        ChangeNotifierProvider(
            create: (c) => InventoryProvider(c.read<ApiClient>())),
        ChangeNotifierProvider(
            create: (c) => PaymentModesProvider(c.read<ApiClient>())),
        ChangeNotifierProvider(
            create: (c) => SalesProvider(c.read<ApiClient>())),
      ],
      child: child,
    );
  }
}

class StockroomApp extends StatelessWidget {
  const StockroomApp({super.key, this.api});

  final ApiClient? api;

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      api: api,
      child: MaterialApp(
        title: 'Stockroom',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AppShell(),
      ),
    );
  }
}
