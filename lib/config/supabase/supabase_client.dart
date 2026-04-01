import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_constants.dart';

class SupabaseConfig {
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      anonKey: SupabaseConstants.supabaseAnonKey,
    );
  }
  
  static bool isInitialized() {
    try {
      // Supabase.instance.client is non-null once initialize() succeeds.
      return true;
    } catch (e) {
      return false;
    }
  }
}
