import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/vendor_service.dart';
import '../models/vendor_model.dart';

class VendorProfileController extends ChangeNotifier {
  final VendorService _vendorService = VendorService();
  final supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  VendorModel? _vendorProfile;
  bool _isEditing = false;
  String _errorMessage = '';
  Map<String, dynamic> _profileData = {};
  
  bool get isLoading => _isLoading;
  VendorModel? get vendorProfile => _vendorProfile;
  bool get isEditing => _isEditing;
  String get errorMessage => _errorMessage;
  Map<String, dynamic> get profileData => _profileData;
  
  // Calculate profile completion percentage
  int calculateCompletionPercentage(Map<String, dynamic> data) {
    int completed = 0;
    int total = 7; // Total fields to complete
    
    if (data['business_name'] != null && data['business_name'].toString().isNotEmpty) completed++;
    if (data['business_phone'] != null && data['business_phone'].toString().isNotEmpty) completed++;
    if (data['business_address'] != null && data['business_address'].toString().isNotEmpty) completed++;
    if (data['business_license'] != null && data['business_license'].toString().isNotEmpty) completed++;
    if (data['profile_image'] != null && data['profile_image'].toString().isNotEmpty) completed++;
    if (data['vehicle_type'] != null && data['vehicle_type'].toString().isNotEmpty) completed++;
    if (data['max_liters_per_trip'] != null && data['max_liters_per_trip'].toString().isNotEmpty) completed++;
    
    return ((completed / total) * 100).round();
  }
  
  // Load vendor profile
  Future<void> loadVendorProfile() async {
    _setLoading(true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final vendor = await _vendorService.getVendorByUserId(userId);
      if (vendor != null) {
        _vendorProfile = vendor;
        _profileData = vendor.toJson();
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('Error loading vendor profile: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Update vendor profile with new fields
  Future<Map<String, dynamic>> updateVendorProfile({
    String? businessName,
    String? businessPhone,
    String? businessAddress,
    String? businessLicense,
    String? profileImage,
    String? vehicleType,
    int? maxLitersPerTrip,
  }) async {
    _setLoading(true);
    
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (businessName != null) updateData['business_name'] = businessName;
      if (businessPhone != null) updateData['business_phone'] = businessPhone;
      if (businessAddress != null) updateData['business_address'] = businessAddress;
      if (businessLicense != null) updateData['business_license'] = businessLicense;
      if (profileImage != null) updateData['profile_image'] = profileImage;
      if (vehicleType != null) updateData['vehicle_type'] = vehicleType;
      if (maxLitersPerTrip != null) updateData['max_liters_per_trip'] = maxLitersPerTrip;
      
      // Check if profile exists
      final existingProfile = await supabase
          .from('vendors')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      
      Map<String, dynamic> result;
      
      if (existingProfile != null) {
        // Update existing profile
        result = await supabase
            .from('vendors')
            .update(updateData)
            .eq('user_id', userId)
            .select()
            .single();
      } else {
        // Create new profile
        updateData.addAll({
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
          'is_active': true,
          'is_verified': false,
          'rating': 0.0,
          'total_deliveries': 0,
        });
        
        result = await supabase
            .from('vendors')
            .insert(updateData)
            .select()
            .single();
      }
      
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
      _setLoading(false);
    }
  }
  
  // Legacy update method for backward compatibility
  Future<bool> updateProfile({
    String? businessName,
    String? businessPhone,
    String? businessAddress,
    String? profileImage,
  }) async {
    if (_vendorProfile == null) return false;
    
    _setLoading(true);
    
    try {
      final data = <String, dynamic>{};
      if (businessName != null) data['business_name'] = businessName;
      if (businessPhone != null) data['business_phone'] = businessPhone;
      if (businessAddress != null) data['business_address'] = businessAddress;
      if (profileImage != null) data['profile_image'] = profileImage;
      
      final updated = await _vendorService.updateVendor(_vendorProfile!.id, data);
      if (updated != null) {
        _vendorProfile = updated;
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> toggleAvailability() async {
    if (_vendorProfile == null) return false;
    
    _setLoading(true);
    
    try {
      final success = await _vendorService.toggleVendorAvailability(_vendorProfile!.id);
      if (success && _vendorProfile != null) {
        _vendorProfile = _vendorProfile!.copyWith(isActive: !_vendorProfile!.isActive);
      }
      return success;
    } catch (e) {
      print('Error toggling availability: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Get vehicle type details
  Map<String, dynamic> getVehicleTypeDetails(String vehicleType) {
    final vehicleTypes = {
      'towable': {
        'name': 'Towable Browser',
        'description': '400-2000 Liters capacity',
        'icon': 'agriculture',
        'color': 'orange',
        'min_liters': 400,
        'max_liters': 2000,
      },
      'medium_truck': {
        'name': 'Medium Truck',
        'description': '3000-5000 Liters capacity',
        'icon': 'local_shipping',
        'color': 'blue',
        'min_liters': 3000,
        'max_liters': 5000,
      },
      'heavy_truck': {
        'name': 'Heavy Duty Truck',
        'description': '8000-16000 Liters capacity',
        'icon': 'airport_shuttle',
        'color': 'purple',
        'min_liters': 8000,
        'max_liters': 16000,
      },
    };
    
    return vehicleTypes[vehicleType] ?? vehicleTypes['towable']!;
  }
  
  // Validate vehicle capacity
  bool validateVehicleCapacity(String vehicleType, int capacity) {
    final details = getVehicleTypeDetails(vehicleType);
    return capacity >= details['min_liters'] && capacity <= details['max_liters'];
  }
  
  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
