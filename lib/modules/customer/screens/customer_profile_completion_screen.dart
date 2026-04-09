import 'package:flutter/material.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../modules/shared/services/location_service.dart';

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
  
  int _districtId = 0;
  int _wardId = 0;
  bool _isTruckAccessible = true;
  int _completionPercentage = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _calculateCompletionPercentage();
  }

  void _calculateCompletionPercentage() {
    int completed = 0;
    int total = 5; // Total fields to complete
    
    if (_districtId > 0) completed++;
    if (_wardId > 0) completed++;
    if (_streetNameController.text.isNotEmpty) completed++;
    if (_houseNumberController.text.isNotEmpty) completed++;
    if (_landmarkController.text.isNotEmpty) completed++;
    
    setState(() {
      _completionPercentage = ((completed / total) * 100).round();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Complete Your Profile'),
            Text('$_completionPercentage% Complete',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                )),
          ],
        ),
        actions: [
          if (_completionPercentage == 100)
            const Icon(Icons.verified, color: Colors.green),
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
                        const SizedBox(width: 8),
                        Text(
                          'Profile Completion',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _completionPercentage / 100,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _completionPercentage == 100 ? Colors.green : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete your profile for faster water delivery',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Location Information
              const Text(
                'Delivery Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              LocationSelector(
                initialDistrictId: _districtId > 0 ? _districtId : null,
                initialWardId: _wardId > 0 ? _wardId : null,
                onLocationChanged: (districtId, wardId) {
                  setState(() {
                    _districtId = districtId;
                    _wardId = wardId;
                  });
                  _calculateCompletionPercentage();
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _streetNameController,
                label: 'Street Name',
                hintText: 'Enter your street name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter street name';
                  }
                  return null;
                },
                onChanged: (value) => _calculateCompletionPercentage(),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _houseNumberController,
                label: 'House Number',
                hintText: 'Enter your house number',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter house number';
                  }
                  return null;
                },
                onChanged: (value) => _calculateCompletionPercentage(),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _landmarkController,
                label: 'Nearest Landmark (Optional)',
                hintText: 'e.g., Near school, mosque, shop',
                onChanged: (value) => _calculateCompletionPercentage(),
              ),
              const SizedBox(height: 24),

              // Delivery Preferences
              const Text(
                'Delivery Preferences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Truck Accessibility',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Can large water trucks access your location?',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isTruckAccessible = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isTruckAccessible 
                                    ? Colors.green.shade50 
                                    : Colors.white,
                                border: Border.all(
                                  color: _isTruckAccessible 
                                      ? Colors.green 
                                      : Colors.grey.shade300,
                                  width: _isTruckAccessible ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.local_shipping,
                                    color: _isTruckAccessible 
                                        ? Colors.green 
                                        : Colors.grey,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Yes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _isTruckAccessible 
                                          ? Colors.green 
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isTruckAccessible = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: !_isTruckAccessible 
                                    ? Colors.orange.shade50 
                                    : Colors.white,
                                border: Border.all(
                                  color: !_isTruckAccessible 
                                      ? Colors.orange 
                                      : Colors.grey.shade300,
                                  width: !_isTruckAccessible ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.agriculture,
                                    color: !_isTruckAccessible 
                                        ? Colors.orange 
                                        : Colors.grey,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'No',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: !_isTruckAccessible 
                                          ? Colors.orange 
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!_isTruckAccessible) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Only towable browsers can access your location',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
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
                  'Please complete all required fields for better service',
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

    if (_districtId == 0 || _wardId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your district and ward'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual profile submission
      await Future.delayed(const Duration(seconds: 2));

      if (_completionPercentage == 100) {
        // Navigate to home screen
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Progress saved. Complete your profile for better service.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _streetNameController.dispose();
    _houseNumberController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }
}
