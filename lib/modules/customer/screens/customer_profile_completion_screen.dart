import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/services/profile_completion_service.dart';
import '../../../shared/services/location_service.dart';
import '../../../localization/language_provider.dart';  // ADD THIS IMPORT
import '../../auth/controllers/auth_controller.dart';
import '../controllers/customer_profile_controller.dart';

class CustomerProfileCompletionScreen extends StatefulWidget {
  const CustomerProfileCompletionScreen({super.key});

  @override
  State<CustomerProfileCompletionScreen> createState() => _CustomerProfileCompletionScreenState();
}

class _CustomerProfileCompletionScreenState extends State<CustomerProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetNameController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _landmarkController = TextEditingController();
  
  int? _selectedDistrictId;
  int? _selectedWardId;
  bool _isTruckAccessible = true;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  
  // Location data
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _wards = [];
  
  final ProfileCompletionService _profileCompletionService = ProfileCompletionService();

  @override
  void initState() {
    super.initState();
    _loadLocationData();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _streetNameController.dispose();
    _houseNumberController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _loadLocationData() async {
    setState(() => _isLoading = true);
    try {
      _districts = await LocationService.getDistricts();
      setState(() {});
    } catch (e) {
      _showSnackBar('Error loading locations: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExistingProfile() async {
    final controller = context.read<CustomerProfileController>();
    await controller.loadCustomerProfile();
    
    final profile = controller.profileData;
    if (profile.isNotEmpty) {
      setState(() {
        _selectedDistrictId = profile['district_id'];
        _selectedWardId = profile['ward_id'];
        _streetNameController.text = profile['street_name'] ?? '';
        _houseNumberController.text = profile['house_number'] ?? '';
        _landmarkController.text = profile['landmark'] ?? '';
        _isTruckAccessible = profile['is_truck_accessible'] ?? true;
      });
      
      if (_selectedDistrictId != null) {
        await _loadWardsForDistrict(_selectedDistrictId!);
      }
    }
  }

  Future<void> _loadWardsForDistrict(int districtId) async {
    try {
      _wards = await LocationService.getWards(districtId);
      setState(() {});
    } catch (e) {
      print('Error loading wards: $e');
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDistrictId == null) {
      _showSnackBar('Please select your district', Colors.red);
      return;
    }

    if (_selectedWardId == null) {
      _showSnackBar('Please select your ward', Colors.red);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final authController = context.read<AuthController>();
      final userId = authController.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final controller = context.read<CustomerProfileController>();
      final result = await controller.updateCustomerProfile(
        districtId: _selectedDistrictId!,
        wardId: _selectedWardId!,
        streetName: _streetNameController.text.trim(),
        houseNumber: _houseNumberController.text.trim(),
        landmark: _landmarkController.text.trim(),
        isTruckAccessible: _isTruckAccessible,
      );

      if (result['success'] == true && mounted) {
        await _profileCompletionService.markCustomerProfileCompleted();
        _showSnackBar('Profile completed successfully!', Colors.green);
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
          }
        });
      } else {
        throw Exception(result['error'] ?? 'Failed to save profile');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  int _getCompletionPercentage() {
    int completed = 0;
    int total = 5;
    
    if (_selectedDistrictId != null) completed++;
    if (_selectedWardId != null) completed++;
    if (_streetNameController.text.isNotEmpty) completed++;
    if (_houseNumberController.text.isNotEmpty) completed++;
    if (_landmarkController.text.isNotEmpty) completed++;
    
    return ((completed / total) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isSwahili = languageProvider.currentLocale.languageCode == 'sw';
    final completionPercentage = _getCompletionPercentage();
    final isComplete = completionPercentage == 100;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isSwahili ? 'Kamilisha Wasifu Wako' : 'Complete Your Profile'),
        centerTitle: true,
        actions: [
          if (isComplete)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.verified, color: Colors.green),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: completionPercentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isComplete ? Colors.green : Colors.blue,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isSwahili ? 'Umekamilisha: $completionPercentage%' : 'Completion: $completionPercentage%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isSwahili 
                                      ? 'Kamilisha wasifu wako kwa huduma bora'
                                      : 'Complete your profile for better delivery service',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Location Information Section
                    Text(
                      isSwahili ? 'Mahali Unapotaka Kufikishiwa' : 'Your Delivery Location',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSwahili 
                          ? 'Chagua wilaya na kata unayoishi'
                          : 'Select your district and ward for accurate delivery',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    
                    // District Selection
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedDistrictId != null ? Colors.blue.shade50 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedDistrictId != null ? Colors.blue : Colors.grey.shade300,
                          width: _selectedDistrictId != null ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.location_city, color: Colors.blue.shade700, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isSwahili ? 'Wilaya Yako' : 'Your District',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _selectedDistrictId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: isSwahili ? 'Chagua Wilaya' : 'Select District',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: _districts.map((district) {
                              return DropdownMenuItem(
                                value: district['id'] as int,
                                child: Text(district['name'] as String),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              setState(() {
                                _selectedDistrictId = value;
                                _selectedWardId = null;
                                _wards = [];
                              });
                              if (value != null) {
                                await _loadWardsForDistrict(value);
                              }
                            },
                            validator: (value) {
                              if (value == null) {
                                return isSwahili ? 'Tafadhali chagua wilaya' : 'Please select your district';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Ward Selection
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedWardId != null ? Colors.blue.shade50 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedWardId != null ? Colors.blue : Colors.grey.shade300,
                          width: _selectedWardId != null ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.place, color: Colors.green.shade700, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isSwahili ? 'Kata Yako' : 'Your Ward',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _selectedWardId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: isSwahili ? 'Chagua Kata' : 'Select Ward',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: _wards.map((ward) {
                              return DropdownMenuItem(
                                value: ward['id'] as int,
                                child: Text(ward['name'] as String),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedWardId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return isSwahili ? 'Tafadhali chagua kata' : 'Please select your ward';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Address Details Section
                    Text(
                      isSwahili ? 'Maelezo ya Anwani' : 'Address Details',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSwahili 
                          ? 'Weka maelezo ya nyumba yako kwa usahihi'
                          : 'Provide your house details for accurate delivery',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    
                    // Street Name
                    CustomTextField(
                      controller: _streetNameController,
                      label: isSwahili ? 'Jina la Mtaa' : 'Street Name',
                      hintText: isSwahili ? 'Weka jina la mtaa wako' : 'Enter your street name',
                      prefixIcon: Icons.streetview,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return isSwahili ? 'Tafadhali weka jina la mtaa' : 'Please enter street name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // House Number
                    CustomTextField(
                      controller: _houseNumberController,
                      label: isSwahili ? 'Namba ya Jengo/Nyumba' : 'House/Building Number',
                      hintText: isSwahili ? 'Weka namba ya nyumba yako' : 'Enter your house number',
                      prefixIcon: Icons.home,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return isSwahili ? 'Tafadhali weka namba ya nyumba' : 'Please enter house number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Landmark (Optional)
                    CustomTextField(
                      controller: _landmarkController,
                      label: isSwahili ? 'Mahali pa Kujulikana (Si lazima)' : 'Nearest Landmark (Optional)',
                      hintText: isSwahili ? 'Mfano: Karibu na skuli, msikiti, duka' : 'e.g., Near school, mosque, shop',
                      prefixIcon: Icons.flag,
                    ),
                    const SizedBox(height: 24),
                    
                    // Truck Accessibility Section
                    Text(
                      isSwahili ? 'Ufikiaji wa Lori' : 'Truck Accessibility',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSwahili 
                          ? 'Je, lori kubwa linaweza kufika nyumbani kwako?'
                          : 'Can large water trucks access your location?',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildAccessibilityOption(
                                  title: isSwahili ? 'Ndiyo, lori linaweza' : 'Yes, truck can access',
                                  icon: Icons.local_shipping,
                                  isSelected: _isTruckAccessible,
                                  color: Colors.green,
                                  onTap: () => setState(() => _isTruckAccessible = true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildAccessibilityOption(
                                  title: isSwahili ? 'Hapana, gari ndogo tu' : 'No, only small vehicles',
                                  icon: Icons.agriculture,
                                  isSelected: !_isTruckAccessible,
                                  color: Colors.orange,
                                  onTap: () => setState(() => _isTruckAccessible = false),
                                ),
                              ),
                            ],
                          ),
                          if (!_isTruckAccessible) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isSwahili 
                                          ? 'Utapata huduma kutoka kwa towable browser pekee'
                                          : 'Only towable browsers can access your location',
                                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    _isSaving
                        ? const LoadingIndicator(message: 'Saving your profile...')
                        : CustomButton(
                            text: isComplete 
                                ? (isSwahili ? 'Kamilisha Wasifu' : 'Complete Profile')
                                : (isSwahili ? 'Hifadhi Mabadiliko' : 'Save Progress'),
                            onPressed: _submitProfile,
                            backgroundColor: isComplete ? Colors.green : Colors.blue,
                          ),
                    
                    if (!isComplete) ...[
                      const SizedBox(height: 12),
                      Text(
                        isSwahili 
                            ? 'Tafadhali kamilisha sehemu zote muhimu kwa huduma bora'
                            : 'Please complete all required fields for better service',
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAccessibilityOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}