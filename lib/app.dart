import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/payment_modes_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/session_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'services/api_client.dart';
import 'services/password_cipher.dart';
import 'services/picture_service.dart';
import 'theme/app_theme.dart';

/// Wires up the API client and all providers. Tests use this too, passing in
/// an [ApiClient] backed by a fake HTTP client.
class AppProviders extends StatelessWidget {
  const AppProviders({
    super.key,
    this.api,
    this.pictures,
    this.cipher,
    this.permissions,
    required this.child,
  });

  final ApiClient? api;

  /// Camera/gallery access. Tests pass a fake so no real picker opens.
  final PictureService? pictures;

  /// How the password is protected before it is sent (tests pass a plain one).
  final PasswordCipher? cipher;

  /// Starting permissions. Normally empty until sign-in; tests pass some.
  final Set<String>? permissions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => api ?? ApiClient()),
        Provider<PictureService>(create: (_) => pictures ?? PictureService()),
        Provider<PasswordCipher>(
            create: (_) => cipher ?? PasswordCipher.fromEnvironment()),
        ChangeNotifierProvider(
            create: (_) => SessionProvider(permissions: permissions ?? const {})),
        ChangeNotifierProvider(
            create: (c) => AuthProvider(
                  api: c.read<ApiClient>(),
                  cipher: c.read<PasswordCipher>(),
                  session: c.read<SessionProvider>(),
                )),
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
  const StockroomApp({super.key, this.api, this.pictures, this.cipher});

  final ApiClient? api;
  final PictureService? pictures;
  final PasswordCipher? cipher;

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      api: api,
      pictures: pictures,
      cipher: cipher,
      child: MaterialApp(
        title: 'Stockroom',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AuthGate(),
      ),
    );
  }
}
