import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Asks "Sign out?" and, if confirmed, ends the session.
Future<void> confirmSignOut(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text('Sign out?', style: AppText.display(size: 20)),
      content: Text(
          'You will need a new one-time code to sign back in.',
          style: AppText.body(size: 14, color: AppColors.inkSoft)),
      actions: [
        TextButton(
          key: const Key('cancelSignOut'),
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Stay signed in'),
        ),
        FilledButton(
          key: const Key('confirmSignOut'),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  if (ok == true) await auth.signOut();
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.user, {this.size = 34});

  final AuthUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.pine,
        shape: BoxShape.circle,
      ),
      child: Text(user.initials,
          style: AppText.body(
              size: size * 0.38, weight: FontWeight.w600, color: Colors.white)),
    );
  }
}

String _roleLabel(AuthUser user) => user.role.isEmpty ? 'Signed in' : user.role;

/// Phone top bar: the person's avatar; tapping it shows who they are and "Sign out".
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, AuthUser?>((a) => a.user);
    if (user == null) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      key: const Key('accountMenu'),
      tooltip: 'Account',
      color: AppColors.card,
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.line)),
      onSelected: (v) {
        if (v == 'signout') confirmSignOut(context);
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name,
                  style: AppText.body(size: 14, weight: FontWeight.w600)),
              Text(_roleLabel(user),
                  style: AppText.body(size: 12, color: AppColors.inkSoft)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          key: const Key('signOutItem'),
          value: 'signout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 18, color: AppColors.alert),
              const SizedBox(width: 10),
              Text('Sign out',
                  style: AppText.body(
                      size: 14, weight: FontWeight.w500, color: AppColors.alert)),
            ],
          ),
        ),
      ],
      child: _Avatar(user),
    );
  }
}

/// Sidebar footer on wide screens: who is signed in, their role, and "Sign out".
class AccountCard extends StatelessWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, AuthUser?>((a) => a.user);
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Avatar(user, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(size: 13.5, weight: FontWeight.w600)),
                  Text(_roleLabel(user),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(size: 12, color: AppColors.inkSoft)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('signOut'),
          onPressed: () => confirmSignOut(context),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
