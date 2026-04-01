class PaymentModel {
  final String id;
  final String orderId;
  final String customerId;
  final String vendorId;
  final double amount;
  final String method; // cash, mobile_money, card
  final String status; // pending, completed, failed, refunded
  final String? transactionId;
  final DateTime createdAt;
  final DateTime? completedAt;
  
  PaymentModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.vendorId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    required this.createdAt,
    this.completedAt,
  });
  
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      customerId: json['customer_id'] as String,
      vendorId: json['vendor_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: json['method'] as String,
      status: json['status'] as String,
      transactionId: json['transaction_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'customer_id': customerId,
      'vendor_id': vendorId,
      'amount': amount,
      'method': method,
      'status': status,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
} 
