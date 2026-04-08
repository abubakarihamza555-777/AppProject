import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerProfileController extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, dynamic> _profileData = {};
  
  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Map<String, dynamic> get profileData => _profileData;
  
  // Calculate profile completion percentage
  int calculateCompletionPercentage(Map<String, dynamic> data) {
    int completed = 0;
    int total = 5; // Total fields to complete
    
    if (data['district_id'] != null && data['district_id'] > 0) completed++;
    if (data['ward_id'] != null && data['ward_id'] > 0) completed++;
    if (data['street_name'] != null && data['street_name'].toString().isNotEmpty) completed++;
    if (data['house_number'] != null && data['house_number'].toString().isNotEmpty) completed++;
    if (data['landmark'] != null && data['landmark'].toString().isNotEmpty) completed++;
    
    return ((completed / total) * 100).round();
  }
  
  // Load customer profile
  Future<void> loadCustomerProfile() async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
      
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final response = await supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .maybeSingle();
      
      if (response != null) {
        _profileData = Map<String, dynamic>.from(response);
      }
      
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
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
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
      
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final updateData = {
        'district_id': districtId,
        'ward_id': wardId,
        'street_name': streetName,
        'house_number': houseNumber,
        'landmark': landmark,
        'is_truck_accessible': isTruckAccessible,
      };
      
      final result = await supabase
          .from('users')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();
      
      _profileData = Map<String, dynamic>.from(result);
      
      // Check if profile is complete
      int completionPercentage = calculateCompletionPercentage(_profileData);
      
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
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get formatted address
  String getFormattedAddress() {
    if (_profileData.isEmpty) return 'No address set';
    
    return 'House: ${_profileData['house_number'] ?? ''}, '
           'Street: ${_profileData['street_name'] ?? ''}, '
           'Ward: ${_profileData['ward_name'] ?? ''}, '
           'District: ${_profileData['district_name'] ?? ''}';
  }
  
  // Check if truck can access location
  bool canTruckAccessLocation() {
    return _profileData['is_truck_accessible'] ?? true;
  }
  
  // Get available delivery services based on location
  List<String> getAvailableDeliveryServices() {
    final canTruckAccess = canTruckAccessLocation();
    
    if (canTruckAccess) {
      return ['towable', 'medium_truck', 'heavy_truck'];
    } else {
      return ['towable']; // Only towable browsers can access
    }
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
