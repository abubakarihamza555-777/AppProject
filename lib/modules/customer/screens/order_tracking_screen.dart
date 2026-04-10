import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../localization/language_provider.dart';
import '../../../core/utils/helpers.dart';
import '../../../config/supabase/supabase_client.dart';
import '../controllers/order_controller.dart';
import '../widgets/order_status_timeline.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  String? _orderId;
  String? _estimatedDeliveryTime;
  
  @override
  void initState() {
    super.initState();
    _orderId = ModalRoute.of(context)!.settings.arguments as String?;
    if (_orderId != null) {
      _loadOrder();
    }
  }
  
  Future<void> _loadOrder() async {
    final controller = context.read<OrderController>();
    await controller.getOrderById(_orderId!);
    
    // Fetch real ETA from order_tracking table
    if (_orderId != null) {
      try {
        final tracking = await SupabaseConfig.client
            .from('order_tracking')
            .select('estimated_minutes')
            .eq('order_id', _orderId!)
            .maybeSingle();
        
        if (tracking != null) {
          final estimatedMinutes = tracking['estimated_minutes'] as int?;
          if (estimatedMinutes != null) {
            _estimatedDeliveryTime = '$estimatedMinutes-${estimatedMinutes + 15} minutes';
          } else {
            _estimatedDeliveryTime = 'Calculating...';
          }
        } else {
          _estimatedDeliveryTime = 'Calculating...';
        }
      } catch (e) {
        print('Error fetching tracking info: $e');
        _estimatedDeliveryTime = 'Calculating...';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final controller = Provider.of<OrderController>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('track_order')),
      ),
      body: controller.isLoading
          ? const LoadingIndicator()
          : controller.currentOrder == null
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    languageProvider.translate('order_id'),
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    Helpers.formatOrderId(controller.currentOrder!.id),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    languageProvider.translate('order_date'),
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(Helpers.formatDate(controller.currentOrder!.orderDate)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    languageProvider.translate('total_amount'),
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    Helpers.formatPrice(controller.currentOrder!.totalPrice),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Order Status Timeline
                      OrderStatusTimeline(
                        currentStatus: controller.currentOrder!.status,
                      ),
                      const SizedBox(height: 24),
                      
                      // Delivery Info
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                languageProvider.translate('delivery_address'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(controller.currentOrder!.deliveryAddress),
                              const SizedBox(height: 16),
                              Text(
                                languageProvider.translate('estimated_delivery'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(_estimatedDeliveryTime ?? 'Calculating...'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Contact Vendor Button
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: {
                              'vendorId': controller.currentOrder!.vendorId,
                              'orderId': controller.currentOrder!.id,
                            },
                          );
                        },
                        icon: const Icon(Icons.chat),
                        label: Text(languageProvider.translate('contact_vendor')),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
} 
