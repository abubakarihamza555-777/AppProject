import 'package:shared_preferences/shared_preferences.dart';

class ProfileCompletionService {
  static final ProfileCompletionService _instance = ProfileCompletionService._internal();
  factory ProfileCompletionService() => _instance;
  ProfileCompletionService._internal();

  Future<bool> shouldShowCustomerProfilePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('customer_profile_prompt_shown');
    return !(shown ?? false);
  }

  Future<bool> shouldShowVendorProfilePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('vendor_profile_prompt_shown');
    return !(shown ?? false);
  }

  Future<void> markCustomerPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('customer_profile_prompt_shown', true);
  }

  Future<void> markVendorPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vendor_profile_prompt_shown', true);
  }
}
