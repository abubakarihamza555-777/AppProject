import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../localization/language_provider.dart';
import '../../../core/utils/helpers.dart';
import '../models/order_model.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final order = ModalRoute.of(context)!.settings.arguments as OrderModel;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('order_confirmed')),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              languageProvider.translate('order_placed_successfully'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            Text(
              languageProvider.translate('order_id'),
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            Text(
              Helpers.formatOrderId(order.id),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Order Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(
                      label: languageProvider.translate('water_type'),
                      value: order.waterType,
                    ),
                    const Divider(),
                    _DetailRow(
                      label: languageProvider.translate('quantity'),
                      value: '${order.quantity} L',
                    ),
                    const Divider(),
                    _DetailRow(
                      label: languageProvider.translate('delivery_address'),
                      value: order.deliveryAddress,
                    ),
                    const Divider(),
                    _DetailRow(
                      label: languageProvider.translate('payment_method'),
                      value: order.paymentMethod,
                    ),
                    const Divider(),
                    _DetailRow(
                      label: languageProvider.translate('total'),
                      value: Helpers.formatPrice(order.totalPrice),
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Buttons
            CustomButton(
              text: languageProvider.translate('track_order'),
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.orderTracking,
                  arguments: order.id,
                );
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: languageProvider.translate('back_to_home'),
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
              },
              isOutlined: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
