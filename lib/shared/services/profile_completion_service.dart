import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileCompletionService {
  
  // ==================== VENDOR METHODS ====================
  
  /// Check if vendor profile should be shown (checks database first)
  Future<bool> shouldShowVendorProfilePrompt() async {
    // FIRST: Check if vendor exists in database
    final isCompleted = await isVendorProfileCompleted();
    
    // If database has verified vendor, NEVER show prompt
    if (isCompleted) {
      print('✅ Vendor verified in DB - skipping prompt');
      return false;
    }
    
    // Only check local storage if no verified vendor in DB
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('vendor_profile_prompt_shown') ?? false;
    return !hasShown;
  }
  
  /// Check if vendor profile is completed (checks REAL database)
  Future<bool> isVendorProfileCompleted() async {
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      
      if (session == null) {
        print('❌ No active session');
        return false;
      }
      
      final userId = session.user.id;
      print('🔍 Checking vendor profile for user: $userId');
      
      final result = await supabase
          .from('vendors')
          .select('id, business_name, is_verified, is_active')
          .eq('user_id', userId)
          .maybeSingle();
      
      print('📊 Database result: $result');
      
      // Profile is COMPLETE if: vendor exists AND is_verified = true
      final isComplete = result != null && result['is_verified'] == true;
      
      print('✅ Vendor profile complete: $isComplete');
      return isComplete;
      
    } catch (e) {
      print('❌ Error checking vendor profile: $e');
      return false;
    }
  }
  
  /// Mark vendor prompt as shown (local only)
  Future<void> markVendorPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vendor_profile_prompt_shown', true);
  }
  
  /// Mark vendor profile as completed (updates BOTH local and database)
  Future<void> markVendorProfileCompleted() async {
    // Update local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vendor_profile_completed', true);
    await prefs.setBool('vendor_profile_prompt_shown', true);
    
    // Update database to ensure is_verified = true
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      
      if (session != null) {
        await supabase
            .from('vendors')
            .update({'is_verified': true, 'is_active': true})
            .eq('user_id', session.user.id);
        print('✅ Database updated: vendor verified');
      }
    } catch (e) {
      print('⚠️ Could not update database: $e');
    }
  }
  
  // ==================== CUSTOMER METHODS ====================
  
  Future<bool> shouldShowCustomerProfilePrompt() async {
    final isCompleted = await isCustomerProfileCompleted();
    if (isCompleted) return false;
    
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('customer_profile_prompt_shown') ?? false;
    return !hasShown;
  }
  
  Future<bool> isCustomerProfileCompleted() async {
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      
      if (session == null) return false;
      
      final result = await supabase
          .from('users')
          .select('address, district_id, ward_id')
          .eq('id', session.user.id)
          .maybeSingle();
      
      if (result == null) return false;
      
      return (result['address'] != null && result['address'].toString().isNotEmpty) ||
             (result['district_id'] != null);
    } catch (e) {
      return false;
    }
  }
  
  Future<void> markCustomerPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('customer_profile_prompt_shown', true);
  }
  
  Future<void> markCustomerProfileCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('customer_profile_completed', true);
    await prefs.setBool('customer_profile_prompt_shown', true);
  }
  
  // ==================== RESET METHODS ====================
  
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
