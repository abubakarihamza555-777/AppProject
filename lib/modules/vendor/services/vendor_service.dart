import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../config/supabase/supabase_client.dart';
import '../../../config/supabase/supabase_tables.dart';
import '../models/vendor_model.dart';
import '../../customer/models/order_model.dart';

class VendorService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Get vendor profile by user ID
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
  
  // Get vendor profile by vendor ID
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
  
  // Get all vendors
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
  
  // Create vendor profile
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
  
  // Update vendor profile
  Future<VendorModel?> updateVendor(String vendorId, Map<String, dynamic> data) async {
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
  
  // Get vendor orders
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
  
  // Get incoming orders (pending status)
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
  
  // Get active deliveries (confirmed, preparing)
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
  
  // Accept order
  Future<bool> acceptOrder(String orderId) async {
    try {
      await _supabase
          .from(SupabaseTables.orders)
          .update({
            'status': 'confirmed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      
      return true;
    } catch (e) {
      print('Accept order error: $e');
      return false;
    }
  }
  
  // Reject order
  Future<bool> rejectOrder(String orderId, {String? reason}) async {
    try {
      await _supabase
          .from(SupabaseTables.orders)
          .update({
            'status': 'cancelled',
            'cancellation_reason': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      
      return true;
    } catch (e) {
      print('Reject order error: $e');
      return false;
    }
  }
  
  // Update delivery status
  Future<bool> updateDeliveryStatus(String orderId, String status) async {
    try {
      await _supabase
          .from(SupabaseTables.orders)
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
            if (status == 'delivered') 'delivery_date': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      
      // If order is delivered, update vendor statistics
      if (status == 'delivered') {
        await _updateVendorStats(orderId);
      }
      
      return true;
    } catch (e) {
      print('Update delivery status error: $e');
      return false;
    }
  }
  
  // Update vendor statistics
  Future<void> _updateVendorStats(String orderId) async {
    try {
      // Get order details
      final order = await _supabase
          .from(SupabaseTables.orders)
          .select('vendor_id, total_price')
          .eq('id', orderId)
          .single();
      
      final vendorId = order['vendor_id'] as String;
      final totalPrice = (order['total_price'] as num).toDouble();
      
      // Update vendor total deliveries
      await _supabase.rpc('increment_vendor_deliveries', params: {
        'vendor_id': vendorId,
      });
      
      // Add to earnings
      await _supabase
          .from(SupabaseTables.earnings)
          .insert({
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
  
  // Update vendor rating
  Future<void> updateVendorRating(String vendorId, double newRating) async {
    try {
      final vendor = await getVendorById(vendorId);
      if (vendor != null) {
        final averageRating = (vendor.rating + newRating) / 2;
        await _supabase
            .from(SupabaseTables.vendors)
            .update({'rating': averageRating})
            .eq('id', vendorId);
      }
    } catch (e) {
      print('Update vendor rating error: $e');
    }
  }
  
  // Get vendor availability status
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
  
  // Toggle vendor availability
  Future<bool> toggleVendorAvailability(String vendorId) async {
    try {
      await _supabase
          .from('vendors')
          .update({'is_active': !_supabase.rpc('get_vendor_status', params: {'vendor_id': vendorId})})
          .eq('id', vendorId);
      return true;
    } catch (e) {
      print('Toggle vendor availability error: $e');
      return false;
    }
  }

  // Request withdrawal
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

  // Get remaining capacity for vendor
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
}
