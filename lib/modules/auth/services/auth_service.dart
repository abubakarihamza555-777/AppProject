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
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Create user in Supabase Auth with user metadata
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': role,
        },
      );

      if (response.user == null) {
        throw Exception('Failed to create user account');
      }

      // Wait a moment for trigger to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Fetch the user that was created by Supabase trigger
      final userData = await _supabase
          .from(SupabaseTables.users)
          .select()
          .eq('id', response.user!.id)
          .single();

      // Create role-specific profile only (users table already handled by trigger)
      if (role == 'customer' && additionalData != null) {
        await _supabase.from('customers').insert({
          'user_id': response.user!.id,
          'district_id': additionalData['district_id'],
          'ward_id': additionalData['ward_id'],
          'street': additionalData['street'],
          'house_number': additionalData['house_number'],
          'landmark': additionalData['landmark'],
          'is_truck_accessible': additionalData['is_truck_accessible'] ?? true,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else if (role == 'vendor' && additionalData != null) {
        await _supabase.from('vendors').insert({
          'user_id': response.user!.id,
          'business_name': additionalData['business_name'],
          'owner_name': additionalData['owner_name'],
          'vehicle_type': additionalData['vehicle_type'],
          'max_delivery_liters': additionalData['max_delivery_liters'],
          'can_negotiate_large_orders': additionalData['can_negotiate_large_orders'] ?? false,
          'is_verified': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return UserModel.fromJson(userData);
      
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
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
        // Get user data from users table with better error handling
        try {
          final userData = await _supabase
              .from(SupabaseTables.users)
              .select()
              .eq('id', response.user!.id)
              .single();
          
          return UserModel.fromJson(userData);
        } catch (e) {
          // If user data doesn't exist in users table, create it from auth data
          print('User data not found, creating from auth data: $e');
          
          final fallbackUserData = {
            'id': response.user!.id,
            'email': response.user!.email ?? email,
            'full_name': response.user!.userMetadata?['full_name'] ?? 'User',
            'phone': response.user!.userMetadata?['phone'] ?? '',
            'role': response.user!.userMetadata?['role'] ?? 'customer',
            'created_at': response.user!.createdAt,
            'is_active': true,
          };
          
          return UserModel.fromJson(fallbackUserData);
        }
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
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Try to get user data from users table
        try {
          final userData = await _supabase
              .from(SupabaseTables.users)
              .select()
              .eq('id', user.id)
              .single();
          
          return UserModel.fromJson(userData);
        } catch (e) {
          // If user data doesn't exist, create from auth data
          final fallbackUserData = {
            'id': user.id,
            'email': user.email ?? '',
            'full_name': user.userMetadata?['full_name'] ?? 'User',
            'phone': user.userMetadata?['phone'] ?? '',
            'role': user.userMetadata?['role'] ?? 'customer',
            'created_at': user.createdAt,
            'is_active': true,
          };
          
          return UserModel.fromJson(fallbackUserData);
        }
      }
      return null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
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
  
  // Add token management
  Future<String?> getAccessToken() async {
    return _supabase.auth.currentSession?.accessToken;
  }
  
  Future<bool> refreshSession() async {
    try {
      await _supabase.auth.refreshSession();
      return true;
    } catch (e) {
      print('Session refresh error: $e');
      return false;
    }
  }
  
  // Add session timeout
  Future<void> startSessionTimer() async {
    await Future.delayed(const Duration(hours: 24));
    await signOut();
  }
  
  // Add guest mode
  Future<UserModel?> signInAsGuest() async {
    // Create anonymous user
    final response = await _supabase.auth.signInAnonymously();
    if (response.user != null) {
      return UserModel(
        id: response.user!.id,
        email: 'guest@temp.com',
        fullName: 'Guest User',
        phone: '',
        role: 'customer',
        createdAt: DateTime.now(),
      );
    }
    return null;
  }
  
  // Add password reset confirmation
  Future<void> confirmPasswordReset(String email, String token, String newPassword) async {
    await _supabase.auth.recoverSession(token);
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
  
  // Add social sign in methods
  Future<UserModel?> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://callback',
      );
      
      // OAuth sign-in is handled by the redirect, so we just return null here
      // The actual user data will be available after the redirect
      return null;
    } catch (e) {
      print('Google sign in error: $e');
      return null;
    }
  }
  
  Future<UserModel?> signInWithFacebook() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'io.supabase.flutter://callback',
      );
      
      // OAuth sign-in is handled by the redirect, so we just return null here
      // The actual user data will be available after the redirect
      return null;
    } catch (e) {
      print('Facebook sign in error: $e');
      return null;
    }
  }
  
  Future<UserModel?> signInWithApple() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.flutter://callback',
      );
      
      // OAuth sign-in is handled by the redirect, so we just return null here
      // The actual user data will be available after the redirect
      return null;
    } catch (e) {
      print('Apple sign in error: $e');
      return null;
    }
  }
}
