import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase/supabase_client.dart';
import '../models/delivery_model.dart';

class DeliveryService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Assign delivery to driver
  Future<bool> assignDelivery({
    required String orderId,
    required String vendorId,
    required String driverId,
  }) async {
    try {
      final deliveryData = {
        'order_id': orderId,
        'vendor_id': vendorId,
        'driver_id': driverId,
        'status': 'assigned',
        'assigned_at': DateTime.now().toIso8601String(),
        'tracking_number': 'TRK${DateTime.now().millisecondsSinceEpoch}',
      };
      
      await _supabase
          .from('deliveries')
          .insert(deliveryData);
      
      return true;
    } catch (e) {
      print('Assign delivery error: $e');
      return false;
    }
  }
  
  // Update delivery status
  Future<bool> updateDeliveryStatus(String deliveryId, String status) async {
    try {
      final updateData = {
        'status': status,
        if (status == 'picked_up') 'picked_up_at': DateTime.now().toIso8601String(),
        if (status == 'delivered') 'delivered_at': DateTime.now().toIso8601String(),
      };
      
      await _supabase
          .from('deliveries')
          .update(updateData)
          .eq('id', deliveryId);
      
      return true;
    } catch (e) {
      print('Update delivery status error: $e');
      return false;
    }
  }
  
  // Get delivery by order ID
  Future<DeliveryModel?> getDeliveryByOrderId(String orderId) async {
    try {
      final response = await _supabase
          .from('deliveries')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();
      
      if (response == null) return null;
      return DeliveryModel.fromJson(response);
    } catch (e) {
      print('Get delivery by order ID error: $e');
      return null;
    }
  }
  
  // Track delivery in realtime
  Stream<DeliveryModel> trackDelivery(String deliveryId) {
    return _supabase
        .from('deliveries')
        .stream(primaryKey: ['id'])
        .eq('id', deliveryId)
        .map((event) => DeliveryModel.fromJson(event.first));
  }
} 
