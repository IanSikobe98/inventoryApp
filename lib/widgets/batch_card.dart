import 'package:flutter/material.dart';

import '../models/shoe_batch.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';
import 'shoe_photo.dart';

/// One box of shoes as a hang-tag style card.
class BatchCard extends StatelessWidget {
  const BatchCard({
    super.key,
    required this.batch,
    required this.onEdit,
    required this.onRestock,
  });

  final ShoeBatch batch;
  final VoidCallback onEdit;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ShoePhoto(
                  url: batch.pictureUrl,
                  width: double.infinity,
                  height: 140,
                  iconSize: 52),
              // the little punched hole of a hang tag
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(batch.shoeCode,
                    style: AppText.mono(
                        size: 11, color: AppColors.inkSoft)),
                const SizedBox(height: 2),
                Text(batch.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(size: 17)),
                const SizedBox(height: 2),
                Text('Size ${batch.size}',
                    style: AppText.body(size: 13, color: AppColors.inkSoft)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _price('Cost', batch.costPerShoe)),
                    Expanded(child: _price('Wholesale', batch.wholesalePrice)),
                    Expanded(child: _price('Retail', batch.retailPrice)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('${batch.quantityRemaining} / ${batch.quantityReceived} left',
                        style: AppText.mono(
                            size: 13, weight: FontWeight.w600)),
                    const Spacer(),
                    StockPill(batch: batch),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onRestock,
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10)),
                        child: const Text('Restock'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10)),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _price(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppText.body(size: 9.5, color: AppColors.inkSoft)
                .copyWith(letterSpacing: 0.5)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(formatMoney(value),
              style: AppText.mono(size: 12, weight: FontWeight.w600)),
        ),
      ],
    );
  }
}
