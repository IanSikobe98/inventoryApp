import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../app_shell.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

/// Decides what to show: sign-in, the code screen, or the app itself.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final stage = context.select<AuthProvider, AuthStage>((a) => a.stage);
    return switch (stage) {
      AuthStage.signedOut => const LoginScreen(),
      AuthStage.otpPending => const OtpScreen(),
      AuthStage.signedIn => const AppShell(),
    };
  }
}
