import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/shoe_batch.dart';
import '../providers/inventory_provider.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';
import 'picture_field.dart';

/// Opens the add/edit dialog. Pass [batch] to edit, or nothing to add.
Future<void> showBatchForm(BuildContext context, {ShoeBatch? batch}) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: AppColors.paper,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: BatchForm(batch: batch),
      ),
    ),
  );
}

/// Opens the small "how many pairs arrived?" dialog.
Future<void> showRestockDialog(BuildContext context, ShoeBatch batch) {
  return showDialog<void>(
    context: context,
    builder: (_) => _RestockDialog(batch: batch),
  );
}

class BatchForm extends StatefulWidget {
  const BatchForm({super.key, this.batch});

  final ShoeBatch? batch;

  @override
  State<BatchForm> createState() => _BatchFormState();
}

class _BatchFormState extends State<BatchForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _size;
  late final TextEditingController _type;
  late final TextEditingController _colour;
  late final TextEditingController _qty;
  late final TextEditingController _cost;
  late final TextEditingController _wholesale;
  late final TextEditingController _retail;

  /// What will be saved in pictureUrl: base64 text, an older http link, or null for none.
  String? _picture;

  bool _saving = false;
  String? _error;

  bool get _editing => widget.batch != null;

  @override
  void initState() {
    super.initState();
    final b = widget.batch;
    _code = TextEditingController(text: b?.shoeCode ?? '');
    _size = TextEditingController(text: b?.size ?? '');
    _type = TextEditingController(text: b?.type ?? '');
    _colour = TextEditingController(text: b?.colour ?? '');
    _picture = b?.pictureUrl;
    _qty = TextEditingController(
        text: b == null ? '' : b.quantityReceived.toString());
    _cost = TextEditingController(text: b == null ? '' : plainNumber(b.costPerShoe));
    _wholesale =
        TextEditingController(text: b == null ? '' : plainNumber(b.wholesalePrice));
    _retail =
        TextEditingController(text: b == null ? '' : plainNumber(b.retailPrice));
  }

  @override
  void dispose() {
    for (final c in [
      _code, _size, _type, _colour, _qty, _cost, _wholesale, _retail
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  String? _amount(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    final n = double.tryParse(v.trim());
    if (n == null || n < 0) return 'Enter a valid amount';
    return null;
  }

  String? _wholeNumber(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    final n = int.tryParse(v.trim());
    if (n == null || n < 0) return 'Enter a whole number';
    return null;
  }

  Widget _grid(List<Widget> fields) {
    return LayoutBuilder(builder: (context, box) {
      final two = box.maxWidth >= 480;
      final w = two ? (box.maxWidth - 12) / 2 : box.maxWidth;
      return Wrap(
        spacing: 12,
        runSpacing: 14,
        children: [for (final f in fields) SizedBox(width: w, child: f)],
      );
    });
  }

  static final _moneyFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

  Widget _field(
    TextEditingController c,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    String? hint,
    Key? key,
  }) {
    return TextFormField(
      key: key,
      controller: c,
      keyboardType: keyboard,
      inputFormatters: formatters,
      validator: validator,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final body = <String, dynamic>{
      'shoeCode': _code.text.trim(),
      'size': _size.text.trim(),
      'type': _type.text.trim(),
      'colour': _colour.text.trim(),
      'pictureUrl': _picture, // base64 text (or null to have no photo)
      'costPerShoe': double.parse(_cost.text.trim()),
      'wholesalePrice': double.parse(_wholesale.text.trim()),
      'retailPrice': double.parse(_retail.text.trim()),
      if (!_editing) 'quantityReceived': int.parse(_qty.text.trim()),
    };

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final inventory = context.read<InventoryProvider>();
    try {
      if (_editing) {
        await inventory.update(widget.batch!.id, body);
      } else {
        await inventory.create(body);
      }
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(_editing ? 'Batch updated' : 'Batch added'),
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

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text('Delete this batch?', style: AppText.display(size: 18)),
        content: Text(
            'This removes ${widget.batch!.shoeCode} from inventory. '
            'Batches that already have sales recorded can\'t be deleted.',
            style: AppText.body(color: AppColors.inkSoft)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.alert),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await context.read<InventoryProvider>().delete(widget.batch!.id);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('Batch deleted'),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 10, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(_editing ? 'Edit shoe batch' : 'Add a shoe batch',
                    style: AppText.display(size: 20)),
              ),
              IconButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) InlineError(_error!),
                  PictureField(
                    value: _picture,
                    enabled: !_saving,
                    onChanged: (v) => setState(() => _picture = v),
                  ),
                  const SizedBox(height: 16),
                  _grid([
                    _field(_code, 'Shoe code',
                        key: const Key('fieldCode'),
                        hint: 'e.g. SB-2201',
                        validator: (v) => _required(v, 'Shoe code')),
                    _field(_size, 'Size',
                        key: const Key('fieldSize'),
                        hint: 'e.g. 42',
                        validator: (v) => _required(v, 'Size')),
                    _field(_type, 'Type',
                        key: const Key('fieldType'),
                        hint: 'e.g. Sneaker',
                        validator: (v) => _required(v, 'Type')),
                    _field(_colour, 'Colour',
                        key: const Key('fieldColour'),
                        hint: 'e.g. Black',
                        validator: (v) => _required(v, 'Colour')),
                  ]),
                  const SizedBox(height: 14),
                  _grid([
                    if (!_editing)
                      _field(_qty, 'Pairs received',
                          key: const Key('fieldQty'),
                          keyboard: TextInputType.number,
                          formatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) => _wholeNumber(v, 'Pairs received')),
                    _field(_cost, 'Cost per shoe (KSh)',
                        key: const Key('fieldCost'),
                        keyboard:
                            const TextInputType.numberWithOptions(decimal: true),
                        formatters: [_moneyFormatter],
                        validator: (v) => _amount(v, 'Cost')),
                    _field(_wholesale, 'Wholesale price (KSh)',
                        key: const Key('fieldWholesale'),
                        keyboard:
                            const TextInputType.numberWithOptions(decimal: true),
                        formatters: [_moneyFormatter],
                        validator: (v) => _amount(v, 'Wholesale price')),
                    _field(_retail, 'Retail price (KSh)',
                        key: const Key('fieldRetail'),
                        keyboard:
                            const TextInputType.numberWithOptions(decimal: true),
                        formatters: [_moneyFormatter],
                        validator: (v) => _amount(v, 'Retail price')),
                  ]),
                  if (_editing) ...[
                    const SizedBox(height: 12),
                    Text(
                        'To add stock to this batch, use Restock on its card.',
                        style: AppText.body(
                            size: 12, color: AppColors.inkSoft)),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Row(
            children: [
              if (_editing)
                TextButton.icon(
                  onPressed: _saving ? null : _confirmDelete,
                  style: TextButton.styleFrom(foregroundColor: AppColors.alert),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                ),
              const Spacer(),
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('saveBatch'),
                onPressed: _saving ? null : _submit,
                child: Text(_saving
                    ? 'Saving…'
                    : (_editing ? 'Save changes' : 'Add batch')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RestockDialog extends StatefulWidget {
  const _RestockDialog({required this.batch});

  final ShoeBatch batch;

  @override
  State<_RestockDialog> createState() => _RestockDialogState();
}

class _RestockDialogState extends State<_RestockDialog> {
  final _qty = TextEditingController(text: '1');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final n = int.tryParse(_qty.text.trim()) ?? 0;
    if (n < 1) {
      setState(() => _error = 'Enter at least 1 pair');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await context.read<InventoryProvider>().restock(widget.batch.id, n);
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text('Added $n pair${n == 1 ? '' : 's'} to ${widget.batch.shoeCode}'),
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
    final b = widget.batch;
    return AlertDialog(
      backgroundColor: AppColors.paper,
      title: Text('Restock ${b.shoeCode}', style: AppText.display(size: 19)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${b.title} · size ${b.size}\nCurrently ${b.quantityRemaining} in stock.',
                style: AppText.body(color: AppColors.inkSoft)),
            const SizedBox(height: 16),
            if (_error != null) InlineError(_error!),
            TextField(
              key: const Key('restockQty'),
              controller: _qty,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Pairs to add'),
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
          key: const Key('confirmRestock'),
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Saving…' : 'Add stock'),
        ),
      ],
    );
  }
}
