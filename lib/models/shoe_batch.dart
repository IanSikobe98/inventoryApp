import 'json_helpers.dart';

class ShoeBatch {
  const ShoeBatch({
    required this.id,
    required this.shoeCode,
    required this.size,
    required this.type,
    required this.colour,
    this.pictureUrl,
    required this.quantityReceived,
    required this.quantityRemaining,
    required this.costPerShoe,
    required this.wholesalePrice,
    required this.retailPrice,
    required this.lowStock,
    required this.outOfStock,
  });

  final int id;
  final String shoeCode;
  final String size;
  final String type;
  final String colour;
  final String? pictureUrl;
  final int quantityReceived;
  final int quantityRemaining;
  final double costPerShoe;
  final double wholesalePrice;
  final double retailPrice;
  final bool lowStock;
  final bool outOfStock;

  String get title => '$type · $colour';

  factory ShoeBatch.fromJson(Map<String, dynamic> j) {
    final remaining = asInt(j['quantityRemaining']);
    return ShoeBatch(
      id: asInt(j['id']),
      shoeCode: j['shoeCode'] as String? ?? '',
      size: j['size'] as String? ?? '',
      type: j['type'] as String? ?? '',
      colour: j['colour'] as String? ?? '',
      pictureUrl: j['pictureUrl'] as String?,
      quantityReceived: asInt(j['quantityReceived']),
      quantityRemaining: remaining,
      costPerShoe: asDouble(j['costPerShoe']),
      wholesalePrice: asDouble(j['wholesalePrice']),
      retailPrice: asDouble(j['retailPrice']),
      lowStock: j['lowStock'] as bool? ?? (remaining > 0 && remaining <= 5),
      outOfStock: j['outOfStock'] as bool? ?? remaining <= 0,
    );
  }
}
