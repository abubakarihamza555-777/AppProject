import 'package:flutter/material.dart';
import '../../../config/supabase/supabase_client.dart';
import '../../../config/supabase/supabase_tables.dart';
import '../models/payment_model.dart';
import '../controllers/home_controller.dart';

class PaymentService {
  final supabase = SupabaseConfig.client;
  static const double adminCommissionPercentage = 0.10; // 10% admin commission
  
  // Process payment with automatic splitting
  Future<Map<String, dynamic>> processPaymentWithSplitting({
    required String orderId,
    required String customerId,
    required String vendorId,
    required int liters,
    required String paymentMethod,
    String? mobileNumber,
  }) async {
    try {
      final controller = HomeController();
      
      // Calculate amounts
      double totalPrice = controller.calculateTotalPrice(liters);
      double adminCommission = controller.getAdminCommission(liters);
      double vendorEarnings = controller.getVendorEarnings(liters);
      
      // Create payment record
      final paymentData = {
        'order_id': orderId,
        'customer_id': customerId,
        'vendor_id': vendorId,
        'amount': totalPrice,
        'method': paymentMethod,
        'status': 'completed',
        'transaction_id': 'TXN${DateTime.now().millisecondsSinceEpoch}',
        'created_at': DateTime.now().toIso8601String(),
        'completed_at': DateTime.now().toIso8601String(),
      };
      
      final paymentResult = await supabase
          .from(SupabaseTables.payments)
          .insert(paymentData)
          .select()
          .single();
      
      // Create earnings record for vendor
      final earningsData = {
        'vendor_id': vendorId,
        'order_id': orderId,
        'amount': vendorEarnings,
        'status': 'pending', // Will be marked as paid when withdrawal is processed
        'created_at': DateTime.now().toIso8601String(),
      };
      
      final earningsResult = await supabase
          .from('earnings')
          .insert(earningsData)
          .select()
          .single();
      
      // Record admin commission
      await _recordAdminCommission(
        orderId: orderId,
        amount: adminCommission,
        transactionId: paymentData['transaction_id']?.toString() ?? '',
      );
      
      return {
        'success': true,
        'payment': paymentResult,
        'earnings': earningsResult,
        'total_amount': totalPrice,
        'vendor_earnings': vendorEarnings,
        'admin_commission': adminCommission,
      };
      
    } catch (e) {
      print('Payment processing error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Record admin commission
  Future<void> _recordAdminCommission({
    required String orderId,
    required double amount,
    required String transactionId,
  }) async {
    try {
      // Create notification for admin about commission
      await supabase.from('notifications').insert({
        'user_id': supabase.auth.currentUser?.id,
        'title': 'Commission Received',
        'body': 'Commission of TZS ${amount.toStringAsFixed(0)} from order $orderId',
        'type': 'commission',
        'data': {
          'order_id': orderId,
          'amount': amount,
          'transaction_id': transactionId,
        },
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      print('Error recording admin commission: $e');
    }
  }
  
  // Simulate mobile money payment
  Future<Map<String, dynamic>> simulateMobileMoneyPayment({
    required String phoneNumber,
    required double amount,
    required String provider, // 'tigo', 'mpesa', 'airtel'
  }) async {
    try {
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 3));
      
      // Simulate successful payment
      final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';
      
      return {
        'success': true,
        'transaction_id': transactionId,
        'provider': provider,
        'amount': amount,
        'phone_number': phoneNumber,
        'status': 'completed',
        'message': 'Payment processed successfully via ${provider.toUpperCase()}',
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': 'Payment failed: ${e.toString()}',
      };
    }
  }
  
  // Legacy payment method (for backward compatibility)
  Future<bool> processPayment({
    required String orderId,
    required double amount,
    required String method,
    String? mobileNumber,
  }) async {
    try {
      final paymentData = {
        'order_id': orderId,
        'customer_id': 'temp_customer_id', // Replace with actual
        'vendor_id': 'temp_vendor_id', // Replace with actual
        'amount': amount,
        'method': method,
        'status': 'completed',
        'transaction_id': 'TXN${DateTime.now().millisecondsSinceEpoch}',
        'created_at': DateTime.now().toIso8601String(),
        'completed_at': DateTime.now().toIso8601String(),
      };
      
      await supabase
          .from(SupabaseTables.payments)
          .insert(paymentData);
      
      return true;
    } catch (e) {
      print('Payment error: $e');
      return false;
    }
  }
  
  Future<List<PaymentModel>> getPaymentHistory(String customerId) async {
    try {
      final response = await supabase
          .from(SupabaseTables.payments)
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      
      return response.map((json) => PaymentModel.fromJson(json)).toList();
    } catch (e) {
      print('Get payment history error: $e');
      return [];
    }
  }
  
  // Get vendor earnings
  Future<List<Map<String, dynamic>>> getVendorEarnings(String vendorId) async {
    try {
      final earnings = await supabase
          .from('earnings')
          .select('*, orders(id, created_at)')
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(earnings);
      
    } catch (e) {
      print('Error getting vendor earnings: $e');
      return [];
    }
  }
}
