import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../localization/language_provider.dart';
import '../controllers/auth_controller.dart';

class CustomerRegistrationScreen extends StatefulWidget {
  const CustomerRegistrationScreen({super.key});

  @override
  State<CustomerRegistrationScreen> createState() => _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState extends State<CustomerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _streetController = TextEditingController();
  final _houseController = TextEditingController();
  final _landmarkController = TextEditingController();
  
  int? _selectedDistrictId;
  int? _selectedWardId;
  bool _isTruckAccessible = true;
  bool _isLoadingDistricts = true;
  bool _isLoadingWards = false;
  bool _agreeToTerms = false;
  
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _wards = [];
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadDistricts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _streetController.dispose();
    _houseController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _loadDistricts() async {
    // TODO: Load districts from Supabase
    // For now, using mock data
    setState(() {
      _isLoadingDistricts = false;
      _districts = [
        {'id': 1, 'name': 'Kinondoni'},
        {'id': 2, 'name': 'Ilala'},
        {'id': 3, 'name': 'Temeke'},
        {'id': 4, 'name': 'Kigamboni'},
        {'id': 5, 'name': 'Ubungo'},
      ];
    });
  }

  Future<void> _loadWards(int districtId) async {
    setState(() {
      _isLoadingWards = true;
      _selectedWardId = null;
      _wards.clear();
    });

    // TODO: Load wards from Supabase based on district
    // Mock data for demonstration
    await Future.delayed(const Duration(seconds: 1));
    
    List<Map<String, dynamic>> mockWards = [];
    switch (districtId) {
      case 1: // Kinondoni
        mockWards = [
          {'id': 1, 'name': 'Hananasifu'},
          {'id': 2, 'name': 'Kawe'},
          {'id': 3, 'name': 'Kijitonyama'},
          {'id': 4, 'name': 'Mwananyamala'},
          {'id': 5, 'name': 'Magomeni'},
          {'id': 6, 'name': 'Manzese'},
          {'id': 7, 'name': 'Tandale'},
          {'id': 8, 'name': 'Ubungo'},
        ];
        break;
      case 2: // Ilala
        mockWards = [
          {'id': 9, 'name': 'Buguruni'},
          {'id': 10, 'name': 'Kariakoo'},
          {'id': 11, 'name': 'Kisutu'},
          {'id': 12, 'name': 'Mchikichini'},
          {'id': 13, 'name': 'Mikocheni'},
          {'id': 14, 'name': 'Tabata'},
          {'id': 15, 'name': 'Vingunguti'},
        ];
        break;
      // Add other districts...
    }

    setState(() {
      _isLoadingWards = false;
      _wards = mockWards;
    });
  }

