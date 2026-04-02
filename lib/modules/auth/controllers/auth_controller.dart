import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  UserModel? _currentUser;
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  
  // Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.signIn(
        email: email,
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
      _errorMessage = e.toString();
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
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
        additionalData: additionalData,
      );
      
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Registration failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
    _currentUser = null;
    _setLoading(false);
  }
  
  // Check if user is authenticated
  bool isAuthenticated() {
    return _authService.isAuthenticated();
  }
  
  // Load current user data
  Future<void> loadCurrentUser() async {
    try {
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      print('Error loading current user: $e');
      _currentUser = null;
      notifyListeners();
    }
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
}
