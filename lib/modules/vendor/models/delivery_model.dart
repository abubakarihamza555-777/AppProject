class DeliveryModel {
  final String id;
  final String orderId;
  final String vendorId;
  final String driverId;
  final String status; // assigned, picked_up, in_transit, delivered
  final DateTime assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final String? trackingNumber;
  
  DeliveryModel({
    required this.id,
    required this.orderId,
    required this.vendorId,
    required this.driverId,
    required this.status,
    required this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.trackingNumber,
  });
  
  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      vendorId: json['vendor_id'] as String,
      driverId: json['driver_id'] as String,
      status: json['status'] as String,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      pickedUpAt: json['picked_up_at'] != null 
          ? DateTime.parse(json['picked_up_at'] as String) 
          : null,
      deliveredAt: json['delivered_at'] != null 
          ? DateTime.parse(json['delivered_at'] as String) 
          : null,
      trackingNumber: json['tracking_number'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'vendor_id': vendorId,
      'driver_id': driverId,
      'status': status,
      'assigned_at': assignedAt.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'tracking_number': trackingNumber,
    };
  }
} 
