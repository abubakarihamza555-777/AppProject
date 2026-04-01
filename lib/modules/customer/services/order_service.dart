import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase/supabase_client.dart';
import '../../../config/supabase/supabase_tables.dart';
import '../models/order_model.dart';

class OrderService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Create new order
  Future<OrderModel?> createOrder({
    required String customerId,
    required String vendorId,
    required String waterType,
    required int quantity,
    required double totalPrice,
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    try {
      final orderData = {
        'customer_id': customerId,
        'vendor_id': vendorId,
        'water_type': waterType,
        'quantity': quantity,
        'total_price': totalPrice,
        'delivery_address': deliveryAddress,
        'payment_method': paymentMethod,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };
      
      final response = await _supabase
          .from(SupabaseTables.orders)
          .insert(orderData)
          .select()
          .single();
      
      return OrderModel.fromJson(response);
    } catch (e) {
      print('Create order error: $e');
      rethrow;
    }
  }
  
  // Get customer orders
  Future<List<OrderModel>> getCustomerOrders(String customerId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.orders)
          .select('*, vendors(*)')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      
      return response.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      print('Get orders error: $e');
      return [];
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
  
  // Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.orders)
          .select('*, vendors(*), customers(*)')
          .eq('id', orderId)
          .single();
      
      return OrderModel.fromJson(response);
    } catch (e) {
      print('Get order by ID error: $e');
      return null;
    }
  }
  
  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _supabase
          .from(SupabaseTables.orders)
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      print('Update order status error: $e');
      rethrow;
    }
  }
  
  // Track order in realtime
  Stream<OrderModel> trackOrder(String orderId) {
    return _supabase
        .from(SupabaseTables.orders)
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((event) => OrderModel.fromJson(event.first));
  }
} 
