import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/permissions.dart';
import '../providers/inventory_provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/batch_card.dart';
import '../widgets/batch_form.dart';
import '../widgets/common.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late final TextEditingController _search;
  late final TextEditingController _size;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final inv = context.read<InventoryProvider>();
    _search = TextEditingController(text: inv.query);
    _size = TextEditingController(text: inv.size);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) inv.load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _size.dispose();
    super.dispose();
  }

  void _onTyping() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context
          .read<InventoryProvider>()
          .setFilters(query: _search.text, size: _size.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final session = context.watch<SessionProvider>();
    final canAdd = session.can(Perm.createInventory);
    final canRestock = session.can(Perm.updateInventory);
    final canEdit = session.can(Perm.updateInventory);

    Widget content;
    if (inv.loading && inv.batches.isEmpty) {
      content = const LoadingBox();
    } else if (inv.error != null && inv.batches.isEmpty) {
      content = ErrorView(message: inv.error!, onRetry: () => inv.load());
    } else if (inv.batches.isEmpty) {
      content = EmptyState(
        icon: Icons.inventory_2_outlined,
        message: (inv.query.isNotEmpty || inv.size.isNotEmpty || inv.lowOnly)
            ? 'No batches match your filters.'
            : (canAdd
                ? 'No shoe batches yet. Tap "Add batch" to register your first box.'
                : 'No shoe batches yet.'),
      );
    } else {
      content = GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 340,
          // The card is shorter when it has no Restock / Edit buttons.
          mainAxisExtent: (canRestock || canEdit) ? 388 : 326,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: inv.batches.length,
        itemBuilder: (context, i) {
          final b = inv.batches[i];
          return BatchCard(
            batch: b,
            onEdit: canEdit ? () => showBatchForm(context, batch: b) : null,
            onRestock: canRestock ? () => showRestockDialog(context, b) : null,
          );
        },
      );
    }

    return ScreenFrame(
      title: 'Inventory',
      subtitle: 'Shoe batches by box: size, type, colour and stock on hand.',
      onRefresh: () => inv.load(),
      action: canAdd
          ? FilledButton.icon(
              key: const Key('addBatch'),
              onPressed: () => showBatchForm(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add batch'),
            )
          : null,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 300,
              child: TextField(
                controller: _search,
                onChanged: (_) => _onTyping(),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 20),
                  hintText: 'Search code, type or colour',
                ),
              ),
            ),
            SizedBox(
              width: 110,
              child: TextField(
                controller: _size,
                onChanged: (_) => _onTyping(),
                decoration: const InputDecoration(hintText: 'Size'),
              ),
            ),
            FilterChip(
              label: const Text('Low stock only'),
              selected: inv.lowOnly,
              onSelected: (v) => inv.setFilters(lowOnly: v),
              selectedColor: AppColors.alertBg,
              checkmarkColor: AppColors.alert,
              backgroundColor: AppColors.card,
              side: const BorderSide(color: AppColors.line),
            ),
          ],
        ),
        const SizedBox(height: 18),
        content,
      ],
    );
  }
}
