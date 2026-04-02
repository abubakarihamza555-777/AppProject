import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../localization/language_provider.dart';
import '../controllers/auth_controller.dart';

class VendorRegistrationScreen extends StatefulWidget {
  const VendorRegistrationScreen({super.key});

  @override
  State<VendorRegistrationScreen> createState() => _VendorRegistrationScreenState();
}

class _VendorRegistrationScreenState extends State<VendorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _maxLitersController = TextEditingController();
  
  String _vehicleType = 'small_truck';
  bool _canNegotiateLargeOrders = false;
  bool _agreeToTerms = false;
  int _currentStep = 0;
  
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _allWards = [];
  Map<int, List<Map<String, dynamic>>> _wardsByDistrict = {};
  Map<int, List<int>> _selectedWardsByDistrict = {};
  bool _isLoadingDistricts = true;

  @override
  void initState() {
    super.initState();
    _loadDistrictsAndWards();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _maxLitersController.dispose();
    super.dispose();
  }

  Future<void> _loadDistrictsAndWards() async {
    // TODO: Load from Supabase
    // Mock data for demonstration
    await Future.delayed(const Duration(seconds: 1));
    
    final districts = [
      {'id': 1, 'name': 'Kinondoni'},
      {'id': 2, 'name': 'Ilala'},
      {'id': 3, 'name': 'Temeke'},
      {'id': 4, 'name': 'Kigamboni'},
      {'id': 5, 'name': 'Ubungo'},
    ];

    final allWards = [
      {'id': 1, 'name': 'Hananasifu', 'district_id': 1},
      {'id': 2, 'name': 'Kawe', 'district_id': 1},
      {'id': 3, 'name': 'Kijitonyama', 'district_id': 1},
      {'id': 4, 'name': 'Mwananyamala', 'district_id': 1},
      {'id': 5, 'name': 'Magomeni', 'district_id': 1},
      {'id': 6, 'name': 'Manzese', 'district_id': 1},
      {'id': 7, 'name': 'Tandale', 'district_id': 1},
      {'id': 8, 'name': 'Ubungo', 'district_id': 1},
      {'id': 9, 'name': 'Buguruni', 'district_id': 2},
      {'id': 10, 'name': 'Kariakoo', 'district_id': 2},
      {'id': 11, 'name': 'Kisutu', 'district_id': 2},
      {'id': 12, 'name': 'Mchikichini', 'district_id': 2},
      {'id': 13, 'name': 'Mikocheni', 'district_id': 2},
      {'id': 14, 'name': 'Tabata', 'district_id': 2},
      {'id': 15, 'name': 'Vingunguti', 'district_id': 2},
      {'id': 16, 'name': 'Azimio', 'district_id': 3},
      {'id': 17, 'name': 'Buza', 'district_id': 3},
      {'id': 18, 'name': 'Mbagala', 'district_id': 3},
      {'id': 19, 'name': 'Temeke', 'district_id': 3},
      {'id': 20, 'name': 'Yombo', 'district_id': 3},
    ];

    // Group wards by district
    final wardsByDistrict = <int, List<Map<String, dynamic>>>{};
    for (final ward in allWards) {
      final districtId = ward['district_id'] as int;
      wardsByDistrict.putIfAbsent(districtId, () => []);
      wardsByDistrict[districtId]!.add(ward);
    }

    setState(() {
      _isLoadingDistricts = false;
      _districts = districts;
      _allWards = allWards;
      _wardsByDistrict = wardsByDistrict;
    });
  }

  List<Step> _getSteps() {
    return [
      Step(
        title: const Text('Maelezo ya Biashara'),
        content: _buildBusinessInfoStep(),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: const Text('Eneo la Huduma'),
        content: _buildServiceAreaStep(),
        isActive: _currentStep >= 1,
      ),
      Step(
        title: const Text('Uwezo wa Kusafirisha'),
        content: _buildCapacityStep(),
        isActive: _currentStep >= 2,
      ),
      Step(
        title: const Text('Bei na Mikakati'),
        content: _buildPricingStep(),
        isActive: _currentStep >= 3,
      ),
      Step(
        title: const Text('Thibitisha'),
        content: _buildConfirmationStep(),
        isActive: _currentStep >= 4,
      ),
    ];
  }

  Widget _buildBusinessInfoStep() {
    return Column(
      children: [
        CustomTextField(
          label: 'Jina la Biashara',
          controller: _businessNameController,
          prefixIcon: Icons.store_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Tafadhali jaza jina la biashara';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Jina Kamili la Mmiliki',
          controller: _ownerNameController,
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Tafadhali jaza jina kamili';
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
    );
  }

  Widget _buildServiceAreaStep() {
    return Column(
      children: [
        const Text(
          'Chagua maeneo unayohudumia',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        
        if (_isLoadingDistricts)
          const CircularProgressIndicator()
        else
          ListView.builder(
            shrinkWrap: true,
            itemCount: _districts.length,
            itemBuilder: (context, index) {
              final district = _districts[index];
              final districtId = district['id'] as int;
              final wards = _wardsByDistrict[districtId] ?? [];
              final selectedWards = _selectedWardsByDistrict[districtId] ?? [];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Checkbox(
                        value: selectedWards.length == wards.length,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              // Select all wards in this district
                              _selectedWardsByDistrict[districtId] = 
                                  wards.map((w) => w['id'] as int).toList();
                            } else {
                              // Deselect all wards in this district
                              _selectedWardsByDistrict[districtId] = [];
                            }
                          });
                        },
                      ),
                      Expanded(child: Text(district['name'])),
                      Text('${selectedWards.length}/${wards.length}'),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: wards.map((ward) {
                          final wardId = ward['id'] as int;
                          final isSelected = selectedWards.contains(wardId);
                          
                          return CheckboxListTile(
                            title: Text(ward['name']),
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                final currentSelection = List<int>.from(
                                  _selectedWardsByDistrict[districtId] ?? []
                                );
                                
                                if (value == true) {
                                  currentSelection.add(wardId);
                                } else {
                                  currentSelection.remove(wardId);
                                }
                                
                                _selectedWardsByDistrict[districtId] = currentSelection;
                              });
                            },
                            dense: true,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCapacityStep() {
    return Column(
      children: [
        const Text(
          'Aina ya Gari',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        
        RadioListTile<String>(
          title: const Text('Lori Ndogo (hadi lita 2,000)'),
          value: 'small_truck',
          groupValue: _vehicleType,
          onChanged: (value) {
            setState(() {
              _vehicleType = value!;
            });
          },
        ),
        
        RadioListTile<String>(
          title: const Text('Tanker Kubwa (hadi lita 10,000)'),
          value: 'large_tanker',
          groupValue: _vehicleType,
          onChanged: (value) {
            setState(() {
              _vehicleType = value!;
            });
          },
        ),
        
        RadioListTile<String>(
          title: const Text('Aina Zote Mbili'),
          value: 'both',
          groupValue: _vehicleType,
          onChanged: (value) {
            setState(() {
              _vehicleType = value!;
            });
          },
        ),
        
        const SizedBox(height: 20),
        
        CustomTextField(
          label: 'Uwezo Mkuu wa Lita kwa Safari Moja',
          controller: _maxLitersController,
          isNumber: true,
          prefixIcon: Icons.water_drop,
          hintText: 'Mfano: 5000',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Tafadhali jaza uwezo wa lita';
            }
            final liters = int.tryParse(value);
            if (liters == null || liters <= 0) {
              return 'Tafadhali jaza namba sahihi ya lita';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPricingStep() {
    return Column(
      children: [
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
                  const Text(
                    'Muundo wa Bei',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Bei ya kawaida: TSh 100 kwa kila lita 10 (ni pamoja na gharama ya usafirishaji)',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mfano: Lita 40 = TSh 400 (gharama ya usafirishaji) + TSh 800 (maji) = Jumla TSh 1,200',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        CheckboxListTile(
          title: const Text('Naweza kujadili bei kwa maagizo makubwa'),
          subtitle: const Text('Wateja wanaagiza lita 1,000 au zaidi'),
          value: _canNegotiateLargeOrders,
          onChanged: (value) {
            setState(() {
              _canNegotiateLargeOrders = value!;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    // Calculate total selected wards
    int totalSelectedWards = _selectedWardsByDistrict.values
        .fold(0, (sum, wards) => sum + wards.length);
    
    String vehicleTypeText = '';
    switch (_vehicleType) {
      case 'small_truck':
        vehicleTypeText = 'Lori Ndogu';
        break;
      case 'large_tanker':
        vehicleTypeText = 'Tanker Kubwa';
        break;
      case 'both':
        vehicleTypeText = 'Aina Zote Mbili';
        break;
    }

    return Column(
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
                'Muhtasari Wa Usajili wa Mtoa Huduma',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow('Jina la Biashara:', _businessNameController.text),
              _buildSummaryRow('Mmiliki:', _ownerNameController.text),
              _buildSummaryRow('Simu:', _phoneController.text),
              _buildSummaryRow('Aina ya Gari:', vehicleTypeText),
              _buildSummaryRow('Uwezo wa Lita:', '${_maxLitersController.text}'),
              _buildSummaryRow('Maeneo Yanayohudumiliwa:', '$totalSelectedWards kata'),
              if (_canNegotiateLargeOrders)
                _buildSummaryRow('Uwezo wa Kujadili:', 'Ndiyo'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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
    if (_currentStep < _getSteps().length - 1) {
      setState(() {
        _currentStep++;
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if at least one ward is selected
    int totalSelectedWards = _selectedWardsByDistrict.values
        .fold(0, (sum, wards) => sum + wards.length);
    
    if (totalSelectedWards == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tafadhali chagua angalau kata moja unayohudumia'),
          backgroundColor: Colors.red,
        ),
      );
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
    final success = await authController.signUp(
      email: '${_phoneController.text}@vendor.com', // Temporary email
      password: _passwordController.text,
      fullName: _ownerNameController.text,
      phone: _phoneController.text,
      role: 'vendor',
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
        title: const Text('Jisajili Kama Mtoa Huduma'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  constraints.maxWidth < 360 ? 12.0 : 16.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Stepper(
                    type: constraints.maxWidth < 400 
                        ? StepperType.vertical 
                        : StepperType.horizontal,
                    currentStep: _currentStep,
                    steps: _getSteps(),
                    onStepContinue: _handleRegister,
                    onStepCancel: () {
                      if (_currentStep > 0) {
                        setState(() {
                          _currentStep--;
                        });
                      }
                    },
                    controlsBuilder: (context, details) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            if (_currentStep > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: details.onStepCancel,
                                  child: const Text('RUDI'),
                                ),
                              ),
                            if (_currentStep > 0) const SizedBox(width: 8),
                            Expanded(
                              child: CustomButton(
                                text: _currentStep == _getSteps().length - 1 
                                    ? 'JISAJILI KAMA MTOA HUDUMA' 
                                    : 'ENDAYE',
                                onPressed: details.onStepContinue,
                                isLoading: context.watch<AuthController>().isLoading,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
