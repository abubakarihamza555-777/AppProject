import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../localization/language_provider.dart';
import '../../../core/utils/helpers.dart';
import '../controllers/vendor_order_controller.dart';
import '../../customer/models/order_model.dart';
import '../widgets/delivery_status_badge.dart';

class ActiveDeliveriesScreen extends StatefulWidget {
  const ActiveDeliveriesScreen({super.key});

  @override
  State<ActiveDeliveriesScreen> createState() => _ActiveDeliveriesScreenState();
}

class _ActiveDeliveriesScreenState extends State<ActiveDeliveriesScreen> {
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  
  Future<void> _loadOrders() async {
    final controller = context.read<VendorOrderController>();
    await controller.loadOrders(); // Use real vendor ID from controller
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final controller = Provider.of<VendorOrderController>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('active_deliveries')),
      ),
      body: controller.isLoading
          ? const LoadingIndicator()
          : controller.activeDeliveries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delivery_dining,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        languageProvider.translate('no_active_deliveries'),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.activeDeliveries.length,
                    itemBuilder: (context, index) {
                      final order = controller.activeDeliveries[index];
                      return _ActiveDeliveryCard(
                        order: order,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/vendor/order-details',
                            arguments: order.id,
                          );
                        },
                        onUpdateStatus: (status) async {
                          final success = await controller.updateDeliveryStatus(
                            order.id,
                            status,
                          );
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Status updated to $status'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadOrders();
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _ActiveDeliveryCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  final Function(String) onUpdateStatus;

  const _ActiveDeliveryCard({
    required this.order,
    required this.onTap,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Helpers.formatOrderId(order.id),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  DeliveryStatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                order.waterType,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    order.customerDetails?['full_name'] ?? 'Customer',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    Helpers.formatPrice(order.totalPrice),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Status Update Buttons
              if (order.status == 'confirmed')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => onUpdateStatus('preparing'),
                    child: Text(languageProvider.translate('start_preparing')),
                  ),
                ),
              if (order.status == 'preparing')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => onUpdateStatus('out_for_delivery'),
                    child: Text(languageProvider.translate('start_delivery')),
                  ),
                ),
              if (order.status == 'out_for_delivery')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => onUpdateStatus('delivered'),
                    child: Text(languageProvider.translate('mark_delivered')),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
