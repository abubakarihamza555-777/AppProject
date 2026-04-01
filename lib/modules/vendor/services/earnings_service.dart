import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase/supabase_client.dart';
import '../../../config/supabase/supabase_tables.dart';
import '../models/earnings_model.dart';

class EarningsService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Get vendor earnings
  Future<List<EarningsModel>> getVendorEarnings(String vendorId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.earnings)
          .select()
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false);
      
      return response.map((json) => EarningsModel.fromJson(json)).toList();
    } catch (e) {
      print('Get vendor earnings error: $e');
      return [];
    }
  }
  
  // Get total earnings
  Future<double> getTotalEarnings(String vendorId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.earnings)
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
  
  // Get pending earnings
  Future<double> getPendingEarnings(String vendorId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.earnings)
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
  
  // Get earnings by period
  Future<Map<String, double>> getEarningsByPeriod(String vendorId, String period) async {
    try {
      final response = await _supabase.rpc('get_earnings_by_period', params: {
        'vendor_id': vendorId,
        'period': period, // 'daily', 'weekly', 'monthly', 'yearly'
      });
      
      return Map<String, double>.from(response);
    } catch (e) {
      print('Get earnings by period error: $e');
      return {};
    }
  }
  
  // Request withdrawal
  Future<bool> requestWithdrawal(String vendorId, double amount) async {
    try {
      await _supabase
          .from('withdrawals')
          .insert({
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
