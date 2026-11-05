import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Shared look for the sign-in screens: the brand mark above a centred card on the paper background.
class AuthFrame extends StatelessWidget {
  const AuthFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.rust,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.inventory_2,
                            size: 22, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Text('Stockroom', style: AppText.display(size: 24)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
