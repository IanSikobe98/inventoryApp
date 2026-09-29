import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shoe_batch.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/sale_form.dart';
import '../widgets/shoe_photo.dart';

/// Employee-facing screen: pick a batch, then record the sale.
/// Wide screens show the form beside the list; phones open it in a sheet.
class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  List<ShoeBatch> _batches = [];
  bool _loading = true;
  String? _error;
  ShoeBatch? _selected;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context
          .read<ApiClient>()
          .searchBatches(query: _search.text, pageSize: 100);
      if (!mounted || seq != _seq) return;
      setState(() {
        _batches = page.content;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  void _afterSale() {
    setState(() => _selected = null);
    _load();
  }

  Future<void> _pick(ShoeBatch batch, bool wide) async {
    if (wide) {
      setState(() => _selected = batch);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: SaleForm(
            batch: batch,
            onSold: () {
              Navigator.of(sheetContext).pop();
              _afterSale();
            },
          ),
        ),
      ),
    );
  }

  Widget _list(bool wide) {
    if (_loading && _batches.isEmpty) return const LoadingBox();
    if (_error != null && _batches.isEmpty) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    if (_batches.isEmpty) {
      return const EmptyState(
          icon: Icons.inventory_2_outlined,
          message: 'No shoe batches found. Add stock under Inventory first.');
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _batches.length,
      separatorBuilder: (context, i) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final b = _batches[i];
        return _PickerItem(
          batch: b,
          selected: _selected?.id == b.id,
          onTap: b.outOfStock ? null : () => _pick(b, wide),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    final pad = screenPadding(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 24, pad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenHeader(
            title: 'Record a sale',
            subtitle: 'Pick a shoe batch, then log what was sold.',
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 420,
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 20),
                hintText: 'Search code, type or colour',
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _list(true)),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 400,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: SectionCard(
                            child: _selected == null
                                ? const EmptyState(
                                    icon: Icons.point_of_sale,
                                    message: 'Select a shoe batch to begin.')
                                : SaleForm(
                                    key: ValueKey(_selected!.id),
                                    batch: _selected!,
                                    onSold: _afterSale,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  )
                : _list(false),
          ),
        ],
      ),
    );
  }
}

class _PickerItem extends StatelessWidget {
  const _PickerItem({
    required this.batch,
    required this.selected,
    required this.onTap,
  });

  final ShoeBatch batch;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final out = batch.outOfStock;
    return Opacity(
      opacity: out ? 0.45 : 1,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.rust : AppColors.line,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                ShoePhoto(
                    url: batch.pictureUrl,
                    width: 54,
                    height: 54,
                    radius: 8,
                    iconSize: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(batch.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(weight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('${batch.shoeCode} · size ${batch.size}',
                          style: AppText.body(
                              size: 12, color: AppColors.inkSoft)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(out ? 'Out of stock' : '${batch.quantityRemaining} left',
                        style: AppText.mono(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: (out || batch.lowStock)
                                ? AppColors.alert
                                : AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(formatMoney(batch.retailPrice),
                        style:
                            AppText.mono(size: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
