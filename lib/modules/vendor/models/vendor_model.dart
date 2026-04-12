// lib/modules/vendor/models/vendor_model.dart
class VendorModel {
  final String id;
  final String userId;
  final String businessName;
  final String businessPhone;
  final String businessAddress;
  final String? businessLicense;
  final String? profileImage;
  final double rating;
  final int totalDeliveries;
  final bool isActive;
  final bool isVerified;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<int> serviceAreas;
  final String? vehicleType;
  final int? maxLitersPerTrip;
  final int? defaultDeliveryFeePer10l;
  final bool canNegotiateLargeOrders;

  VendorModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.businessPhone,
    required this.businessAddress,
    this.businessLicense,
    this.profileImage,
    required this.rating,
    required this.totalDeliveries,
    required this.isActive,
    required this.isVerified,
    this.verifiedAt,
    required this.createdAt,
    this.updatedAt,
    required this.serviceAreas,
    this.vehicleType,
    this.maxLitersPerTrip,
    this.defaultDeliveryFeePer10l,
    required this.canNegotiateLargeOrders,
  });

  /// Safely converts service_areas from database to List<int>
  /// Handles: List<int>, List<dynamic>, List<String>, null, and PostgreSQL array format
  static List<int> _parseServiceAreas(dynamic areas) {
    if (areas == null) return [];
    
    // If it's already List<int>
    if (areas is List<int>) return areas;
    
    // If it's List<dynamic>
    if (areas is List<dynamic>) {
      try {
        return areas.map((e) {
          // Handle if element is String that can be parsed to int
          if (e is String) {
            return int.tryParse(e) ?? 0;
          }
          // Handle if element is int
          if (e is int) {
            return e;
          }
          // Handle if element is double
          if (e is double) {
            return e.toInt();
          }
          return 0;
        }).toList();
      } catch (e) {
        print('Error parsing List<dynamic> service_areas: $e');
        return [];
      }
    }
    
    // If it's a String (PostgreSQL array format like "{1,2,3}")
    if (areas is String) {
      try {
        // Remove curly braces and split by comma
        final cleaned = areas.replaceAll('{', '').replaceAll('}', '');
        if (cleaned.isEmpty) return [];
        return cleaned.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
      } catch (e) {
        print('Error parsing String service_areas: $e');
        return [];
      }
    }
    
    return [];
  }

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessName: json['business_name'] as String,
      businessPhone: json['business_phone'] as String,
      businessAddress: json['business_address'] as String,
      businessLicense: json['business_license'] as String?,
      profileImage: json['profile_image'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalDeliveries: json['total_deliveries'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      verifiedAt: json['verified_at'] != null 
          ? DateTime.parse(json['verified_at'] as String) 
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      serviceAreas: _parseServiceAreas(json['service_areas']),
      vehicleType: json['vehicle_type'] as String?,
      maxLitersPerTrip: json['max_liters_per_trip'] as int?,
      defaultDeliveryFeePer10l: json['default_delivery_fee_per_10l'] as int?,
      canNegotiateLargeOrders: json['can_negotiate_large_orders'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_name': businessName,
      'business_phone': businessPhone,
      'business_address': businessAddress,
      'business_license': businessLicense,
      'profile_image': profileImage,
      'rating': rating,
      'total_deliveries': totalDeliveries,
      'is_active': isActive,
      'is_verified': isVerified,
      'verified_at': verifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'service_areas': serviceAreas,
      'vehicle_type': vehicleType,
      'max_liters_per_trip': maxLitersPerTrip,
      'default_delivery_fee_per_10l': defaultDeliveryFeePer10l,
      'can_negotiate_large_orders': canNegotiateLargeOrders,
    };
  }

  VendorModel copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? businessPhone,
    String? businessAddress,
    String? businessLicense,
    String? profileImage,
    double? rating,
    int? totalDeliveries,
    bool? isActive,
    bool? isVerified,
    DateTime? verifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<int>? serviceAreas,
    String? vehicleType,
    int? maxLitersPerTrip,
    int? defaultDeliveryFeePer10l,
    bool? canNegotiateLargeOrders,
  }) {
    return VendorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      businessPhone: businessPhone ?? this.businessPhone,
      businessAddress: businessAddress ?? this.businessAddress,
      businessLicense: businessLicense ?? this.businessLicense,
      profileImage: profileImage ?? this.profileImage,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      vehicleType: vehicleType ?? this.vehicleType,
      maxLitersPerTrip: maxLitersPerTrip ?? this.maxLitersPerTrip,
      defaultDeliveryFeePer10l: defaultDeliveryFeePer10l ?? this.defaultDeliveryFeePer10l,
      canNegotiateLargeOrders: canNegotiateLargeOrders ?? this.canNegotiateLargeOrders,
    );
  }
}