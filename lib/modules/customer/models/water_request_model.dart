class WaterRequestModel {
  final String id;
  final String customerId;
  final String vendorId;
  final String waterType;
  final int quantity;
  final double pricePerUnit;
  final double totalPrice;
  final String deliveryAddress;
  final String status; // pending, confirmed, preparing, delivered, cancelled
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  WaterRequestModel({
    required this.id,
    required this.customerId,
    required this.vendorId,
    required this.waterType,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
    required this.deliveryAddress,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });
  
  factory WaterRequestModel.fromJson(Map<String, dynamic> json) {
    return WaterRequestModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      vendorId: json['vendor_id'] as String,
      waterType: json['water_type'] as String,
      quantity: json['quantity'] as int,
      pricePerUnit: (json['price_per_unit'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      deliveryAddress: json['delivery_address'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'vendor_id': vendorId,
      'water_type': waterType,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'total_price': totalPrice,
      'delivery_address': deliveryAddress,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
