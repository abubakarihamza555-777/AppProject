import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../localization/language_provider.dart';
import '../../../core/utils/helpers.dart';
import '../controllers/vendor_order_controller.dart';
import '../../customer/widgets/order_status_timeline.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  String? _orderId;
  
  @override
  void initState() {
    super.initState();
    _orderId = ModalRoute.of(context)!.settings.arguments as String?;
    if (_orderId != null) {
      _loadOrder();
    }
  }
  
  Future<void> _loadOrder() async {
    final controller = context.read<VendorOrderController>();
    await controller.getOrderById(_orderId!);
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final controller = Provider.of<VendorOrderController>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('order_details')),
      ),
      body: controller.isLoading
          ? const LoadingIndicator()
          : controller.selectedOrder == null
              ? Center(
                  child: Text(languageProvider.translate('order_not_found')),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Order Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _DetailRow(
                                label: languageProvider.translate('order_id'),
                                value: Helpers.formatOrderId(controller.selectedOrder!.id),
                              ),
                              const Divider(),
                              _DetailRow(
                                label: languageProvider.translate('order_date'),
                                value: Helpers.formatDate(controller.selectedOrder!.orderDate),
                              ),
                              const Divider(),
                              _DetailRow(
                                label: languageProvider.translate('payment_method'),
                                value: controller.selectedOrder!.paymentMethod,
                              ),
                              const Divider(),
                              _DetailRow(
                                label: languageProvider.translate('total_amount'),
                                value: Helpers.formatPrice(controller.selectedOrder!.totalPrice),
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Customer Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                languageProvider.translate('customer_details'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _DetailRow(
                                label: languageProvider.translate('name'),
                                value: controller.selectedOrder!.customerDetails?['full_name'] ?? 'N/A',
                              ),
                              const SizedBox(height: 8),
                              _DetailRow(
                                label: languageProvider.translate('phone'),
                                value: controller.selectedOrder!.customerDetails?['phone'] ?? 'N/A',
                              ),
                              const SizedBox(height: 8),
                              _DetailRow(
                                label: languageProvider.translate('address'),
                                value: controller.selectedOrder!.deliveryAddress,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Order Items
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                languageProvider.translate('order_items'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(controller.selectedOrder!.waterType),
                                  Text('${controller.selectedOrder!.quantity} L'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Order Status Timeline
                      OrderStatusTimeline(
                        currentStatus: controller.selectedOrder!.status,
                      ),
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      if (controller.selectedOrder!.status == 'pending')
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: languageProvider.translate('reject'),
                                onPressed: () => _rejectOrder(controller),
                                isOutlined: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomButton(
                                text: languageProvider.translate('accept'),
                                onPressed: () => _acceptOrder(controller),
                              ),
                            ),
                          ],
                        ),
                      if (controller.selectedOrder!.status == 'confirmed')
                        CustomButton(
                          text: languageProvider.translate('start_preparing'),
                          onPressed: () => _updateStatus(controller, 'preparing'),
                        ),
                      if (controller.selectedOrder!.status == 'preparing')
                        CustomButton(
                          text: languageProvider.translate('mark_delivered'),
                          onPressed: () => _updateStatus(controller, 'delivered'),
                        ),
                    ],
                  ),
                ),
    );
  }
  
  Future<void> _acceptOrder(VendorOrderController controller) async {
    final success = await controller.acceptOrder(controller.selectedOrder!.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order accepted'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }
  
  Future<void> _rejectOrder(VendorOrderController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: const Text('Are you sure you want to reject this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final success = await controller.rejectOrder(controller.selectedOrder!.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order rejected'), backgroundColor: Colors.orange),
        );
        Navigator.pop(context);
      }
    }
  }
  
  Future<void> _updateStatus(VendorOrderController controller, String status) async {
    final success = await controller.updateDeliveryStatus(controller.selectedOrder!.id, status);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $status'), backgroundColor: Colors.green),
      );
      _loadOrder();
    }
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
} 
