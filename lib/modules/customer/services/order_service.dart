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
      final orderId = _generateOrderId();
      final now = DateTime.now().toIso8601String();
      
      final orderData = {
        'id': orderId,
        'customer_id': customerId,
        'vendor_id': vendorId,
        'water_type': waterType,
        'quantity': quantity,
        'total_price': totalPrice,
        'delivery_address': deliveryAddress,
        'payment_method': paymentMethod,
        'status': 'placed',
        'created_at': now,
        'updated_at': now,
        'tracking_number': 'TRK${DateTime.now().millisecondsSinceEpoch}',
      };
      
      final response = await _supabase
          .from(SupabaseTables.orders)
          .insert(orderData)
          .select()
          .single();
      
      // Create notification for vendor
      await _createVendorNotification(vendorId, orderId);
      
      return OrderModel.fromJson(response);
    } catch (e) {
      print('Create order error: $e');
      rethrow;
    }
  }
  
  // Generate unique order ID
  String _generateOrderId() {
    const prefix = 'ORD';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (DateTime.now().microsecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return '$prefix${timestamp.substring(timestamp.length - 8)}$random';
  }
  
  // Create vendor notification
  Future<void> _createVendorNotification(String vendorId, String orderId) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': vendorId,
        'title': 'New Order Received',
        'message': 'You have a new water delivery order #$orderId',
        'type': 'order',
        'data': {'order_id': orderId},
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Create notification error: $e');
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
          .maybeSingle();
      
      if (response == null) return null;
      return OrderModel.fromJson(response);
    } catch (e) {
      print('Get order by ID error: $e');
      return null;
    }
  }
  
  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _supabase
          .from(SupabaseTables.orders)
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
            if (status == 'delivered') 'delivery_date': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      
      return true;
    } catch (e) {
      print('Update order status error: $e');
      return false;
    }
  }
  
  // Cancel order
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
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
      print('Cancel order error: $e');
      return false;
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
  
  // Rate vendor after delivery
  Future<bool> rateVendor(String orderId, double rating, String? review) async {
    try {
      // Get order to find vendor
      final order = await getOrderById(orderId);
      if (order == null) return false;
      
      // Update vendor rating
      final vendor = await _supabase
          .from('vendors')
          .select('rating, total_ratings')
          .eq('id', order.vendorId)
          .single();
      
      final currentRating = (vendor['rating'] as num?)?.toDouble() ?? 0.0;
      final totalRatings = (vendor['total_ratings'] as int?) ?? 0;
      final newRating = ((currentRating * totalRatings) + rating) / (totalRatings + 1);
      
      await _supabase
          .from('vendors')
          .update({
            'rating': newRating,
            'total_ratings': totalRatings + 1,
          })
          .eq('id', order.vendorId);
      
      // Add review
      if (review != null && review.isNotEmpty) {
        await _supabase.from('reviews').insert({
          'order_id': orderId,
          'vendor_id': order.vendorId,
          'customer_id': order.customerId,
          'rating': rating,
          'review': review,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      return true;
    } catch (e) {
      print('Rate vendor error: $e');
      return false;
    }
  }
} 
