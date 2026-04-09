import 'package:flutter/material.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class OrderPlacementScreen extends StatefulWidget {
  const OrderPlacementScreen({super.key});

  @override
  State<OrderPlacementScreen> createState() => _OrderPlacementScreenState();
}

class _OrderPlacementScreenState extends State<OrderPlacementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _houseController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _notesController = TextEditingController();
  
  int _selectedQuantity = 40; // Default 40L
  bool _useAlternativeAddress = false;
  bool _isAsapDelivery = true;
  DateTime? _scheduledDateTime;
  String _paymentMethod = 'cash';
  int _currentStep = 0;
  
  // Pricing constants
  static const int _pricePer10Liters = 300;
  static const int _deliveryFeePer10Liters = 100;
  static const int _waterCostPer10Liters = 200;

  final List<Map<String, int>> _quantityOptions = [
    {'liters': 10, 'price': 300},
    {'liters': 20, 'price': 600},
    {'liters': 40, 'price': 1200},
    {'liters': 100, 'price': 3000},
    {'liters': 400, 'price': 12000},
    {'liters': 1000, 'price': 30000},
    {'liters': 5000, 'price': 150000},
  ];

  @override
  void dispose() {
    _streetController.dispose();
    _houseController.dispose();
    _landmarkController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int calculateTotalPrice(int liters) {
    return (liters ~/ 10) * _pricePer10Liters;
  }

  int calculateWaterCost(int liters) {
    return (liters ~/ 10) * _waterCostPer10Liters;
  }

  int calculateDeliveryFee(int liters) {
    return (liters ~/ 10) * _deliveryFeePer10Liters;
  }

  List<Step> _getSteps() {
    return [
      Step(
        title: const Text('Kiasi'),
        content: _buildQuantityStep(),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: const Text('Mahali'),
        content: _buildLocationStep(),
        isActive: _currentStep >= 1,
      ),
      Step(
        title: const Text('Muda'),
        content: _buildTimeStep(),
        isActive: _currentStep >= 2,
      ),
      Step(
        title: const Text('Malipo'),
        content: _buildPaymentStep(),
        isActive: _currentStep >= 3,
      ),
      Step(
        title: const Text('Thibitisha'),
        content: _buildConfirmationStep(),
        isActive: _currentStep >= 4,
      ),
    ];
  }

  Widget _buildQuantityStep() {
    return Column(
      children: [
        const Text(
          'Chagua kiasi cha maji unachohitaji',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        
        // Quantity Selection Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _quantityOptions.length + 1, // +1 for custom option
          itemBuilder: (context, index) {
            if (index == _quantityOptions.length) {
              // Custom quantity option
              return InkWell(
                onTap: () => _showCustomQuantityDialog(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit, size: 24),
                      SizedBox(height: 4),
                      Text(
                        'CUSTOM',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            final option = _quantityOptions[index];
            final liters = option['liters']!;
            final price = option['price']!;
            final isSelected = _selectedQuantity == liters;
            
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedQuantity = liters;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected ? Colors.blue.shade50 : Colors.white,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${liters}L',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TSh ${price.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      )}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 20),
        
        // Price Breakdown
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
              const Text(
                ' Maelezo ya Bei',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              _buildPriceRow('Bei ya Maji:', calculateWaterCost(_selectedQuantity)),
              _buildPriceRow('Gharama ya Usafirishaji:', calculateDeliveryFee(_selectedQuantity)),
              const Divider(color: Colors.blue),
              _buildPriceRow('JUMLA:', calculateTotalPrice(_selectedQuantity), isBold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, int amount, {bool isBold = false}) {
    final formattedAmount = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.blue : Colors.black87,
            ),
          ),
          Text(
            'TSh $formattedAmount',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.blue : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return Column(
      children: [
        // Address Selection
        RadioListTile<bool>(
          title: const Text('Tumia anwani yangu iliyosajiliwa'),
          subtitle: const Text('Inatumia anwani ya kawaida ya kupelekea'),
          value: false,
          groupValue: _useAlternativeAddress,
          onChanged: (value) {
            setState(() {
              _useAlternativeAddress = value!;
            });
          },
        ),
        
        RadioListTile<bool>(
          title: const Text('Tumia anwani nyingine'),
          subtitle: const Text('Toa mahali mbadala pa kufikishia'),
          value: true,
          groupValue: _useAlternativeAddress,
          onChanged: (value) {
            setState(() {
              _useAlternativeAddress = value!;
            });
          },
        ),
        
        if (_useAlternativeAddress) ...[
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Jina la Mtaa',
            controller: _streetController,
            prefixIcon: Icons.location_on_outlined,
            hintText: 'Mfano: Mtaa wa Kisutu - Main Road',
            validator: (value) {
              if (_useAlternativeAddress && (value == null || value.isEmpty)) {
                return 'Tafadhali jaza jina la mtaa';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Mahali Pa Kujulikana',
            controller: _landmarkController,
            prefixIcon: Icons.flag_outlined,
            hintText: 'Mfano: Karibu na Tanesco pole',
            validator: (value) {
              if (_useAlternativeAddress && (value == null || value.isEmpty)) {
                return 'Tafadhali jaza mahali pa kujulikana';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Namba ya Jengo/Nyumba',
            controller: _houseController,
            prefixIcon: Icons.home_outlined,
            hintText: 'Mfano: House No. 45',
            validator: (value) {
              if (_useAlternativeAddress && (value == null || value.isEmpty)) {
                return 'Tafadhali jaza namba ya jengo';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Maelezo kwa Mtoa Huduma (Hiari)',
            controller: _notesController,
            prefixIcon: Icons.note_outlined,
            hintText: 'Mfano: Lori inaweza kusimama barabarani, nitaishiwa hapa',
            maxLines: 3,
          ),
        ],
      ],
    );
  }

  Widget _buildTimeStep() {
    return Column(
      children: [
        const Text(
          'Chagua wakati wa usafirishaji',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        
        RadioListTile<bool>(
          title: const Text('Kwa Haraka Sasa Hivi (ASAP)'),
          subtitle: const Text('Maji yatapelekwa mapema iwezekanavyo'),
          value: true,
          groupValue: _isAsapDelivery,
          onChanged: (value) {
            setState(() {
              _isAsapDelivery = value!;
            });
          },
        ),
        
        RadioListTile<bool>(
          title: const Text('Panga kwa muda baadaye'),
          subtitle: Text(_scheduledDateTime != null 
              ? '${_scheduledDateTime!.day}/${_scheduledDateTime!.month}/${_scheduledDateTime!.year} ${_scheduledDateTime!.hour}:${_scheduledDateTime!.minute.toString().padLeft(2, '0')}'
              : 'Chagua tarehe na saa'),
          value: false,
          groupValue: _isAsapDelivery,
          onChanged: (value) {
            setState(() {
              _isAsapDelivery = value!;
              if (!value) {
                _showDateTimePicker();
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      children: [
        const Text(
          'Chagua njia ya malipo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        
        RadioListTile<String>(
          title: const Text('Malipo kwa Pesa (Cash on Delivery)'),
          subtitle: const Text('Lipa unapopokea maji'),
          value: 'cash',
          groupValue: _paymentMethod,
          onChanged: (value) {
            setState(() {
              _paymentMethod = value!;
            });
          },
        ),
        
        RadioListTile<String>(
          title: const Text('Malipo ya Simu (M-Pesa, Tigo Pesa, Airtel Money)'),
          subtitle: const Text('Utakuja kuwekwa baadaye'),
          value: 'mobile',
          groupValue: _paymentMethod,
          onChanged: (value) {
            setState(() {
              _paymentMethod = value!;
            });
          },
          enabled: false, // Disable for now as it's future integration
        ),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Malipo ya simu yatakuja yakopo baadaye. Kwa sasa tumia malipo kwa pesa.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    final totalPrice = calculateTotalPrice(_selectedQuantity);
    final formattedTotal = totalPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return Column(
      children: [
        // Order Summary Card
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
                'MUHTASARI WA ORDER',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow('Kiasi:', '$_selectedQuantity Lita'),
              _buildSummaryRow('Bei ya Maji:', 'TSh ${calculateWaterCost(_selectedQuantity)}'),
              _buildSummaryRow('Gharama ya Usafirishaji:', 'TSh ${calculateDeliveryFee(_selectedQuantity)}'),
              const Divider(),
              _buildSummaryRow('JUMLA:', 'TSh $formattedTotal', isBold: true),
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              
              const Text(
                'MAHALI PA KUFIKISHIA',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_useAlternativeAddress) ...[
                _buildSummaryRow('Mtaa:', _streetController.text),
                _buildSummaryRow('Mahali Pa Kujulikana:', _landmarkController.text),
                _buildSummaryRow('Namba ya Jengo:', _houseController.text),
                if (_notesController.text.isNotEmpty)
                  _buildSummaryRow('Maelezo:', _notesController.text),
              ] else ...[
                _buildSummaryRow('Anwani:', 'Anwani yako iliyosajiliwa'),
              ],
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              
              const Text(
                'WAKATI NA MALIPO',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildSummaryRow('Wakati:', _isAsapDelivery ? 'Kwa Haraka Sasa Hivi' : 'Pangwa kwa muda'),
              _buildSummaryRow('Malipo:', _paymentMethod == 'cash' ? 'Kwa Pesa (Cash)' : 'Malipo ya Simu'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomQuantityDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kiasi Maalum'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Weka kiasi cha lita unachohitaji:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kiasi (lita)',
                border: OutlineInputBorder(),
                hintText: 'Mfano: 250',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () {
              final liters = int.tryParse(controller.text);
              if (liters != null && liters > 0 && liters <= 10000) {
                setState(() {
                  _selectedQuantity = liters;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tafadhali weka kiasi sahihi (1-10000 lita)'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Thibitisha'),
          ),
        ],
      ),
    );
  }

  void _showDateTimePicker() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 2))),
      );
      
      if (time != null) {
        setState(() {
          _scheduledDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _handlePlaceOrder() async {
    if (_currentStep < _getSteps().length - 1) {
      setState(() {
        _currentStep++;
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show loading and place order
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Inaweka order...'),
          ],
        ),
      ),
    );

    // TODO: Implement actual order placement logic
    await Future.delayed(const Duration(seconds: 2));
    
    Navigator.pop(context); // Close loading dialog
    
    // Show success message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('ORDER IMEWEKWA!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #: WTR-20260315-001'),
            SizedBox(height: 8),
            Text('Status: Inatafuta vendor...'),
            SizedBox(height: 8),
            Text('Utapata taarifa wakati vendor atakapokubali order.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
            },
            child: const Text('Sawa'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // TODO: Navigate to order tracking
            },
            child: const Text('Fuatilia Order'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weka Order ya Maji'),
        backgroundColor: Colors.blue,
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
                    onStepContinue: _handlePlaceOrder,
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
                                    ? 'WEKA ORDER' 
                                    : 'ENDAYE',
                                onPressed: details.onStepContinue,
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
