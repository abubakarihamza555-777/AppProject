// lib/modules/auth/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _isInitialized = false;
  bool _isCheckingSession = false;
  
  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _currentUser != null;
  
  // Initialize auth controller - call this in splash screen
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isCheckingSession = true;
    notifyListeners();
    
    await loadCurrentUser();
    
    _isInitialized = true;
    _isCheckingSession = false;
    notifyListeners();
  }
  
  // Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    if (_isLoading) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.signIn(
        email: email.trim(),
        password: password,
      );
      
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Invalid email or password';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = _getUserFriendlyError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_isLoading) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.signUp(
        email: email.trim(),
        password: password,
        fullName: fullName.trim(),
        phone: phone.trim(),
        role: role,
        additionalData: additionalData,
      );
      
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Registration failed. Please try again.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = _getUserFriendlyError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      print('Sign out error: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Load current user data - FIXED to properly restore session
  Future<void> loadCurrentUser() async {
    try {
      // First check if there's an active session in Supabase
      final session = _supabase.auth.currentSession;
      
      if (session != null) {
        // Session exists, get user data
        final user = await _authService.getCurrentUser();
        if (user != null) {
          _currentUser = user;
        } else {
          // If user data not found, create minimal user from session
          _currentUser = UserModel(
            id: session.user.id,
            email: session.user.email ?? '',
            fullName: session.user.userMetadata?['full_name'] ?? 'User',
            phone: session.user.userMetadata?['phone'] ?? '',
            role: session.user.userMetadata?['role'] ?? 'customer',
            createdAt: DateTime.now(),
            isActive: true,
          );
        }
      } else {
        _currentUser = null;
      }
    } catch (e) {
      print('Error loading current user: $e');
      _currentUser = null;
    }
    notifyListeners();
  }
  
  // Refresh user data from server
  Future<void> refreshUserData() async {
    await loadCurrentUser();
  }
  
  // Check if user is authenticated without loading full data
  bool hasActiveSession() {
    return _supabase.auth.currentSession != null;
  }
  
  String _getUserFriendlyError(String error) {
    if (error.contains('duplicate key') || error.contains('already registered')) {
      return 'An account with this email already exists';
    }
    if (error.contains('rate limit')) {
      return 'Too many attempts. Please try again later';
    }
    if (error.contains('invalid email')) {
      return 'Please enter a valid email address';
    }
    if (error.contains('weak password')) {
      return 'Password is too weak. Please choose a stronger password';
    }
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    }
    return error;
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
}
