import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/shoe_batch.dart';
import '../providers/payment_modes_provider.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';
import 'shoe_photo.dart';

/// The "record a sale" form for one shoe batch.
/// Calls [onSold] after the API confirms the sale.
class SaleForm extends StatefulWidget {
  const SaleForm({super.key, required this.batch, required this.onSold});

  final ShoeBatch batch;
  final VoidCallback onSold;

  @override
  State<SaleForm> createState() => _SaleFormState();
}

class _SaleFormState extends State<SaleForm> {
  late final TextEditingController _qty = TextEditingController(text: '1');
  late final TextEditingController _price =
      TextEditingController(text: plainNumber(widget.batch.retailPrice));
  final TextEditingController _remarks = TextEditingController();

  int? _modeId;
  bool _saving = false;
  String? _error;

  int get _remaining => widget.batch.quantityRemaining;
  int get _qtyValue => int.tryParse(_qty.text.trim()) ?? 0;
  double? get _priceValue => double.tryParse(_price.text.trim());
  bool get _qtyValid => _qtyValue >= 1 && _qtyValue <= _remaining;
  bool get _priceValid => _priceValue != null && _priceValue! >= 0;
  double get _total => _qtyValid && _priceValid ? _qtyValue * _priceValue! : 0;
  bool get _canSubmit => _qtyValid && _priceValid && _modeId != null && !_saving;

  @override
  void initState() {
    super.initState();
    _qty.addListener(_rebuild);
    _price.addListener(_rebuild);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PaymentModesProvider>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    _remarks.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _step(int delta) {
    final next = math.max(1, math.min(_remaining, _qtyValue + delta));
    _qty.text = next.toString();
    _qty.selection = TextSelection.collapsed(offset: _qty.text.length);
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final api = context.read<ApiClient>();
    final total = _total;
    try {
      await api.createSale(
        shoeBatchId: widget.batch.id,
        actualSellingPrice: _priceValue!,
        quantitySold: _qtyValue,
        paymentModeId: _modeId!,
        remarks: _remarks.text,
      );
      messenger.showSnackBar(SnackBar(
        content: Text('Sale recorded · ${formatMoney(total)}'),
        behavior: SnackBarBehavior.floating,
      ));
      widget.onSold();
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
    final modes = context.watch<PaymentModesProvider>();
    final active = modes.activeModes;
    final belowCost = _priceValid && _priceValue! < b.costPerShoe;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected shoe
        Row(
          children: [
            ShoePhoto(url: b.pictureUrl, width: 56, height: 56, radius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.display(size: 17)),
                  const SizedBox(height: 2),
                  Text('${b.shoeCode} · size ${b.size} · $_remaining in stock',
                      style: AppText.body(size: 12, color: AppColors.inkSoft)),
                ],
              ),
            ),
          ],
        ),
        const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider()),

        if (_error != null) InlineError(_error!),

        // Quantity
        Text('Quantity sold',
            style: AppText.body(
                size: 12, weight: FontWeight.w600, color: AppColors.inkSoft)),
        const SizedBox(height: 6),
        Row(
          children: [
            _StepButton(icon: Icons.remove, onTap: () => _step(-1)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                key: const Key('qtyField'),
                controller: _qty,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppText.mono(size: 16, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10),
            _StepButton(icon: Icons.add, onTap: () => _step(1)),
          ],
        ),
        if (!_qtyValid)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Enter a number from 1 to $_remaining',
                style: AppText.body(size: 12, color: AppColors.alert)),
          ),
        const SizedBox(height: 16),

        // Price
        Text('Actual selling price (per pair)',
            style: AppText.body(
                size: 12, weight: FontWeight.w600, color: AppColors.inkSoft)),
        const SizedBox(height: 6),
        TextField(
          key: const Key('priceField'),
          controller: _price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          style: AppText.mono(size: 15, weight: FontWeight.w600),
          decoration: const InputDecoration(prefixText: 'KSh  '),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ActionChip(
              label: Text('Retail ${formatMoney(b.retailPrice)}'),
              onPressed: () => _price.text = plainNumber(b.retailPrice),
              backgroundColor: AppColors.paper2,
              side: BorderSide.none,
            ),
            ActionChip(
              label: Text('Wholesale ${formatMoney(b.wholesalePrice)}'),
              onPressed: () => _price.text = plainNumber(b.wholesalePrice),
              backgroundColor: AppColors.paper2,
              side: BorderSide.none,
            ),
          ],
        ),
        if (belowCost)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
                'Below cost (${formatMoney(b.costPerShoe)} per pair): this sale loses money.',
                style: AppText.body(size: 12, color: AppColors.alert)),
          ),
        const SizedBox(height: 16),

        // Payment mode
        Text('Mode of payment',
            style: AppText.body(
                size: 12, weight: FontWeight.w600, color: AppColors.inkSoft)),
        const SizedBox(height: 8),
        if (modes.loading && active.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.rust)),
          )
        else if (active.isEmpty)
          Text(
              modes.error ??
                  'No active payment modes. An admin can add one under Payment modes.',
              style: AppText.body(size: 13, color: AppColors.alert))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in active)
                ChoiceChip(
                  label: Text(m.name),
                  selected: _modeId == m.id,
                  onSelected: (_) => setState(() => _modeId = m.id),
                  selectedColor: AppColors.pineTint,
                  backgroundColor: AppColors.card,
                  side: BorderSide(
                      color: _modeId == m.id ? AppColors.pine : AppColors.line),
                ),
            ],
          ),
        const SizedBox(height: 16),

        // Remarks
        TextField(
          controller: _remarks,
          maxLines: 2,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Remarks (optional)',
            hintText: 'e.g. customer asked for a discount',
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),

        // Total
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.pine,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text('TOTAL AMOUNT',
                    style: AppText.body(
                            size: 11,
                            weight: FontWeight.w600,
                            color: const Color(0xCCFFFFFF))
                        .copyWith(letterSpacing: 0.6)),
              ),
              Text(formatMoney(_total),
                  style: AppText.display(size: 24, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('confirmSale'),
            onPressed: _canSubmit ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.rust,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(_saving ? 'Saving…' : 'Confirm sale'),
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper2,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, size: 20, color: AppColors.ink),
        ),
      ),
    );
  }
}
