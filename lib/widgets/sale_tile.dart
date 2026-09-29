import 'package:flutter/material.dart';

import '../models/sale.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';

/// One sale, as a two-line row. Used on the dashboard and in the sales log.
class SaleTile extends StatelessWidget {
  const SaleTile({super.key, required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final remarks = sale.remarks;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sale.shoeDescription,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(weight: FontWeight.w600)),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Pill(label: sale.paymentModeName),
                    Text(
                        '${sale.quantitySold} × ${formatMoney(sale.actualSellingPrice)}',
                        style: AppText.mono(
                            size: 12, color: AppColors.inkSoft)),
                    Text(formatDateTime(sale.createdAt),
                        style: AppText.body(
                            size: 12, color: AppColors.inkSoft)),
                  ],
                ),
                if (remarks != null && remarks.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(remarks,
                      style: AppText.body(size: 12, color: AppColors.inkSoft)
                          .copyWith(fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(formatMoney(sale.totalAmount),
              style: AppText.mono(size: 14, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// A list of [SaleTile]s with dividers between them.
class SaleList extends StatelessWidget {
  const SaleList({super.key, required this.sales});

  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return const EmptyState(
          icon: Icons.receipt_long_outlined, message: 'No sales to show yet.');
    }
    return Column(
      children: [
        for (var i = 0; i < sales.length; i++) ...[
          if (i > 0) const Divider(),
          SaleTile(sale: sales[i]),
        ],
      ],
    );
  }
}
