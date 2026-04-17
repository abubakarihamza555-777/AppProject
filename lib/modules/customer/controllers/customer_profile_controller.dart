import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/controllers/auth_controller.dart';

class CustomerProfileController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Map<String, dynamic> _profileData = {};
  bool _isLoading = false;
  bool _isEditing = false;
  String? _errorMessage;
  
  // Getters
  Map<String, dynamic> get profileData => _profileData;
  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;
  String? get errorMessage => _errorMessage;
  
  // Get full name from profile
  String get fullName => _profileData['full_name'] ?? 'Customer';
  String get email => _profileData['email'] ?? '';
  String get phone => _profileData['phone'] ?? '';
  String get address => _profileData['address'] ?? '';
  int? get districtId => _profileData['district_id'];
  int? get wardId => _profileData['ward_id'];
  String get streetName => _profileData['street_name'] ?? '';
  String get houseNumber => _profileData['house_number'] ?? '';
  String get landmark => _profileData['landmark'] ?? '';
  bool get isTruckAccessible => _profileData['is_truck_accessible'] ?? true;
  
  // Load customer profile
  Future<void> loadCustomerProfile() async {
    _setLoading(true);
    _clearError();
    
    try {
      final authController = AuthController();
      await authController.initialize();
      final currentUser = authController.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();
      
      if (response != null) {
        _profileData = Map<String, dynamic>.from(response);
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('Load customer profile error: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Update customer profile
  Future<Map<String, dynamic>> updateCustomerProfile({
    required int districtId,
    required int wardId,
    required String streetName,
    required String houseNumber,
    String? landmark,
    required bool isTruckAccessible,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final authController = AuthController();
      await authController.initialize();
      final currentUser = authController.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Build full address
      String fullAddress = streetName;
      if (houseNumber.isNotEmpty) fullAddress += ', House $houseNumber';
      if (landmark != null && landmark.isNotEmpty) fullAddress += ' (Near $landmark)';
      
      final updateData = {
        'district_id': districtId,
        'ward_id': wardId,
        'street_name': streetName,
        'house_number': houseNumber,
        'landmark': landmark,
        'is_truck_accessible': isTruckAccessible,
        'address': fullAddress,
        'profile_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final result = await _supabase
          .from('users')
          .update(updateData)
          .eq('id', currentUser.id)
          .select()
          .single();
      
      _profileData = Map<String, dynamic>.from(result);
      
      int completionPercentage = _calculateCompletionPercentage();
      
      return {
        'success': true,
        'data': result,
        'completion_percentage': completionPercentage,
        'is_complete': completionPercentage == 100,
      };
      
    } catch (e) {
      _errorMessage = e.toString();
      return {
        'success': false,
        'error': e.toString(),
      };
    } finally {
      _setLoading(false);
    }
  }
  
  // Update basic profile info (name, phone)
  Future<bool> updateBasicProfile({
    required String fullName,
    required String phone,
    String? address,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final authController = AuthController();
      await authController.initialize();
      final currentUser = authController.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      final updateData = {
        'full_name': fullName,
        'phone': phone,
        if (address != null) 'address': address,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await _supabase
          .from('users')
          .update(updateData)
          .eq('id', currentUser.id);
      
      _profileData['full_name'] = fullName;
      _profileData['phone'] = phone;
      if (address != null) _profileData['address'] = address;
      
      _setLoading(false);
      return true;
      
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }
  
  // Toggle edit mode
  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }
  
  // Calculate profile completion percentage
  int _calculateCompletionPercentage() {
    int completed = 0;
    int total = 5;
    
    if (_profileData['district_id'] != null && _profileData['district_id'] > 0) completed++;
    if (_profileData['ward_id'] != null && _profileData['ward_id'] > 0) completed++;
    if (_profileData['street_name'] != null && _profileData['street_name'].toString().isNotEmpty) completed++;
    if (_profileData['house_number'] != null && _profileData['house_number'].toString().isNotEmpty) completed++;
    if (_profileData['landmark'] != null && _profileData['landmark'].toString().isNotEmpty) completed++;
    
    return ((completed / total) * 100).round();
  }
  
  // Get formatted address for display
  String getFormattedAddress() {
    if (_profileData.isEmpty) return 'No address set';
    
    String address = '';
    if (_profileData['street_name'] != null && _profileData['street_name'].toString().isNotEmpty) {
      address += _profileData['street_name'];
    }
    if (_profileData['house_number'] != null && _profileData['house_number'].toString().isNotEmpty) {
      address += address.isNotEmpty ? ', House ${_profileData['house_number']}' : 'House ${_profileData['house_number']}';
    }
    if (_profileData['landmark'] != null && _profileData['landmark'].toString().isNotEmpty) {
      address += address.isNotEmpty ? ' (Near ${_profileData['landmark']})' : 'Near ${_profileData['landmark']}';
    }
    
    return address.isNotEmpty ? address : 'No address set';
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
}
