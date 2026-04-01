import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_stats.dart';
import '../../../modules/auth/models/user_model.dart';
import '../../../modules/vendor/models/vendor_model.dart';
import '../../../modules/customer/models/order_model.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<int> _count(
    String table, {
    String? eqField,
    Object? eqValue,
    String? inField,
    List<Object?>? inValues,
  }) async {
    var q = _supabase.from(table).select('id');
    if (eqField != null && eqValue != null) {
      q = q.eq(eqField, eqValue);
    }
    if (inField != null && inValues != null) {
      q = q.inFilter(inField, inValues);
    }
    final res = await q;
    return (res as List).length;
  }

  Future<AdminStats> getDashboardStats() async {
    try {
      // Get total counts
      final usersCount = await _count('users');
      final vendorsCount = await _count('vendors');
      final customersCount = await _count('customers');
      final ordersCount = await _count('orders');
      
      // Get pending orders
      final pendingOrders = await _count('orders', eqField: 'status', eqValue: 'pending');

      // Get completed orders
      final completedOrders = await _count(
        'orders',
        inField: 'status',
        inValues: ['delivered', 'completed'],
      );

      // Get active vendors
      final activeVendors = await _count('vendors', eqField: 'is_active', eqValue: true);

      // Get pending vendors
      final pendingVendors = await _count('vendors', eqField: 'is_verified', eqValue: false);

      // Get revenue data
      final totalRevenue = await _getTotalRevenue();
      final todayRevenue = await _getRevenueForDate(DateTime.now());
      final weeklyRevenue = await _getRevenueForDateRange(
        DateTime.now().subtract(const Duration(days: 7)),
        DateTime.now(),
      );
      final monthlyRevenue = await _getRevenueForDateRange(
        DateTime.now().subtract(const Duration(days: 30)),
        DateTime.now(),
      );

      return AdminStats(
        totalUsers: usersCount,
        totalVendors: vendorsCount,
        totalCustomers: customersCount,
        totalOrders: ordersCount,
        pendingOrders: pendingOrders,
        completedOrders: completedOrders,
        activeVendors: activeVendors,
        pendingVendors: pendingVendors,
        totalRevenue: totalRevenue,
        todayRevenue: todayRevenue,
        weeklyRevenue: weeklyRevenue,
        monthlyRevenue: monthlyRevenue,
      );
    } catch (e) {
      throw Exception('Failed to load dashboard stats: $e');
    }
  }

  Future<double> _getTotalRevenue() async {
    final response = await _supabase
        .from('orders')
        .select('total_amount')
        .inFilter('status', ['delivered', 'completed']);

    double total = 0;
    for (var order in response) {
      total += (order['total_amount'] as num).toDouble();
    }
    return total;
  }

  Future<double> _getRevenueForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _supabase
        .from('orders')
        .select('total_amount')
        .inFilter('status', ['delivered', 'completed'])
        .gte('created_at', startOfDay.toIso8601String())
        .lt('created_at', endOfDay.toIso8601String());

    double total = 0;
    for (var order in response) {
      total += (order['total_amount'] as num).toDouble();
    }
    return total;
  }

  Future<double> _getRevenueForDateRange(DateTime start, DateTime end) async {
    final response = await _supabase
        .from('orders')
        .select('total_amount')
        .inFilter('status', ['delivered', 'completed'])
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String());

    double total = 0;
    for (var order in response) {
      total += (order['total_amount'] as num).toDouble();
    }
    return total;
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((user) => UserModel.fromJson(user))
          .toList();
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  Future<List<VendorModel>> getAllVendors() async {
    try {
      final response = await _supabase
          .from('vendors')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((vendor) => VendorModel.fromJson(vendor))
          .toList();
    } catch (e) {
      throw Exception('Failed to load vendors: $e');
    }
  }

  Future<VendorModel> approveVendor(String vendorId) async {
    try {
      final response = await _supabase
          .from('vendors')
          .update({
            'is_verified': true,
            'verified_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vendorId)
          .select()
          .single();

      return VendorModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to approve vendor: $e');
    }
  }

  Future<void> suspendUser(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({
            'is_active': false,
            'suspended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to suspend user: $e');
    }
  }

  Future<void> activateUser(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({
            'is_active': true,
            'suspended_at': null,
          })
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to activate user: $e');
    }
  }

  Future<List<OrderModel>> getAllOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, customer:customers(*), vendor:vendors(*)')
          .order('created_at', ascending: false);

      return (response as List)
          .map((order) => OrderModel.fromJson(order))
          .toList();
    } catch (e) {
      throw Exception('Failed to load orders: $e');
    }
  }

  Future<OrderModel> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await _supabase
          .from('orders')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select()
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Stream<List<OrderModel>> subscribeToOrders() {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .map((data) {
          return (data as List)
              .map((order) => OrderModel.fromJson(order))
              .toList();
        });
  }
} 