  List<Step> _getSteps() {
    return [
      Step(
        title: const Text('Maelezo Msingi'),
        content: _buildBasicInfoStep(),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: const Text('Mahali Pa Kuishi'),
        content: _buildLocationStep(),
        isActive: _currentStep >= 1,
      ),
      Step(
        title: const Text('Chaguo Za Kufikishia'),
        content: _buildDeliveryStep(),
        isActive: _currentStep >= 2,
      ),
      Step(
        title: const Text('Thibitisha'),
        content: _buildConfirmationStep(),
        isActive: _currentStep >= 3,
      ),
    ];
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          CustomTextField(
            label: 'Jina Kamili',
            controller: _nameController,
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tafadhali jaza jina lako';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Namba ya Simu',
            controller: _phoneController,
            isPhone: true,
            prefixIcon: Icons.phone_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tafadhali jaza namba ya simu';
              }
              if (value.length < 10) {
                return 'Namba ya simu isi sahihi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Neno Siri',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: Icons.lock_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tafadhali jaza neno siri';
              }
              if (value.length < 4) {
                return 'Neno siri liwe na angalau herufi 4';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Thibitisha Neno Siri',
            controller: _confirmPasswordController,
            isPassword: true,
            prefixIcon: Icons.lock_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tafadhali thibitisha neno siri';
              }
              if (value != _passwordController.text) {
                return 'Neno siri hazilingani';
              }
              return null;
            },
          ),
          const SizedBox(height: 20), // Extra space for buttons
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // District Dropdown
          if (_isLoadingDistricts)
            const CircularProgressIndicator()
          else
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Chagua Wilaya',
                border: OutlineInputBorder(),
              ),
              value: _selectedDistrictId,
              items: _districts.map((district) {
                return DropdownMenuItem<int>(
                  value: district['id'],
                  child: Text(district['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDistrictId = value;
                  if (value != null) {
                    _loadWards(value);
                  }
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Tafadhali chagua wilaya';
                }
                return null;
              },
            ),
          
          const SizedBox(height: 16),
          
          // Ward Dropdown
          if (_isLoadingWards)
            const CircularProgressIndicator()
          else
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Chagua Kata',
                border: OutlineInputBorder(),
              ),
              value: _selectedWardId,
              items: _wards.map((ward) {
                return DropdownMenuItem<int>(
                  value: ward['id'],
                  child: Text(ward['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedWardId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Tafadhali chagua kata';
                }
                return null;
              },
            ),
          
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Jina la Mtaa',
            controller: _streetController,
            prefixIcon: Icons.location_on_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tafadhali jaza jina la mtaa';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Namba ya Nyumba',
            controller: _houseController,
            prefixIcon: Icons.home_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tafadhali jaza namba ya nyumba';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Mahali Pa Kujulikana (Hiari)',
            controller: _landmarkController,
            prefixIcon: Icons.flag_outlined,
            hintText: 'Mfano: Karibu na Tanesco pole, Nyuma ya duka la Salim',
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text(
            'Je, nyumba yako inaweza kupitiwa na lori?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          
          RadioListTile<bool>(
            title: const Text('Ndiyo - Lori inaweza kufika moja kwa moja'),
            value: true,
            groupValue: _isTruckAccessible,
            onChanged: (value) {
              setState(() {
                _isTruckAccessible = value!;
              });
            },
          ),
          
          RadioListTile<bool>(
            title: const Text('Hapana - Nitahitaji kupata sehemu nyingine ya kufikishia'),
            value: false,
            groupValue: _isTruckAccessible,
            onChanged: (value) {
              setState(() {
                _isTruckAccessible = value!;
              });
            },
          ),
          
          if (!_isTruckAccessible) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Muhtasari',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Utahitaji kutoa mahali mbadala pa kufikishia maji (mfano: barabarani karibu na makaburi).',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          CheckboxListTile(
            title: const Text('Nakubali masharti na sheria za programu'),
            value: _agreeToTerms,
            onChanged: (value) {
              setState(() {
                _agreeToTerms = value!;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          
          const SizedBox(height: 20),
          
          // Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Muhtasari Wa Usajili',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Jina:', _nameController.text),
                _buildSummaryRow('Simu:', _phoneController.text),
                if (_selectedDistrictId != null)
                  _buildSummaryRow(
                    'Wilaya:', 
                    _districts.firstWhere((d) => d['id'] == _selectedDistrictId)['name']
                  ),
                if (_selectedWardId != null)
                  _buildSummaryRow(
                    'Kata:', 
                    _wards.firstWhere((w) => w['id'] == _selectedWardId)['name']
                  ),
                _buildSummaryRow('Mtaa:', _streetController.text),
                _buildSummaryRow('Nyumba No:', _houseController.text),
                if (_landmarkController.text.isNotEmpty)
                  _buildSummaryRow('Mahali Pa Kujulikana:', _landmarkController.text),
                _buildSummaryRow('Lori Inaweza Kufika:', _isTruckAccessible ? 'Ndiyo' : 'Hapana'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tafadhali kubali masharti na sheria'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authController = context.read<AuthController>();
    
    // Prepare additional customer data
    final additionalData = {
      'district_id': _selectedDistrictId,
      'ward_id': _selectedWardId,
      'street': _streetController.text,
      'house_number': _houseController.text,
      'landmark': _landmarkController.text,
      'is_truck_accessible': _isTruckAccessible,
    };

    final success = await authController.signUp(
      email: _emailController.text.trim(), // Use real email
      password: _passwordController.text,
      fullName: _nameController.text,
      phone: _phoneController.text,
      role: 'customer',
      additionalData: additionalData,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usajili umefanikiwa! Inakupeleka kwenye ukurasa wa kuingia...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authController.errorMessage ?? 'Usajili umeshindikana'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jisajili Kama Mteja'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(
                constraints.maxWidth < 360 ? 12.0 : 16.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Basic Information
                    _buildSectionHeader('Taarifa za Msingi'),
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    
                    // Section 2: Location Information
                    _buildSectionHeader('Taarifa ya Mahali'),
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                    
                    // Section 3: Delivery Information
                    _buildSectionHeader('Taarifa ya Usafirishaji'),
                    _buildDeliverySection(),
                    const SizedBox(height: 24),
                    
                    // Section 4: Terms and Summary
                    _buildSectionHeader('Masharti na Muhtasari'),
                    _buildTermsSection(),
                    const SizedBox(height: 30),
                    
                    // Submit Button
                    CustomButton(
                      text: 'JISAJILI',
                      onPressed: _handleRegister,
                      isLoading: context.watch<AuthController>().isLoading,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          CustomTextField(
            label: 'Jina Kamili',
            controller: _nameController,
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tafadhali jaza jina lako';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Barua Pepe (Email)',
            controller: _emailController,
            isEmail: true,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tafadhali jaza barua pepe';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Tafadhali weka barua pepe sahihi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Namba ya Simu',
            controller: _phoneController,
            isPhone: true,
            prefixIcon: Icons.phone_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tafadhali jaza namba ya simu';
              }
              if (value.length < 10) {
                return 'Namba ya simu isi sahihi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Neno Siri',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: Icons.lock_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tafadhali jaza neno siri';
              }
              if (value.length < 4) {
                return 'Neno siri liwe na angalau herufi 4';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Thibitisha Neno Siri',
            controller: _confirmPasswordController,
            isPassword: true,
            prefixIcon: Icons.lock_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tafadhali thibitisha neno siri';
              }
              if (value != _passwordController.text) {
                return 'Neno siri hazilingani';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // District Dropdown
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Chagua Wilaya',
                prefixIcon: Icon(Icons.location_city, color: Colors.blue.shade600),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                labelStyle: TextStyle(color: Colors.grey.shade600),
              ),
              value: _selectedDistrictId,
              items: _districts.map((district) {
                return DropdownMenuItem<int>(
                  value: district['id'],
                  child: Text(
                    district['name'],
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDistrictId = value;
                  if (value != null) {
                    _loadWards(value);
                  }
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Tafadhali chagua wilaya';
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Ward Dropdown
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Chagua Kata',
                prefixIcon: Icon(Icons.location_on, color: Colors.blue.shade600),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                labelStyle: TextStyle(color: Colors.grey.shade600),
              ),
              value: _selectedWardId,
              items: _wards.map((ward) {
                return DropdownMenuItem<int>(
                  value: ward['id'],
                  child: Text(
                    ward['name'],
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedWardId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Tafadhali chagua kata';
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Jina la Mtaa',
            controller: _streetController,
            prefixIcon: Icons.location_on_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tafadhali jaza jina la mtaa';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Namba ya Nyumba',
            controller: _houseController,
            prefixIcon: Icons.home_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tafadhali jaza namba ya nyumba';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Mahali Pa Kujulikana (Hiari)',
            controller: _landmarkController,
            prefixIcon: Icons.flag_outlined,
            hintText: 'Mfano: Karibu na Tanesco pole, Nyuma ya duka la Salim',
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Text(
            'Je, nyumba yako inaweza kupitiwa na lori?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          
          RadioListTile<bool>(
            title: const Text('Ndiyo - Lori inaweza kufika moja kwa moja'),
            value: true,
            groupValue: _isTruckAccessible,
            onChanged: (value) {
              setState(() {
                _isTruckAccessible = value!;
              });
            },
          ),
          
          RadioListTile<bool>(
            title: const Text('Hapana - Nitahitaji kupata sehemu nyingine ya kufikishia'),
            value: false,
            groupValue: _isTruckAccessible,
            onChanged: (value) {
              setState(() {
                _isTruckAccessible = value!;
              });
            },
          ),
          
          if (!_isTruckAccessible) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Muhtasari',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Utahitaji kutoa mahali mbadala pa kufikishia maji (mfano: barabarani karibu na makaburi).',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTermsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            title: const Text('Nakubali masharti na sheria za programu'),
            value: _agreeToTerms,
            onChanged: (value) {
              setState(() {
                _agreeToTerms = value!;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          
          const SizedBox(height: 16),
          
          // Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Muhtasari Wa Usajili',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Jina:', _nameController.text),
                _buildSummaryRow('Simu:', _phoneController.text),
                if (_selectedDistrictId != null)
                  _buildSummaryRow(
                    'Wilaya:', 
                    _districts.firstWhere((d) => d['id'] == _selectedDistrictId)['name']
                  ),
                if (_selectedWardId != null)
                  _buildSummaryRow(
                    'Kata:', 
                    _wards.firstWhere((w) => w['id'] == _selectedWardId)['name']
                  ),
                _buildSummaryRow('Mtaa:', _streetController.text),
                _buildSummaryRow('Nyumba No:', _houseController.text),
                if (_landmarkController.text.isNotEmpty)
                  _buildSummaryRow('Mahali Pa Kujulikana:', _landmarkController.text),
                _buildSummaryRow('Lori Inaweza Kufika:', _isTruckAccessible ? 'Ndiyo' : 'Hapana'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
