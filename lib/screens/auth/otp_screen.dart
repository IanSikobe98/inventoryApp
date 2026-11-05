import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'auth_frame.dart';

/// Step 2 of sign-in: the one-time code that was emailed to the person.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Re-draw every second so the countdown moves.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final auth = context.read<AuthProvider>();
    if (auth.busy) return;
    await auth.verifyOtp(_code.text);
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    if (auth.busy) return;
    _code.clear();
    await auth.resendCode();
  }

  String _remaining(AuthProvider auth) {
    final end = auth.otpExpiresAt;
    if (end == null) return '';
    final left = end.difference(DateTime.now());
    if (left.isNegative) return '00:00';
    final m = left.inMinutes.toString().padLeft(2, '0');
    final s = (left.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final expired =
        auth.otpExpiresAt != null && !DateTime.now().isBefore(auth.otpExpiresAt!);

    return AuthFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.pineTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.mark_email_unread_outlined,
                  color: AppColors.pine),
            ),
          ),
          const SizedBox(height: 16),
          Text('Check your email', style: AppText.display(size: 26)),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: AppText.body(size: 14, color: AppColors.inkSoft),
              children: [
                const TextSpan(text: 'We sent a one-time code for '),
                TextSpan(
                    text: auth.username,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.ink)),
                const TextSpan(text: '. Enter it below.'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            key: const Key('otpField'),
            controller: _code,
            enabled: !auth.busy,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofillHints: const [AutofillHints.oneTimeCode],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _verify(),
            style: AppText.mono(size: 26, weight: FontWeight.w600)
                .copyWith(letterSpacing: 8),
            decoration: const InputDecoration(
              hintText: '•••••',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined,
                  size: 15, color: expired ? AppColors.alert : AppColors.inkSoft),
              const SizedBox(width: 6),
              Text(
                expired ? 'This code has expired' : 'Expires in ${_remaining(auth)}',
                key: const Key('otpCountdown'),
                style: AppText.body(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: expired ? AppColors.alert : AppColors.inkSoft),
              ),
            ],
          ),
          if (auth.notice != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.pineTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(auth.notice!,
                  style: AppText.body(size: 13, color: AppColors.pine)),
            ),
          ],
          if (auth.error != null) ...[
            const SizedBox(height: 12),
            InlineError(auth.error!),
          ],
          const SizedBox(height: 18),
          FilledButton(
            key: const Key('otpSubmit'),
            onPressed: auth.busy ? null : _verify,
            child: auth.busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white))
                : const Text('Verify and sign in'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                key: const Key('otpBack'),
                onPressed: auth.busy ? null : auth.backToLogin,
                child: const Text('Use a different account'),
              ),
              TextButton(
                key: const Key('otpResend'),
                onPressed: auth.busy ? null : _resend,
                child: const Text('Send a new code'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
