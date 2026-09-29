import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/payment_modes_provider.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class PaymentModesScreen extends StatefulWidget {
  const PaymentModesScreen({super.key});

  @override
  State<PaymentModesScreen> createState() => _PaymentModesScreenState();
}

class _PaymentModesScreenState extends State<PaymentModesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PaymentModesProvider>().load();
    });
  }

  Future<void> _toggle(PaymentModesProvider p, int index, bool value) async {
    try {
      await p.setActive(p.modes[index], value);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PaymentModesProvider>();

    Widget content;
    if (p.loading && p.modes.isEmpty) {
      content = const LoadingBox();
    } else if (p.error != null && p.modes.isEmpty) {
      content = ErrorView(message: p.error!, onRetry: () => p.load());
    } else if (p.modes.isEmpty) {
      content = const EmptyState(
          icon: Icons.account_balance_wallet_outlined,
          message: 'No payment modes yet. Add one to start recording sales.');
    } else {
      content = SectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        child: Column(
          children: [
            for (var i = 0; i < p.modes.length; i++) ...[
              if (i > 0) const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(p.modes[i].name,
                          style: AppText.body(
                              size: 15, weight: FontWeight.w600)),
                    ),
                    Pill(
                      label: p.modes[i].active ? 'Active' : 'Inactive',
                      background: p.modes[i].active
                          ? AppColors.pineTint
                          : AppColors.paper2,
                      foreground: p.modes[i].active
                          ? AppColors.pine
                          : AppColors.inkSoft,
                    ),
                    const SizedBox(width: 10),
                    Switch(
                      value: p.modes[i].active,
                      activeColor: Colors.white,
                      activeTrackColor: AppColors.pine,
                      onChanged: (v) => _toggle(p, i, v),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ScreenFrame(
      title: 'Payment modes',
      subtitle: 'Choose how customers can pay.',
      onRefresh: () => p.load(),
      action: FilledButton.icon(
        key: const Key('addPaymentMode'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const _AddModeDialog(),
        ),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add mode'),
      ),
      children: [content],
    );
  }
}

class _AddModeDialog extends StatefulWidget {
  const _AddModeDialog();

  @override
  State<_AddModeDialog> createState() => _AddModeDialogState();
}

class _AddModeDialogState extends State<_AddModeDialog> {
  final _name = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await context.read<PaymentModesProvider>().create(name);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('Payment mode added'),
        behavior: SnackBarBehavior.floating,
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.fullMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.paper,
      title: Text('Add payment mode', style: AppText.display(size: 19)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) InlineError(_error!),
            TextField(
              key: const Key('modeName'),
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'Name', hintText: 'e.g. Airtel Money'),
              onSubmitted: (_) => _saving ? null : _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Saving…' : 'Add'),
        ),
      ],
    );
  }
}
