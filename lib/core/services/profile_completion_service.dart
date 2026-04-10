import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileCompletionService extends ChangeNotifier {
  static const String _profileCompletionKey = 'profile_completion_status';
  
  bool _hasShownCustomerPrompt = false;
  bool _hasShownVendorPrompt = false;
  bool _isCustomerProfileComplete = false;
  bool _isVendorProfileComplete = false;
  
  bool get hasShownCustomerPrompt => _hasShownCustomerPrompt;
  bool get hasShownVendorPrompt => _hasShownVendorPrompt;
  bool get isCustomerProfileComplete => _isCustomerProfileComplete;
  bool get isVendorProfileComplete => _isVendorProfileComplete;
  
  ProfileCompletionService() {
    _loadProfileCompletionStatus();
  }

  Future<void> _loadProfileCompletionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasShownCustomerPrompt = prefs.getBool('customer_prompt_shown') ?? false;
      _hasShownVendorPrompt = prefs.getBool('vendor_prompt_shown') ?? false;
      _isCustomerProfileComplete = prefs.getBool('customer_profile_complete') ?? false;
      _isVendorProfileComplete = prefs.getBool('vendor_profile_complete') ?? false;
      notifyListeners();
    } catch (e) {
      print('Error loading profile completion status: $e');
    }
  }

  Future<void> _saveProfileCompletionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('customer_prompt_shown', _hasShownCustomerPrompt);
      await prefs.setBool('vendor_prompt_shown', _hasShownVendorPrompt);
      await prefs.setBool('customer_profile_complete', _isCustomerProfileComplete);
      await prefs.setBool('vendor_profile_complete', _isVendorProfileComplete);
    } catch (e) {
      print('Error saving profile completion status: $e');
    }
  }

  // Check if customer needs to complete profile
  bool shouldShowCustomerProfilePrompt() {
    return !_hasShownCustomerPrompt && !_isCustomerProfileComplete;
  }

  // Check if vendor needs to complete profile
  bool shouldShowVendorProfilePrompt() {
    return !_hasShownVendorPrompt && !_isVendorProfileComplete;
  }

  // Mark customer profile as complete
  Future<void> markCustomerProfileComplete() async {
    _isCustomerProfileComplete = true;
    await _saveProfileCompletionStatus();
    notifyListeners();
  }

  // Mark vendor profile as complete
  Future<void> markVendorProfileComplete() async {
    _isVendorProfileComplete = true;
    await _saveProfileCompletionStatus();
    notifyListeners();
  }

  // Mark customer prompt as shown
  Future<void> markCustomerPromptShown() async {
    _hasShownCustomerPrompt = true;
    await _saveProfileCompletionStatus();
    notifyListeners();
  }

  // Mark vendor prompt as shown
  Future<void> markVendorPromptShown() async {
    _hasShownVendorPrompt = true;
    await _saveProfileCompletionStatus();
    notifyListeners();
  }

  // Reset all completion status (for testing)
  Future<void> resetCompletionStatus() async {
    _hasShownCustomerPrompt = false;
    _hasShownVendorPrompt = false;
    _isCustomerProfileComplete = false;
    _isVendorProfileComplete = false;
    await _saveProfileCompletionStatus();
    notifyListeners();
  }
}
