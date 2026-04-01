import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase/supabase_client.dart';
import '../../../config/supabase/supabase_tables.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Sign up with email and password
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      // Create auth user
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': role,
        },
      );
      
      if (response.user != null) {
        // Save user data to users table
        final userData = {
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'phone': phone,
          'role': role,
          'created_at': DateTime.now().toIso8601String(),
          'is_active': true,
        };
        
        await _supabase
            .from(SupabaseTables.users)
            .insert(userData);
        
        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }
  
  // Sign in with email and password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Get user data from users table
        final userData = await _supabase
            .from(SupabaseTables.users)
            .select()
            .eq('id', response.user!.id)
            .single();
        
        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  // Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
  
  // Check if user is authenticated
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
  
  // Update user profile
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _supabase
        .from(SupabaseTables.users)
        .update(data)
        .eq('id', userId);
  }
}
