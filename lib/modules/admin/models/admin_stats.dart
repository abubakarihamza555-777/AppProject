class AdminStats {
  final int totalUsers;
  final int totalVendors;
  final int totalCustomers;
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final int activeVendors;
  final int pendingVendors;
  final double totalRevenue;
  final double todayRevenue;
  final double weeklyRevenue;
  final double monthlyRevenue;
  final Map<String, dynamic>? orderTrends;
  final Map<String, dynamic>? revenueTrends;

  AdminStats({
    required this.totalUsers,
    required this.totalVendors,
    required this.totalCustomers,
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.activeVendors,
    required this.pendingVendors,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.weeklyRevenue,
    required this.monthlyRevenue,
    this.orderTrends,
    this.revenueTrends,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['total_users'] as int? ?? 0,
      totalVendors: json['total_vendors'] as int? ?? 0,
      totalCustomers: json['total_customers'] as int? ?? 0,
      totalOrders: json['total_orders'] as int? ?? 0,
      pendingOrders: json['pending_orders'] as int? ?? 0,
      completedOrders: json['completed_orders'] as int? ?? 0,
      activeVendors: json['active_vendors'] as int? ?? 0,
      pendingVendors: json['pending_vendors'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      todayRevenue: (json['today_revenue'] as num?)?.toDouble() ?? 0.0,
      weeklyRevenue: (json['weekly_revenue'] as num?)?.toDouble() ?? 0.0,
      monthlyRevenue: (json['monthly_revenue'] as num?)?.toDouble() ?? 0.0,
      orderTrends: json['order_trends'],
      revenueTrends: json['revenue_trends'],
    );
  }
}

class VendorApproval {
  final String id;
  final String businessName;
  final String ownerName;
  final String email;
  final String phoneNumber;
  final String businessAddress;
  final String? businessLicense;
  final String? taxId;
  final DateTime submittedAt;
  final String status;

  VendorApproval({
    required this.id,
    required this.businessName,
    required this.ownerName,
    required this.email,
    required this.phoneNumber,
    required this.businessAddress,
    this.businessLicense,
    this.taxId,
    required this.submittedAt,
    required this.status,
  });

  factory VendorApproval.fromJson(Map<String, dynamic> json) {
    return VendorApproval(
      id: json['id'] as String,
      businessName: json['business_name'] as String,
      ownerName: json['owner_name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String,
      businessAddress: json['business_address'] as String,
      businessLicense: json['business_license'] as String?,
      taxId: json['tax_id'] as String?,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      status: json['status'] as String,
    );
  }
}
