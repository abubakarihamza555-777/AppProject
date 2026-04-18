// lib/modules/vendor/controllers/vendor_profile_controller.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vendor_model.dart';
import '../../auth/controllers/auth_controller.dart';

class VendorProfileController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  VendorModel? _vendorProfile;
  bool _isLoading = false;
  bool _isEditing = false;
  String? _errorMessage;
  
  VendorModel? get vendorProfile => _vendorProfile;
  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;
  String? get errorMessage => _errorMessage;
  
  Future<void> loadVendorProfile() async {
    setLoading(true);
    _clearError();
    
    try {
      final authController = AuthController();
      await authController.initialize();
      final currentUser = authController.currentUser;
      
      print('🔍 Loading vendor profile for user: ${currentUser?.id}');
      
      if (currentUser == null) {
        print('❌ User not authenticated');
        setLoading(false);
        return;
      }
      
      final response = await _supabase
          .from('vendors')
          .select()
          .eq('user_id', currentUser.id)
          .maybeSingle();
      
      if (response != null) {
        // VendorModel.fromJson handles all type conversions
        _vendorProfile = VendorModel.fromJson(response);
        print('✅ Vendor profile loaded: ${_vendorProfile?.businessName}');
      } else {
        print('📭 No vendor profile found');
        _vendorProfile = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Load vendor profile error: $e');
    } finally {
      setLoading(false);
    }
  }
  
  Future<bool> createOrUpdateVendorProfile({
    required String businessName,
    required String businessPhone,
    String businessAddress = '', // Now optional with default
    String? businessLicense, // Now optional
    required String vehicleType,
    required int maxLitersPerTrip,
    required List<int> serviceAreas,
  }) async {
    setLoading(true);
    _clearError();
    
    try {
      final authController = AuthController();
      await authController.initialize();
      final currentUser = authController.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      print('=== SAVING VENDOR PROFILE ===');
      print('User ID: ${currentUser.id}');
      print('Business Name: $businessName');
      print('Vehicle Type: $vehicleType');
      print('Service Areas: $serviceAreas');
      
      final now = DateTime.now().toIso8601String();
      
      final vendorData = {
        'user_id': currentUser.id,
        'business_name': businessName,
        'business_phone': businessPhone,
        'business_address': businessAddress.isNotEmpty ? businessAddress : 'Dar es Salaam',
        'business_license': businessLicense,
        'vehicle_type': vehicleType,
        'max_liters_per_trip': maxLitersPerTrip,
        'service_areas': serviceAreas,
        'is_active': true,
        'updated_at': now,
      };
      
      print('📤 Sending data to database: $vendorData');
      
      // Use UPSERT - Update if exists, Insert if not
      final response = await _supabase
          .from('vendors')
          .upsert(vendorData, onConflict: 'user_id')
          .select();
      
      print('✅ Upsert successful');
      
      if (response.isNotEmpty) {
        _vendorProfile = VendorModel.fromJson(response.first);
        print('✅ Vendor profile saved: ${_vendorProfile?.businessName}');
      }
      
      // Update user role to vendor
      await _supabase
          .from('users')
          .update({'role': 'vendor', 'is_active': true})
          .eq('id', currentUser.id);
      
      print('✅ User role updated to vendor');
      print('=== SAVE COMPLETED SUCCESSFULLY ===');
      
      setLoading(false);
      return true;
      
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Save error: $e');
      
      if (e.toString().contains('duplicate key')) {
        print('❌ Duplicate key error - vendor already exists (upsert should handle this)');
      } else if (e.toString().contains('permission')) {
        print('❌ Permission error - check RLS policies');
      } else if (e.toString().contains('column')) {
        print('❌ Column error - check database schema');
      } else if (e.toString().contains('type')) {
        print('❌ Type error - check data types');
      }
      
      setLoading(false);
      return false;
    }
  }
  
  Future<bool> updateProfile({
    required String businessName,
    required String businessPhone,
    required String businessAddress,
  }) async {
    setLoading(true);
    _clearError();
    
    try {
      if (_vendorProfile == null) {
        throw Exception('Vendor profile not found');
      }
      
      final updateData = {
        'business_name': businessName,
        'business_phone': businessPhone,
        'business_address': businessAddress,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final response = await _supabase
          .from('vendors')
          .update(updateData)
          .eq('id', _vendorProfile!.id)
          .select()
          .single();
      
      _vendorProfile = VendorModel.fromJson(response);
      print('✅ Profile updated successfully');
      setLoading(false);
      return true;
      
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Update profile error: $e');
      setLoading(false);
      return false;
    }
  }
  
  Future<bool> toggleAvailability() async {
    if (_vendorProfile == null) return false;
    
    setLoading(true);
    
    try {
      final newStatus = !_vendorProfile!.isActive;
      await _supabase
          .from('vendors')
          .update({'is_active': newStatus})
          .eq('id', _vendorProfile!.id);
      
      _vendorProfile = _vendorProfile!.copyWith(isActive: newStatus);
      print('✅ Availability toggled to: $newStatus');
      setLoading(false);
      return true;
      
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Toggle availability error: $e');
      setLoading(false);
      return false;
    }
  }
  
  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }
  
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
}