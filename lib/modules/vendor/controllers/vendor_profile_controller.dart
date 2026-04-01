import 'package:flutter/material.dart';
import '../services/vendor_service.dart';
import '../models/vendor_model.dart';

class VendorProfileController extends ChangeNotifier {
  final VendorService _vendorService = VendorService();
  
  bool _isLoading = false;
  VendorModel? _vendorProfile;
  bool _isEditing = false;
  
  bool get isLoading => _isLoading;
  VendorModel? get vendorProfile => _vendorProfile;
  bool get isEditing => _isEditing;
  
  Future<void> loadVendorProfile(String vendorId) async {
    _setLoading(true);
    
    try {
      _vendorProfile = await _vendorService.getVendorById(vendorId);
    } catch (e) {
      print('Error loading vendor profile: $e');
    } finally {
      _setLoading(false);
    }
  }
  
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
  
  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
