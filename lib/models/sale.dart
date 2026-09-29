import 'json_helpers.dart';

class Sale {
  const Sale({
    required this.id,
    required this.shoeBatchId,
    required this.shoeCode,
    required this.shoeDescription,
    required this.actualSellingPrice,
    required this.quantitySold,
    required this.paymentModeId,
    required this.paymentModeName,
    required this.totalAmount,
    this.remarks,
    this.createdAt,
  });

  final int id;
  final int shoeBatchId;
  final String shoeCode;
  final String shoeDescription;
  final double actualSellingPrice;
  final int quantitySold;
  final int paymentModeId;
  final String paymentModeName;
  final double totalAmount;
  final String? remarks;
  final DateTime? createdAt;

  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
        id: asInt(j['id']),
        shoeBatchId: asInt(j['shoeBatchId']),
        shoeCode: j['shoeCode'] as String? ?? '',
        shoeDescription: j['shoeDescription'] as String? ?? '',
        actualSellingPrice: asDouble(j['actualSellingPrice']),
        quantitySold: asInt(j['quantitySold']),
        paymentModeId: asInt(j['paymentModeId']),
        paymentModeName: j['paymentModeName'] as String? ?? '',
        totalAmount: asDouble(j['totalAmount']),
        remarks: j['remarks'] as String?,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );
}
