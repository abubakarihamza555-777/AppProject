class ReportModel {
  final String id;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> data;
  final String generatedBy;
  final DateTime generatedAt;
  final String fileUrl;

  ReportModel({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.data,
    required this.generatedBy,
    required this.generatedAt,
    required this.fileUrl,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      type: json['type'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      data: json['data'] as Map<String, dynamic>,
      generatedBy: json['generated_by'] as String,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      fileUrl: json['file_url'] as String,
    );
  }
}

class OrderReport {
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final Map<String, int> ordersByStatus;
  final Map<String, double> revenueByVendor;
  final List<Map<String, dynamic>> dailyOrders;

  OrderReport({
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.ordersByStatus,
    required this.revenueByVendor,
    required this.dailyOrders,
  });
}

class UserReport {
  final int totalUsers;
  final int newUsers;
  final int activeUsers;
  final int inactiveUsers;
  final Map<String, int> usersByRole;
  final Map<String, int> usersByRegion;
  final List<Map<String, dynamic>> userGrowth;

  UserReport({
    required this.totalUsers,
    required this.newUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.usersByRole,
    required this.usersByRegion,
    required this.userGrowth,
  });
} 
