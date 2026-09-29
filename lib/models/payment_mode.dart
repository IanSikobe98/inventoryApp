import 'json_helpers.dart';

class PaymentMode {
  const PaymentMode({required this.id, required this.name, required this.active});

  final int id;
  final String name;
  final bool active;

  factory PaymentMode.fromJson(Map<String, dynamic> j) => PaymentMode(
        id: asInt(j['id']),
        name: j['name'] as String? ?? '',
        active: j['active'] as bool? ?? true,
      );
}
