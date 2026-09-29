import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dashboard_data.dart';
import '../providers/dashboard_provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/sale_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final data = dash.data;

    Widget content;
    if (data == null && dash.loading) {
      content = const LoadingBox();
    } else if (data == null) {
      content = ErrorView(
        message: dash.error ?? 'No data yet.',
        onRetry: () => context.read<DashboardProvider>().load(),
      );
    } else {
      content = _Body(data: data, recent: dash);
    }

    return ScreenFrame(
      title: 'Dashboard',
      subtitle: 'Stock and sales at a glance.',
      onRefresh: () => context.read<DashboardProvider>().load(),
      action: FilledButton.icon(
        onPressed: () => context.read<SessionProvider>().go(AppRoute.sell),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Record a sale'),
      ),
      children: [content],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data, required this.recent});

  final DashboardData data;
  final DashboardProvider recent;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    return Column(
      children: [
        equalGrid([
          StatCard(
            label: 'Stock value (retail)',
            value: formatMoney(data.stockValueRetail),
            sub: 'Cost basis ${formatMoney(data.stockValueCost)}',
          ),
          StatCard(
            label: 'Pairs in stock',
            value: '${data.pairsInStock}',
            sub:
                '${data.batchCount} batch${data.batchCount == 1 ? '' : 'es'} on record',
          ),
          StatCard(
            label: "Today's sales",
            value: formatMoney(data.todayTotalSales),
            sub: 'Est. profit ${formatMoney(data.todayEstimatedProfit)}',
          ),
          StatCard(
            label: 'Needs restocking',
            value: '${data.needsRestocking}',
            sub: '${data.outOfStockCount} out · ${data.lowStockCount} low',
            warn: data.needsRestocking > 0,
          ),
        ], wide ? 4 : 2),
        const SizedBox(height: 14),
        twoColumn(
          SectionCard(
            title: 'Last 7 days',
            tag: 'This month: ${formatMoney(data.monthTotalSales)}',
            child: _TrendBars(points: data.last7Days),
          ),
          SectionCard(
            title: 'Top sellers',
            tag: 'last 30 days',
            child: _TopSellers(sellers: data.topSellers),
          ),
        ),
        const SizedBox(height: 14),
        twoColumn(
          SectionCard(
            title: 'Recent sales',
            child: SaleList(sales: recent.recentSales),
          ),
          SectionCard(
            title: "Today's payments",
            tag: 'by mode',
            child: _PaymentMix(slices: data.todayPaymentBreakdown),
          ),
        ),
      ],
    );
  }
}

class _TrendBars extends StatelessWidget {
  const _TrendBars({required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const EmptyState(
          icon: Icons.bar_chart, message: 'No sales in the last 7 days.');
    }
    final maxTotal = points.map((p) => p.total).fold<double>(0, math.max);
    return SizedBox(
      height: 176,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < points.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(points[i].total > 0 ? compactMoney(points[i].total) : '',
                      style: AppText.mono(
                          size: 10, color: AppColors.inkSoft)),
                  const SizedBox(height: 4),
                  Container(
                    height: maxTotal == 0
                        ? 4
                        : math.max(4, 116 * points[i].total / maxTotal),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      // today (the last bar) is the strong colour
                      color: i == points.length - 1
                          ? AppColors.rust
                          : AppColors.rustSoft,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(points[i].label,
                      style: AppText.body(
                          size: 11, color: AppColors.inkSoft)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TopSellers extends StatelessWidget {
  const _TopSellers({required this.sellers});

  final List<TopSeller> sellers;

  @override
  Widget build(BuildContext context) {
    if (sellers.isEmpty) {
      return Text('No sales in this period yet.',
          style: AppText.body(size: 13, color: AppColors.inkSoft));
    }
    final top = sellers.first.quantitySold;
    return Column(
      children: [
        for (final s in sellers)
          _MeterRow(
            label: s.shoeDescription,
            value: '${s.quantitySold} sold',
            fraction: top == 0 ? 0 : s.quantitySold / top,
          ),
      ],
    );
  }
}

class _PaymentMix extends StatelessWidget {
  const _PaymentMix({required this.slices});

  final List<PaymentSlice> slices;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return Text('No sales today yet.',
          style: AppText.body(size: 13, color: AppColors.inkSoft));
    }
    final top = slices.map((s) => s.total).fold<double>(0, math.max);
    return Column(
      children: [
        for (final s in slices)
          _MeterRow(
            label: s.paymentModeName,
            value: formatMoney(s.total),
            fraction: top == 0 ? 0 : s.total / top,
          ),
      ],
    );
  }
}

class _MeterRow extends StatelessWidget {
  const _MeterRow({
    required this.label,
    required this.value,
    required this.fraction,
  });

  final String label;
  final String value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(size: 13, weight: FontWeight.w500)),
              ),
              const SizedBox(width: 8),
              Text(value,
                  style: AppText.mono(size: 12, color: AppColors.inkSoft)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0).toDouble(),
              minHeight: 7,
              backgroundColor: AppColors.paper2,
              color: AppColors.pine,
            ),
          ),
        ],
      ),
    );
  }
}
