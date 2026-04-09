import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../localization/language_provider.dart';
import '../../../core/utils/helpers.dart';
import '../controllers/payment_controller.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'mobile_money';
  String _mobileNumber = '';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final controller = Provider.of<PaymentController>(context);
    final order = ModalRoute.of(context)!.settings.arguments as Map;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('payment')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      languageProvider.translate('amount_to_pay'),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Helpers.formatPrice(order['amount']),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Payment Methods
            Text(
              languageProvider.translate('select_payment_method'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Mobile Money Option
            Card(
              child: ListTile(
                title: Row(
                  children: [
                    const Icon(Icons.phone_android, color: Colors.green),
                    const SizedBox(width: 12),
                    Text(languageProvider.translate('mobile_money')),
                  ],
                ),
                subtitle: const Text('M-Pesa, Tigo Pesa, Airtel Money'),
                trailing: Radio<String>(
                  value: 'mobile_money',
                  groupValue: _selectedMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedMethod = value!;
                    });
                  },
                  fillColor: WidgetStateProperty.all(Colors.green),
                ),
                onTap: () {
                  setState(() {
                    _selectedMethod = 'mobile_money';
                  });
                },
              ),
            ),
            
            // Cash Option
            Card(
              child: ListTile(
                title: Row(
                  children: [
                    const Icon(Icons.money, color: Colors.orange),
                    const SizedBox(width: 12),
                    Text(languageProvider.translate('cash')),
                  ],
                ),
                subtitle: const Text('Pay on delivery'),
                trailing: Radio<String>(
                  value: 'cash',
                  groupValue: _selectedMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedMethod = value!;
                    });
                  },
                  fillColor: WidgetStateProperty.all(Colors.orange),
                ),
                onTap: () {
                  setState(() {
                    _selectedMethod = 'cash';
                  });
                },
              ),
            ),
            
            if (_selectedMethod == 'mobile_money') ...[
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: languageProvider.translate('mobile_number'),
                  hintText: 'e.g., 0712345678',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  _mobileNumber = value;
                },
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Pay Button
            CustomButton(
              text: languageProvider.translate('pay_now'),
              onPressed: () {
                if (_isProcessing) return;
                _processPayment(controller, order);
              },
              isLoading: _isProcessing,
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _processPayment(PaymentController controller, Map order) async {
    setState(() {
      _isProcessing = true;
    });
    
    final success = await controller.processPayment(
      orderId: order['orderId'],
      amount: order['amount'],
      method: _selectedMethod,
      mobileNumber: _selectedMethod == 'mobile_money' ? _mobileNumber : null,
    );
    
    setState(() {
      _isProcessing = false;
    });
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/customer/order-confirmation');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Payment failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
