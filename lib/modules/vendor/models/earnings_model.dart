class EarningsModel {
  final String id;
  final String vendorId;
  final String orderId;
  final double amount;
  final String status; // pending, paid, withdrawn
  final DateTime createdAt;
  final DateTime? paidAt;
  
  EarningsModel({
    required this.id,
    required this.vendorId,
    required this.orderId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });
  
  factory EarningsModel.fromJson(Map<String, dynamic> json) {
    return EarningsModel(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      orderId: json['order_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      paidAt: json['paid_at'] != null 
          ? DateTime.parse(json['paid_at'] as String) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'order_id': orderId,
      'amount': amount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
    };
  }
} 
