import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/payment_modes_provider.dart';
import '../providers/sales_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/sale_tile.dart';

class SalesLogScreen extends StatefulWidget {
  const SalesLogScreen({super.key});

  @override
  State<SalesLogScreen> createState() => _SalesLogScreenState();
}

class _SalesLogScreenState extends State<SalesLogScreen> {
  late final TextEditingController _search;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final sales = context.read<SalesProvider>();
    _search = TextEditingController(text: sales.query);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      sales.load();
      context.read<PaymentModesProvider>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final sales = context.read<SalesProvider>();
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
      initialDateRange: sales.range,
    );
    if (picked != null) sales.setRange(picked);
  }

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesProvider>();
    final modes = context.watch<PaymentModesProvider>().modes;

    Widget content;
    if (sales.loading && sales.items.isEmpty) {
      content = const LoadingBox();
    } else if (sales.error != null && sales.items.isEmpty) {
      content = ErrorView(message: sales.error!, onRetry: () => sales.load());
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Showing ${sales.items.length} of ${sales.total} sale${sales.total == 1 ? '' : 's'}'
              ' · ${sales.shownPairs} pairs · ${formatMoney(sales.shownTotal)}',
              style: AppText.body(size: 12.5, color: AppColors.inkSoft),
            ),
          ),
          SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: SaleList(sales: sales.items),
          ),
          if (!sales.last)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Center(
                child: OutlinedButton(
                  onPressed: sales.loadingMore ? null : () => sales.loadMore(),
                  child: Text(sales.loadingMore ? 'Loading…' : 'Load more'),
                ),
              ),
            ),
        ],
      );
    }

    final range = sales.range;
    return ScreenFrame(
      title: 'Sales log',
      subtitle: 'Every sale recorded, most recent first.',
      onRefresh: () => sales.load(),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                controller: _search,
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 350), () {
                    if (mounted) sales.setQuery(v);
                  });
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 20),
                  hintText: 'Search shoe',
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _pickRange,
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(range == null
                  ? 'Any date'
                  : '${formatShortDate(range.start)} – ${formatShortDate(range.end)}'),
            ),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<int?>(
                value: sales.paymentModeId,
                isExpanded: true,
                decoration: const InputDecoration(),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('All payment modes')),
                  for (final m in modes)
                    DropdownMenuItem<int?>(value: m.id, child: Text(m.name)),
                ],
                onChanged: (v) => sales.setPaymentMode(v),
              ),
            ),
            if (sales.hasFilters)
              TextButton.icon(
                onPressed: () {
                  _search.clear();
                  sales.clearFilters();
                },
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('Clear filters'),
              ),
          ],
        ),
        const SizedBox(height: 18),
        content,
      ],
    );
  }
}
