import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../config/supabase/supabase_client.dart';
import '../../../config/supabase/supabase_tables.dart';
import '../models/vendor_model.dart';
import '../../customer/models/order_model.dart';

class VendorService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // =========================
  // VENDOR MANAGEMENT
  // =========================

  Future<VendorModel?> getVendorByUserId(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.vendors)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return VendorModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get vendor by user ID error: $e');
      }
      return null;
    }
  }

  Future<VendorModel?> getVendorById(String vendorId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.vendors)
          .select()
          .eq('id', vendorId)
          .single();

      return VendorModel.fromJson(response);
    } catch (e) {
      print('Get vendor by ID error: $e');
      return null;
    }
  }

  Future<List<VendorModel>> getAllVendors() async {
    try {
      final response = await _supabase
          .from(SupabaseTables.vendors)
          .select()
          .eq('is_active', true)
          .order('rating', ascending: false);

      return response.map((json) => VendorModel.fromJson(json)).toList();
    } catch (e) {
      print('Get all vendors error: $e');
      return [];
    }
  }

  Future<VendorModel?> createVendor({
    required String userId,
    required String businessName,
    required String businessPhone,
    required String businessAddress,
    String? businessLicense,
    String? profileImage,
  }) async {
    try {
      final vendorData = {
        'user_id': userId,
        'business_name': businessName,
        'business_phone': businessPhone,
        'business_address': businessAddress,
        'business_license': businessLicense,
        'profile_image': profileImage,
        'rating': 0.0,
        'total_deliveries': 0,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(SupabaseTables.vendors)
          .insert(vendorData)
          .select()
          .single();

      return VendorModel.fromJson(response);
    } catch (e) {
      print('Create vendor error: $e');
      return null;
    }
  }

  Future<VendorModel?> updateVendor(
      String vendorId, Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.vendors)
          .update(data)
          .eq('id', vendorId)
          .select()
          .single();

      return VendorModel.fromJson(response);
    } catch (e) {
      print('Update vendor error: $e');
      return null;
    }
  }

  // =========================
  // ORDERS
  // =========================

  Future<List<OrderModel>> getVendorOrders(String vendorId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.orders)
          .select('*, customers(*)')
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false);

      return response.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      print('Get vendor orders error: $e');
      return [];
    }
  }

  Future<List<OrderModel>> getIncomingOrders(String vendorId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.orders)
          .select('*, customers(*)')
          .eq('vendor_id', vendorId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return response.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      print('Get incoming orders error: $e');
      return [];
    }
  }

  Future<List<OrderModel>> getActiveDeliveries(String vendorId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.orders)
          .select('*, customers(*)')
          .eq('vendor_id', vendorId)
          .inFilter('status', ['confirmed', 'preparing'])
          .order('created_at', ascending: false);

      return response.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      print('Get active deliveries error: $e');
      return [];
    }
  }

  Future<bool> acceptOrder(String orderId) async {
    try {
      await _supabase.from(SupabaseTables.orders).update({
        'status': 'confirmed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      return true;
    } catch (e) {
      print('Accept order error: $e');
      return false;
    }
  }

  Future<bool> rejectOrder(String orderId, {String? reason}) async {
    try {
      await _supabase.from(SupabaseTables.orders).update({
        'status': 'cancelled',
        'cancellation_reason': reason,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      return true;
    } catch (e) {
      print('Reject order error: $e');
      return false;
    }
  }

  Future<bool> updateDeliveryStatus(String orderId, String status) async {
    try {
      await _supabase.from(SupabaseTables.orders).update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        if (status == 'delivered')
          'delivery_date': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (status == 'delivered') {
        await _updateVendorStats(orderId);
      }

      return true;
    } catch (e) {
      print('Update delivery status error: $e');
      return false;
    }
  }

  Future<void> _updateVendorStats(String orderId) async {
    try {
      final order = await _supabase
          .from(SupabaseTables.orders)
          .select('vendor_id, total_price')
          .eq('id', orderId)
          .single();

      final vendorId = order['vendor_id'];
      final totalPrice = (order['total_price'] as num).toDouble();

      await _supabase.rpc('increment_vendor_deliveries', params: {
        'vendor_id': vendorId,
      });

      await _supabase.from(SupabaseTables.earnings).insert({
        'vendor_id': vendorId,
        'order_id': orderId,
        'amount': totalPrice,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Update vendor stats error: $e');
    }
  }

  // =========================
  // CAPACITY & STATUS
  // =========================

  Future<bool> getVendorAvailability(String vendorId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.vendors)
          .select('is_active')
          .eq('id', vendorId)
          .single();

      return response['is_active'] as bool;
    } catch (e) {
      print('Get vendor availability error: $e');
      return false;
    }
  }

  Future<bool> toggleVendorAvailability(String vendorId) async {
    try {
      final currentStatus = await getVendorAvailability(vendorId);

      await _supabase
          .from(SupabaseTables.vendors)
          .update({'is_active': !currentStatus})
          .eq('id', vendorId);

      return true;
    } catch (e) {
      print('Toggle vendor availability error: $e');
      return false;
    }
  }

  Future<int> getRemainingCapacity(String vendorId) async {
    try {
      final vendor = await getVendorById(vendorId);
      if (vendor == null) return 0;

      final today = DateTime.now();
      final todayStr = today.toIso8601String().substring(0, 10);

      final response = await _supabase
          .from('orders')
          .select('quantity')
          .eq('vendor_id', vendorId)
          .eq('status', 'delivered')
          .gte('created_at', todayStr);

      int totalDelivered = 0;
      for (var order in response) {
        totalDelivered += order['quantity'] as int;
      }

      return (vendor.maxLitersPerTrip ?? 0) - totalDelivered;
    } catch (e) {
      print('Get remaining capacity error: $e');
      return 0;
    }
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final response = await SupabaseConfig.client
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      print('Get order by ID error: $e');
      return null;
    }
  }

  // =========================
  // EARNINGS
  // =========================

  Future<double> getTodayEarnings(String vendorId) async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));

      final response = await _supabase
          .from('earnings')
          .select('amount')
          .eq('vendor_id', vendorId)
          .eq('status', 'paid')
          .gte('created_at', start.toIso8601String())
          .lt('created_at', end.toIso8601String());

      double total = 0;
      for (var item in response) {
        total += (item['amount'] as num).toDouble();
      }
      return total;
    } catch (e) {
      print('Get today earnings error: $e');
      return 0;
    }
  }

  Future<double> getTotalEarnings(String vendorId) async {
    try {
      final response = await _supabase
          .from('earnings')
          .select('amount')
          .eq('vendor_id', vendorId)
          .eq('status', 'paid');

      double total = 0;
      for (var item in response) {
        total += (item['amount'] as num).toDouble();
      }
      return total;
    } catch (e) {
      print('Get total earnings error: $e');
      return 0;
    }
  }

  Future<double> getPendingEarnings(String vendorId) async {
    try {
      final response = await _supabase
          .from('earnings')
          .select('amount')
          .eq('vendor_id', vendorId)
          .eq('status', 'pending');

      double total = 0;
      for (var item in response) {
        total += (item['amount'] as num).toDouble();
      }
      return total;
    } catch (e) {
      print('Get pending earnings error: $e');
      return 0;
    }
  }

  // =========================
  // NEW ADDED METHODS
  // =========================

  Future<double> getWithdrawnEarnings(String vendorId) async {
    try {
      final response = await _supabase
          .from('withdrawals')
          .select('amount')
          .eq('vendor_id', vendorId)
          .eq('status', 'completed');

      double total = 0;
      for (var item in response) {
        total += (item['amount'] as num).toDouble();
      }
      return total;
    } catch (e) {
      print('Get withdrawn earnings error: $e');
      return 0;
    }
  }

  Future<Map<String, double>> getEarningsByPeriod(
      String vendorId, String period) async {
    try {
      final response = await _supabase
          .from('earnings')
          .select('amount, created_at')
          .eq('vendor_id', vendorId)
          .eq('status', 'paid');

      final Map<String, double> result = {};

      for (var item in response) {
        final date = DateTime.parse(item['created_at']);
        final amount = (item['amount'] as num).toDouble();

        String key;

        switch (period) {
          case 'weekly':
            key = 'Week ${_getWeekNumber(date)}';
            break;
          case 'monthly':
            key = _getMonthName(date.month);
            break;
          case 'yearly':
            key = date.year.toString();
            break;
          default:
            key = 'Week ${_getWeekNumber(date)}';
        }

        result[key] = (result[key] ?? 0) + amount;
      }

      return result;
    } catch (e) {
      print('Get earnings by period error: $e');
      return {};
    }
  }

  int _getWeekNumber(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    final days = date.difference(firstDay).inDays;
    return ((days + firstDay.weekday) / 7).ceil();
  }

  String _getMonthName(int month) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return months[month - 1];
  }

  // =========================
  // WITHDRAWAL & CAPACITY
  // =========================

  Future<bool> requestWithdrawal(String vendorId, double amount) async {
    try {
      await _supabase.from('withdrawals').insert({
        'vendor_id': vendorId,
        'amount': amount,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Request withdrawal error: $e');
      return false;
    }
  }
}