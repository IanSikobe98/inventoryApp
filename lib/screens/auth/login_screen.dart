import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'auth_frame.dart';

/// Step 1 of sign-in: username and password.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (auth.busy) return;
    await auth.signIn(_username.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthFrame(
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Welcome back', style: AppText.display(size: 26)),
            const SizedBox(height: 6),
            Text('Sign in to record sales and manage stock.',
                style: AppText.body(size: 14, color: AppColors.inkSoft)),
            const SizedBox(height: 22),
            TextField(
              key: const Key('loginUsername'),
              controller: _username,
              enabled: !auth.busy,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('loginPassword'),
              controller: _password,
              enabled: !auth.busy,
              obscureText: _hidePassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  key: const Key('togglePassword'),
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20),
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                ),
              ),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 14),
              InlineError(auth.error!),
            ],
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('loginSubmit'),
              onPressed: auth.busy ? null : _submit,
              child: auth.busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white))
                  : const Text('Continue'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mail_outline,
                    size: 15, color: AppColors.inkSoft),
                const SizedBox(width: 6),
                Flexible(
                  child: Text("We'll email you a one-time code to finish.",
                      style: AppText.body(size: 12.5, color: AppColors.inkSoft)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
