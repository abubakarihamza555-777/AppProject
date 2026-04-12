// lib/modules/customer/screens/customer_profile_completion_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/services/profile_completion_service.dart';
import '../../../shared/services/location_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/customer_profile_controller.dart';

class CustomerProfileCompletionScreen extends StatefulWidget {
  const CustomerProfileCompletionScreen({super.key});

  @override
  State<CustomerProfileCompletionScreen> createState() {
    return _CustomerProfileCompletionScreenState();
  }
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
    setState(() {
      _isLoading = true;
    });
    try {
      _districts = await LocationService.getDistricts();
    } catch (e) {
      _showSnackBar('Error loading locations: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      if (mounted) {
        setState(() {});
      }
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
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        _showSnackBar('Error: ${e.toString()}', Colors.red);
      }
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
    final completionPercentage = _getCompletionPercentage();
    final isComplete = completionPercentage == 100;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        centerTitle: true,
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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressCard(completionPercentage, isComplete),
                    const SizedBox(height: 24),
                    _buildDistrictSelector(),
                    const SizedBox(height: 16),
                    _buildWardSelector(),
                    const SizedBox(height: 16),
                    _buildStreetField(),
                    const SizedBox(height: 16),
                    _buildHouseNumberField(),
                    const SizedBox(height: 16),
                    _buildLandmarkField(),
                    const SizedBox(height: 24),
                    _buildAccessibilitySection(),
                    if (_errorMessage != null) _buildErrorWidget(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(isComplete),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProgressCard(int percentage, bool isComplete) {
    return Container(
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
                  'Profile Completion: $percentage%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete your profile for better delivery service',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Your District',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _selectedDistrictId,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Select district',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.location_city),
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
            if (value == null) return 'Please select your district';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildWardSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Your Ward',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _selectedWardId,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Select ward',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.place),
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
            if (value == null) return 'Please select your ward';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStreetField() {
    return CustomTextField(
      controller: _streetNameController,
      label: 'Street Name',
      hintText: 'Enter your street name',
      prefixIcon: Icons.location_on,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter street name';
        }
        return null;
      },
    );
  }

  Widget _buildHouseNumberField() {
    return CustomTextField(
      controller: _houseNumberController,
      label: 'House/Building Number',
      hintText: 'Enter your house number',
      prefixIcon: Icons.home,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter house number';
        }
        return null;
      },
    );
  }

  Widget _buildLandmarkField() {
    return CustomTextField(
      controller: _landmarkController,
      label: 'Nearest Landmark (Optional)',
      hintText: 'e.g., Near school, mosque, shop',
      prefixIcon: Icons.flag,
    );
  }

  Widget _buildAccessibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Truck Accessibility',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
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
                      title: 'Yes, truck can access',
                      icon: Icons.local_shipping,
                      isSelected: _isTruckAccessible,
                      onTap: () => setState(() => _isTruckAccessible = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAccessibilityOption(
                      title: 'No, only small vehicles',
                      icon: Icons.agriculture,
                      isSelected: !_isTruckAccessible,
                      onTap: () => setState(() => _isTruckAccessible = false),
                    ),
                  ),
                ],
              ),
              if (!_isTruckAccessible) _buildAccessibilityWarning(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccessibilityWarning() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
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
              'Only towable browsers can access your location',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
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
    );
  }

  Widget _buildSubmitButton(bool isComplete) {
    if (_isSaving) {
      return const LoadingIndicator(message: 'Saving your profile...');
    }
    
    return CustomButton(
      text: isComplete ? 'Complete Profile' : 'Save Progress',
      onPressed: _submitProfile,
      backgroundColor: isComplete ? Colors.green : Colors.blue,
    );
  }
}
