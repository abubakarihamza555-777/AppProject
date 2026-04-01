import '../../../config/supabase/supabase_client.dart';
import '../../../config/supabase/supabase_tables.dart';
import '../models/payment_model.dart';

class PaymentService {
  final supabase = SupabaseConfig.client;
  
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
}
