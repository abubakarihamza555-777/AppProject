import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../localization/language_provider.dart';
import '../../../core/services/location_service.dart';
import '../controllers/vendor_profile_controller.dart';

class VendorProfileCompletionScreen extends StatefulWidget {
  const VendorProfileCompletionScreen({super.key});

  @override
  State<VendorProfileCompletionScreen> createState() => _VendorProfileCompletionScreenState();
}

class _VendorProfileCompletionScreenState extends State<VendorProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessLicenseController = TextEditingController();
  
  String _selectedVehicleType = '';
  int _maxLitersPerTrip = 1000;
  int _completionPercentage = 0;
  bool _isLoading = false;
  
  // Service area selection
  List<int> _selectedDistricts = [];
  List<int> _selectedWards = [];

  final List<Map<String, dynamic>> _vehicleTypes = [
    {
      'id': 'towable',
      'name': 'Towable Browser',
      'description': '400-2000 Liters capacity',
      'icon': Icons.agriculture,
      'color': Colors.orange,
      'max_liters': 2000,
    },
    {
      'id': 'medium_truck',
      'name': 'Medium Truck',
      'description': '3000-5000 Liters capacity',
      'icon': Icons.local_shipping,
      'color': Colors.blue,
      'max_liters': 5000,
    },
    {
      'id': 'heavy_truck',
      'name': 'Heavy Duty Truck',
      'description': '8000-16000 Liters capacity',
      'icon': Icons.airport_shuttle,
      'color': Colors.purple,
      'max_liters': 16000,
    },
  ];

  @override
  void initState() {
    super.initState();
    _calculateCompletionPercentage();
  }

  void _calculateCompletionPercentage() {
    int completed = 0;
    int total = 8; // Total fields to complete (added service areas)

    if (_businessNameController.text.isNotEmpty) completed++;
    if (_businessPhoneController.text.isNotEmpty) completed++;
    if (_businessAddressController.text.isNotEmpty) completed++;
    if (_businessLicenseController.text.isNotEmpty) completed++;
    if (_selectedVehicleType.isNotEmpty) completed++;
    if (_maxLitersPerTrip > 0) completed++;
    if (_selectedDistricts.isNotEmpty) completed++; // Service areas
    
    setState(() {
      _completionPercentage = ((completed / total) * 100).round();
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Your Profile'),
        subtitle: Text('$_completionPercentage% Complete'),
        actions: [
          if (_completionPercentage == 100)
            Icon(Icons.verified, color: Colors.green),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        SizedBox(width: 8),
                        Text(
                          'Profile Completion',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _completionPercentage / 100,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _completionPercentage == 100 ? Colors.green : Colors.blue,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Complete your profile to start receiving orders',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Business Information
              Text(
                'Business Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _businessNameController,
                label: 'Business Name',
                hintText: 'Enter your business name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter business name';
                  }
                  return null;
                },
                onChanged: (value) => _calculateCompletionPercentage(),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _businessPhoneController,
                label: 'Business Phone',
                hintText: 'Enter business phone number',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter business phone';
                  }
                  return null;
                },
                onChanged: (value) => _calculateCompletionPercentage(),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _businessAddressController,
                label: 'Business Address',
                hintText: 'Enter your business address',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter business address';
                  }
                  return null;
                },
                onChanged: (value) => _calculateCompletionPercentage(),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _businessLicenseController,
                label: 'Business License (Optional)',
                hintText: 'Enter business license number',
                onChanged: (value) => _calculateCompletionPercentage(),
              ),
              const SizedBox(height: 24),

              // Vehicle Type Selection
              Text(
                'Select Your Vehicle Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose the type of vehicle you use for water delivery',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              ..._vehicleTypes.map((vehicle) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedVehicleType = vehicle['id'];
                      _maxLitersPerTrip = vehicle['max_liters'];
                    });
                    _calculateCompletionPercentage();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedVehicleType == vehicle['id']
                          ? vehicle['color'].shade50
                          : Colors.white,
                      border: Border.all(
                        color: _selectedVehicleType == vehicle['id']
                            ? vehicle['color']
                            : Colors.grey.shade300,
                        width: _selectedVehicleType == vehicle['id'] ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: vehicle['color'].shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            vehicle['icon'],
                            color: vehicle['color'],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vehicle['description'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedVehicleType == vehicle['id'])
                          Icon(
                            Icons.check_circle,
                            color: vehicle['color'],
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              )),

              const SizedBox(height: 24),

              // Service Area Selection
              Text(
                'Service Areas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select districts and wards where you can provide water delivery services',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              // District Selection
              ...LocationService.getDistricts().map((district) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedDistricts.contains(district['id'])
                        ? Colors.blue.shade50
                        : Colors.white,
                    border: Border.all(
                      color: _selectedDistricts.contains(district['id'])
                          ? Colors.blue
                          : Colors.grey.shade300,
                      width: _selectedDistricts.contains(district['id']) ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _selectedDistricts.contains(district['id']),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedDistricts.add(district['id']);
                                } else {
                                  _selectedDistricts.remove(district['id']);
                                  // Remove all wards from this district
                                  final districtWards = LocationService.getWardsByDistrict(district['id']);
                                  for (var ward in districtWards) {
                                    _selectedWards.remove(ward['id']);
                                  }
                                }
                              });
                              _calculateCompletionPercentage();
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              district['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _selectedDistricts.contains(district['id'])
                                    ? Colors.blue
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Show wards if district is selected
                      if (_selectedDistricts.contains(district['id'])) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Select Wards in ${district['name']}:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...LocationService.getWardsByDistrict(district['id']).map((ward) => Padding(
                          padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _selectedWards.contains(ward['id']),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedWards.add(ward['id']);
                                    } else {
                                      _selectedWards.remove(ward['id']);
                                    }
                                  });
                                  _calculateCompletionPercentage();
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                ward['name'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _selectedWards.contains(ward['id'])
                                      ? Colors.blue
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              )),

              const SizedBox(height: 24),

              // Max Liters Slider
              Text(
                'Maximum Liters Per Trip: $_maxLitersPerTrip L',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _maxLitersPerTrip.toDouble(),
                min: 400,
                max: _selectedVehicleType == 'heavy_truck' ? 16000 : 
                      _selectedVehicleType == 'medium_truck' ? 5000 : 2000,
                divisions: _selectedVehicleType == 'heavy_truck' ? 78 : 
                          _selectedVehicleType == 'medium_truck' ? 20 : 8,
                onChanged: (value) {
                  setState(() {
                    _maxLitersPerTrip = value.round();
                  });
                  _calculateCompletionPercentage();
                },
              ),

              const SizedBox(height: 32),

              // Submit Button
              _isLoading
                  ? const LoadingIndicator()
                  : CustomButton(
                      text: _completionPercentage == 100 
                          ? 'Complete Profile' 
                          : 'Save Progress',
                      onPressed: _completionPercentage > 0 ? _submitProfile : null,
                    ),

              if (_completionPercentage < 100) ...[
                const SizedBox(height: 16),
                Text(
                  'Please complete all required fields to activate your account',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDistricts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one service area'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual profile submission
      await Future.delayed(const Duration(seconds: 2));

      if (_completionPercentage == 100) {
        // Navigate to vendor dashboard
        Navigator.pushReplacementNamed(context, AppRoutes.vendorDashboard);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Progress saved. Complete your profile to start receiving orders.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessPhoneController.dispose();
    _businessAddressController.dispose();
    _businessLicenseController.dispose();
    super.dispose();
  }
}
