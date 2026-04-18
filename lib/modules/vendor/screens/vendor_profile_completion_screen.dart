import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/services/profile_completion_service.dart';
import '../../../shared/services/location_service.dart';
import '../../../localization/language_provider.dart';
import '../../auth/controllers/auth_controller.dart';
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
  
  // REMOVED: _businessAddressController
  // REMOVED: _businessLicenseController
  
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
    {'id': 'towable', 'name': 'Towable Browser', 'name_sw': 'Towable Browser', 'capacity': '400-2000L', 'min': 400, 'max': 2000, 'icon': Icons.agriculture, 'color': 0xFF4CAF50, 'description': 'Inafaa kwa nyumba ndogo na mitaa nyembamba'},
    {'id': 'medium_truck', 'name': 'Medium Truck', 'name_sw': 'Lori la Kati', 'capacity': '3000-5000L', 'min': 3000, 'max': 5000, 'icon': Icons.local_shipping, 'color': 0xFF2196F3, 'description': 'Inafaa kwa majengo ya ghorofa na biashara ndogo'},
    {'id': 'heavy_truck', 'name': 'Heavy Duty Truck', 'name_sw': 'Lori Kubwa', 'capacity': '8000-16000L', 'min': 8000, 'max': 16000, 'icon': Icons.airport_shuttle, 'color': 0xFFFF9800, 'description': 'Inafaa kwa viwanda, hoteli, na mahitaji makubwa'},
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
    final controller = VendorProfileController();
    await controller.loadVendorProfile();
    
    final profile = controller.vendorProfile;
    if (profile != null) {
      setState(() {
        _businessNameController.text = profile.businessName;
        _businessPhoneController.text = profile.businessPhone;
        // REMOVED: business address and license
        _selectedVehicleType = profile.vehicleType;
        _maxLitersPerTrip = profile.maxLitersPerTrip ?? 1000;
        _selectedDistricts = profile.serviceAreas ?? [];
      });
    }
  }

  Future<void> _loadWardsForDistrict(int districtId) async {
    if (_wardsCache.containsKey(districtId)) return;
    
    try {
      final wards = await LocationService.getWards(districtId);
      _wardsCache[districtId] = wards;
      setState(() {});
    } catch (e) {
      print('Error loading wards: $e');
    }
  }

  int _getCompletionPercentage() {
    int completed = 0;
    int total = 5; // REMOVED: address and license (was 7, now 5)
    
    if (_businessNameController.text.isNotEmpty) completed++;
    if (_businessPhoneController.text.isNotEmpty) completed++;
    if (_selectedVehicleType != null) completed++;
    if (_maxLitersPerTrip > 0) completed++;
    if (_selectedDistricts.isNotEmpty) completed++;
    // REMOVED: business address and license checks
    
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
      final authController = AuthController();
      await authController.initialize();
      final userId = authController.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final controller = VendorProfileController();
      final success = await controller.createOrUpdateVendorProfile(
        businessName: _businessNameController.text.trim(),
        businessPhone: _businessPhoneController.text.trim(),
        businessAddress: 'Dar es Salaam', // Default address
        businessLicense: null, // No license required
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
        throw Exception(controller.errorMessage ?? 'Failed to save vendor profile');
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
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isSwahili = languageProvider.currentLocale.languageCode == 'sw';
    final completionPercentage = _getCompletionPercentage();
    final isComplete = completionPercentage == 100;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isSwahili ? 'Kamilisha Wasifu Wako' : 'Complete Your Vendor Profile'),
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
                                      ? 'Kamilisha wasifu wako kuanza kupokea oda'
                                      : 'Complete your profile to start receiving orders',
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
                    Text(
                      isSwahili ? 'Taarifa za Biashara' : 'Business Information',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // Business Name
                    CustomTextField(
                      controller: _businessNameController,
                      label: isSwahili ? 'Jina la Biashara' : 'Business Name',
                      hintText: isSwahili ? 'Weka jina la biashara yako' : 'Enter your business name',
                      prefixIcon: Icons.business,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return isSwahili ? 'Tafadhali weka jina la biashara' : 'Please enter business name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Business Phone
                    CustomTextField(
                      controller: _businessPhoneController,
                      label: isSwahili ? 'Namba ya Simu ya Biashara' : 'Business Phone',
                      hintText: isSwahili ? 'Weka namba ya simu' : 'Enter business phone number',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return isSwahili ? 'Tafadhali weka namba ya simu' : 'Please enter business phone';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // REMOVED: Business Address Field
                    // REMOVED: Business License Field
                    
                    // Vehicle Information Section
                    Text(
                      isSwahili ? 'Taarifa za Gari' : 'Vehicle Information',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSwahili 
                          ? 'Chagua aina ya gari unayotumia kusafirisha maji'
                          : 'Select the type of vehicle you use for water delivery',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    
                    ..._vehicleTypes.map((vehicle) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildVehicleOption(vehicle, isSwahili),
                    )),
                    
                    const SizedBox(height: 16),
                    
                    // Max Liters Slider
                    Text(
                      isSwahili 
                          ? 'Upeo wa Lita kwa Safari Moja: $_maxLitersPerTrip L'
                          : 'Maximum Capacity Per Trip: $_maxLitersPerTrip L',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _maxLitersPerTrip.toDouble(),
                      min: _getMinCapacity(),
                      max: _getMaxCapacity(),
                      divisions: 20,
                      label: '$_maxLitersPerTrip L',
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        setState(() {
                          _maxLitersPerTrip = value.round();
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Service Areas Section
                    Text(
                      isSwahili ? 'Maeneo ya Huduma' : 'Service Areas',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSwahili 
                          ? 'Chagua wilaya ambazo unaweza kufikishia maji'
                          : 'Select districts where you can provide water delivery',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    
                    ..._districts.map((district) => _buildDistrictOption(district, isSwahili)),
                    
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
                            ? 'Tafadhali kamilisha sehemu zote muhimu kuanza kupokea oda'
                            : 'Please complete all required fields to start receiving orders',
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

  Widget _buildVehicleOption(Map<String, dynamic> vehicle, bool isSwahili) {
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
                    isSwahili ? vehicle['name_sw'] : vehicle['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSwahili ? vehicle['description'] : vehicle['capacity'],
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

  Widget _buildDistrictOption(Map<String, dynamic> district, bool isSwahili) {
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
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
          trailing: isSelected 
              ? const Icon(Icons.expand_more, color: Colors.blue)
              : const Icon(Icons.chevron_right, color: Colors.grey),
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
                          isSwahili 
                              ? 'Chagua Kata (Hiari - chagua zote ikiwa unahudumia kata zote)'
                              : 'Select Wards (Optional - select all if you serve entire district)',
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
                          isSwahili 
                              ? 'Kidokezo: Kuchagua kata maalum husaidia wateja kukupata kwa urahisi'
                              : 'Tip: Selecting specific wards helps customers find you faster',
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
      ),
    );
  }
}