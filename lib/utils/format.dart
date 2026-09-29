import 'package:intl/intl.dart';

final NumberFormat _grouped = NumberFormat.decimalPattern('en_US');

/// 3200 -> "KSh 3,200"
String formatMoney(num? v) => 'KSh ${_grouped.format((v ?? 0).round())}';

/// 12500 -> "12.5k", 2400000 -> "2.4M" (for chart labels)
String compactMoney(num v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.round().toString();
}

/// 3200.0 -> "3200", 3200.5 -> "3200.50" (for prefilling number fields)
String plainNumber(num v) {
  final d = v.toDouble();
  return d == d.roundToDouble() ? d.round().toString() : d.toStringAsFixed(2);
}

String formatDateTime(DateTime? d) {
  if (d == null) return '—';
  return DateFormat('dd MMM · HH:mm').format(d);
}

String formatShortDate(DateTime d) => DateFormat('dd MMM').format(d);

/// 2026-09-05 (the format the API expects for ?from= and ?to=)
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
