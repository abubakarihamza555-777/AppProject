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
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? maxLitersPerTrip;
  final String? vehicleType;
  
  VendorModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.businessPhone,
    required this.businessAddress,
    this.businessLicense,
    this.profileImage,
    this.rating = 0.0,
    this.totalDeliveries = 0,
    this.isActive = true,
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
    this.maxLitersPerTrip,
    this.vehicleType,
  });
  
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
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      maxLitersPerTrip: json['max_liters_per_trip'] as int?,
      vehicleType: json['vehicle_type'] as String?,
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'max_liters_per_trip': maxLitersPerTrip,
      'vehicle_type': vehicleType,
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
    DateTime? createdAt,
    DateTime? updatedAt,
    int? maxLitersPerTrip,
    String? vehicleType,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      maxLitersPerTrip: maxLitersPerTrip ?? this.maxLitersPerTrip,
      vehicleType: vehicleType ?? this.vehicleType,
    );
  }
}