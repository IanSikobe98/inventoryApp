import 'json_helpers.dart';

class TrendPoint {
  const TrendPoint({required this.date, required this.total});

  /// e.g. "Mon 2026-09-28"
  final String date;
  final double total;

  /// "Mon"
  String get label => date.split(' ').first;

  factory TrendPoint.fromJson(Map<String, dynamic> j) => TrendPoint(
        date: j['date'] as String? ?? '',
        total: asDouble(j['total']),
      );
}

class TopSeller {
  const TopSeller({required this.shoeDescription, required this.quantitySold});

  final String shoeDescription;
  final int quantitySold;

  factory TopSeller.fromJson(Map<String, dynamic> j) => TopSeller(
        shoeDescription: j['shoeDescription'] as String? ?? '',
        quantitySold: asInt(j['quantitySold']),
      );
}

class PaymentSlice {
  const PaymentSlice({required this.paymentModeName, required this.total});

  final String paymentModeName;
  final double total;

  factory PaymentSlice.fromJson(Map<String, dynamic> j) => PaymentSlice(
        paymentModeName: j['paymentModeName'] as String? ?? '',
        total: asDouble(j['total']),
      );
}

class DashboardData {
  const DashboardData({
    required this.stockValueRetail,
    required this.stockValueCost,
    required this.pairsInStock,
    required this.batchCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.todayTotalSales,
    required this.todayEstimatedProfit,
    required this.monthTotalSales,
    required this.last7Days,
    required this.topSellers,
    required this.todayPaymentBreakdown,
  });

  final double stockValueRetail;
  final double stockValueCost;
  final int pairsInStock;
  final int batchCount;
  final int lowStockCount;
  final int outOfStockCount;
  final double todayTotalSales;
  final double todayEstimatedProfit;
  final double monthTotalSales;
  final List<TrendPoint> last7Days;
  final List<TopSeller> topSellers;
  final List<PaymentSlice> todayPaymentBreakdown;

  int get needsRestocking => lowStockCount + outOfStockCount;

  factory DashboardData.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) =>
        ((j[key] as List?) ?? const [])
            .map((e) => f(e as Map<String, dynamic>))
            .toList();

    return DashboardData(
      stockValueRetail: asDouble(j['stockValueRetail']),
      stockValueCost: asDouble(j['stockValueCost']),
      pairsInStock: asInt(j['pairsInStock']),
      batchCount: asInt(j['batchCount']),
      lowStockCount: asInt(j['lowStockCount']),
      outOfStockCount: asInt(j['outOfStockCount']),
      todayTotalSales: asDouble(j['todayTotalSales']),
      todayEstimatedProfit: asDouble(j['todayEstimatedProfit']),
      monthTotalSales: asDouble(j['monthTotalSales']),
      last7Days: list('last7Days', TrendPoint.fromJson),
      topSellers: list('topSellers', TopSeller.fromJson),
      todayPaymentBreakdown:
          list('todayPaymentBreakdown', PaymentSlice.fromJson),
    );
  }
}
