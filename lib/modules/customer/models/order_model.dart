class OrderModel {
  final String id;
  final String customerId;
  final String vendorId;
  final String waterType;
  final int quantity;
  final double totalPrice;
  final String deliveryAddress;
  final String paymentMethod;
  final String status;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final String? trackingNumber;
  final Map<String, dynamic>? vendorDetails;
  final Map<String, dynamic>? customerDetails;
  final String? serviceType; // 'small' or 'large' car tank
  
  OrderModel({
    required this.id,
    required this.customerId,
    required this.vendorId,
    required this.waterType,
    required this.quantity,
    required this.totalPrice,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.status,
    required this.orderDate,
    this.deliveryDate,
    this.trackingNumber,
    this.vendorDetails,
    this.customerDetails,
    this.serviceType,
  });
  
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      vendorId: json['vendor_id'] as String,
      waterType: json['water_type'] as String,
      quantity: json['quantity'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
      deliveryAddress: json['delivery_address'] as String,
      paymentMethod: json['payment_method'] as String,
      status: json['status'] as String,
      orderDate: DateTime.parse(json['created_at'] as String),
      deliveryDate: json['delivery_date'] != null 
          ? DateTime.parse(json['delivery_date'] as String) 
          : null,
      trackingNumber: json['tracking_number'] as String?,
      vendorDetails: json['vendors'] as Map<String, dynamic>?,
      customerDetails: json['customers'] as Map<String, dynamic>?,
      serviceType: json['service_type'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'vendor_id': vendorId,
      'water_type': waterType,
      'quantity': quantity,
      'total_price': totalPrice,
      'delivery_address': deliveryAddress,
      'payment_method': paymentMethod,
      'status': status,
      'created_at': orderDate.toIso8601String(),
      'delivery_date': deliveryDate?.toIso8601String(),
      'tracking_number': trackingNumber,
      'service_type': serviceType,
    };
  }
  
  String getStatusText(String languageCode) {
    final statusMap = {
      'placed': languageCode == 'sw' ? 'Imewekwa' : 'Placed',
      'vendor_assigned': languageCode == 'sw' ? 'Mtoa huduma amechaguliwa' : 'Vendor assigned',
      'accepted': languageCode == 'sw' ? 'Imekubaliwa' : 'Accepted',
      'preparing': languageCode == 'sw' ? 'Inaandaliwa' : 'Preparing',
      'out_for_delivery': languageCode == 'sw' ? 'Imetoka' : 'Out for delivery',
      'delivered': languageCode == 'sw' ? 'Imewasilishwa' : 'Delivered',
      'cancelled': languageCode == 'sw' ? 'Imefutwa' : 'Cancelled',
      'completed': languageCode == 'sw' ? 'Imekamilika' : 'Completed',
    };
    return statusMap[status] ?? status;
  }

  // Compatibility helpers for admin/report screens
  DateTime get createdAt => orderDate;
  double get totalAmount => totalPrice;
  List<Map<String, dynamic>> get items {
    final unit = quantity <= 0 ? totalPrice : (totalPrice / quantity);
    return [
      {
        'name': waterType,
        'quantity': quantity,
        'price': unit,
      }
    ];
  }
} 
