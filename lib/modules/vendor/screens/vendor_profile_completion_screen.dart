// lib/modules/vendor/screens/vendor_profile_completion_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/services/profile_completion_service.dart';
import '../../shared/services/location_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/vendor_profile_controller.dart';
import '../models/vendor_model.dart';

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
  
  String? _selectedVehicleType;
  int _maxLitersPerTrip = 1000;
  List<int> _selectedDistricts = [];
  final List<int> _selectedWards = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  
  // Location data
  List<Map<String, dynamic>> _districts = [];
  final Map<int, List<Map<String, dynamic>>> _wardsCache = {};
  
  // Vehicle types
  final List<Map<String, dynamic>> _vehicleTypes = [
    {'id': 'towable', 'name': 'Towable Browser', 'capacity': '400-2000L', 'min': 400, 'max': 2000, 'icon': Icons.agriculture, 'color': 0xFF4CAF50},
    {'id': 'medium_truck', 'name': 'Medium Truck', 'capacity': '3000-5000L', 'min': 3000, 'max': 5000, 'icon': Icons.local_shipping, 'color': 0xFF2196F3},
    {'id': 'heavy_truck', 'name': 'Heavy Duty Truck', 'capacity': '8000-16000L', 'min': 8000, 'max': 16000, 'icon': Icons.airport_shuttle, 'color': 0xFFFF9800},
  ];
  
  final ProfileCompletionService _profileCompletionService = ProfileCompletionService();

  @override
  void initState() {
    super.initState();
    _loadLocationData();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessPhoneController.dispose();
    _businessAddressController.dispose();
    _businessLicenseController.dispose();
    super.dispose();
  }

  Future<void> _loadLocationData() async {
    setState(() => _isLoading = true);
    try {
      _districts = LocationService.getDistricts();
      setState(() {});
    } catch (e) {
      _showSnackBar('Error loading locations: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExistingProfile() async {
    final controller = context.read<VendorProfileController>();
    await controller.loadVendorProfile();
    
    final profile = controller.vendorProfile;
    if (profile != null) {
      setState(() {
        _businessNameController.text = profile.businessName;
        _businessPhoneController.text = profile.businessPhone;
        _businessAddressController.text = profile.businessAddress;
        _businessLicenseController.text = profile.businessLicense ?? '';
        _selectedVehicleType = profile.vehicleType;
        _maxLitersPerTrip = profile.maxLitersPerTrip ?? 1000;
        _selectedDistricts = profile.serviceAreas.cast<int>() ?? [];
      });
    }
  }

  Future<void> _loadWardsForDistrict(int districtId) async {
    if (_wardsCache.containsKey(districtId)) return;
    
    try {
      final wards = LocationService.getWardsByDistrict(districtId);
      _wardsCache[districtId] = wards;
      setState(() {});
    } catch (e) {
      print('Error loading wards: $e');
    }
  }

  int _getCompletionPercentage() {
    int completed = 0;
    int total = 7;
    
    if (_businessNameController.text.isNotEmpty) completed++;
    if (_businessPhoneController.text.isNotEmpty) completed++;
    if (_businessAddressController.text.isNotEmpty) completed++;
    if (_selectedVehicleType != null) completed++;
    if (_maxLitersPerTrip > 0) completed++;
    if (_selectedDistricts.isNotEmpty) completed++;
    if (_selectedWards.isNotEmpty) completed++;
    
    return ((completed / total) * 100).round();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVehicleType == null) {
      _showSnackBar('Please select your vehicle type', Colors.red);
      return;
    }

    if (_selectedDistricts.isEmpty) {
      _showSnackBar('Please select at least one service district', Colors.red);
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

      final controller = context.read<VendorProfileController>();
      final success = await controller.createOrUpdateVendorProfile(
        businessName: _businessNameController.text.trim(),
        businessPhone: _businessPhoneController.text.trim(),
        businessAddress: _businessAddressController.text.trim(),
        businessLicense: _businessLicenseController.text.trim().isEmpty 
            ? null 
            : _businessLicenseController.text.trim(),
        vehicleType: _selectedVehicleType!,
        maxLitersPerTrip: _maxLitersPerTrip,
        serviceAreas: _selectedDistricts,
      );

      if (success && mounted) {
        await _profileCompletionService.markVendorProfileCompleted();
        
        _showSnackBar('Vendor profile completed successfully!', Colors.green);
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.vendorDashboard);
          }
        });
      } else {
        throw Exception('Failed to save vendor profile');
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

  @override
  Widget build(BuildContext context) {
    final completionPercentage = _getCompletionPercentage();
    final isComplete = completionPercentage == 100;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Vendor Profile'),
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
                                  'Profile Completion: $completionPercentage%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Business Information Section
                    const Text(
                      'Business Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      controller: _businessNameController,
                      label: 'Business Name',
                      hintText: 'Enter your business name',
                      prefixIcon: Icons.business,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter business name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      controller: _businessPhoneController,
                      label: 'Business Phone',
                      hintText: 'Enter business phone number',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter business phone';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      controller: _businessAddressController,
                      label: 'Business Address',
                      hintText: 'Enter your business address',
                      prefixIcon: Icons.location_on,
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter business address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      controller: _businessLicenseController,
                      label: 'Business License (Optional)',
                      hintText: 'Enter business license number',
                      prefixIcon: Icons.document_scanner,
                    ),
                    const SizedBox(height: 24),
                    
                    // Vehicle Type Section
                    const Text(
                      'Vehicle Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    ..._vehicleTypes.map((vehicle) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildVehicleOption(vehicle),
                    )),
                    
                    const SizedBox(height: 16),
                    
                    // Max Liters Slider
                    Text(
                      'Maximum Capacity: $_maxLitersPerTrip Liters',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _maxLitersPerTrip.toDouble(),
                      min: _getMinCapacity(),
                      max: _getMaxCapacity(),
                      divisions: 20,
                      label: '$_maxLitersPerTrip L',
                      onChanged: (value) {
                        setState(() {
                          _maxLitersPerTrip = value.round();
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Service Areas Section
                    const Text(
                      'Service Areas',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select districts where you can provide water delivery',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    
                    ..._districts.map((district) => _buildDistrictOption(district)),
                    
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
                        ? const LoadingIndicator(message: 'Saving your vendor profile...')
                        : CustomButton(
                            text: isComplete ? 'Complete Profile' : 'Save Progress',
                            onPressed: _submitProfile,
                            backgroundColor: isComplete ? Colors.green : Colors.blue,
                          ),
                    
                    if (!isComplete) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Please complete all required fields to start receiving orders',
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

  double _getMinCapacity() {
    if (_selectedVehicleType == 'heavy_truck') return 8000;
    if (_selectedVehicleType == 'medium_truck') return 3000;
    return 400;
  }

  double _getMaxCapacity() {
    if (_selectedVehicleType == 'heavy_truck') return 16000;
    if (_selectedVehicleType == 'medium_truck') return 5000;
    return 2000;
  }

  Widget _buildVehicleOption(Map<String, dynamic> vehicle) {
    final isSelected = _selectedVehicleType == vehicle['id'];
    final color = Color(vehicle['color'] as int);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicleType = vehicle['id'];
          _maxLitersPerTrip = vehicle['max'];
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(vehicle['icon'] as IconData, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Capacity: ${vehicle['capacity']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictOption(Map<String, dynamic> district) {
    final districtId = district['id'] as int;
    final isSelected = _selectedDistricts.contains(districtId);
    final districtWards = _wardsCache[districtId] ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ExpansionTile(
        title: Text(
          district['name'],
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue : Colors.grey.shade800,
          ),
        ),
        leading: Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedDistricts.add(districtId);
                _loadWardsForDistrict(districtId);
              } else {
                _selectedDistricts.remove(districtId);
                _selectedWards.removeWhere((w) => 
                  districtWards.map((dw) => dw['id']).contains(w)
                );
              }
            });
          },
          activeColor: Colors.blue,
        ),
        children: isSelected
            ? [
                Container(
                  margin: const EdgeInsets.only(left: 48, right: 16, bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Wards (Optional - select all if you serve entire district)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (districtWards.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: districtWards.map((ward) {
                            final wardId = ward['id'] as int;
                            final isWardSelected = _selectedWards.contains(wardId);
                            return FilterChip(
                              label: Text(
                                ward['name'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isWardSelected ? Colors.white : Colors.grey.shade700,
                                ),
                              ),
                              selected: isWardSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedWards.add(wardId);
                                  } else {
                                    _selectedWards.remove(wardId);
                                  }
                                });
                              },
                              backgroundColor: Colors.grey.shade100,
                              selectedColor: Colors.blue,
                              checkmarkColor: Colors.white,
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: isWardSelected ? Colors.blue : Colors.grey.shade300,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Tip: Selecting specific wards helps customers find you faster',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            : [],
      ),
    );
  }
}
