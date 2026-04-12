import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/widgets/loading_indicator.dart';
import '../../../localization/language_provider.dart';
import '../../../core/utils/helpers.dart';
import '../controllers/vendor_order_controller.dart';
import '../../customer/models/order_model.dart';
import '../../../config/routes/app_routes.dart';

class ActiveDeliveriesScreen extends StatefulWidget {
  const ActiveDeliveriesScreen({super.key});

  @override
  State<ActiveDeliveriesScreen> createState() => _ActiveDeliveriesScreenState();
}

class _ActiveDeliveriesScreenState extends State<ActiveDeliveriesScreen> {
  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    if (!mounted) return;
    final controller = context.read<VendorOrderController>();
    await controller.loadOrders();        // ← Changed to existing method
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final controller = Provider.of<VendorOrderController>(context);
    final isSwahili = languageProvider.currentLocale.languageCode == 'sw';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSwahili ? 'Usafirishaji Unaotoka' : 'Active Deliveries',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: controller.isLoading
          ? const LoadingIndicator()
          : controller.activeDeliveries.isEmpty
              ? _buildEmptyState(isSwahili)
              : RefreshIndicator(
                  onRefresh: _loadDeliveries,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.activeDeliveries.length,
                    itemBuilder: (context, index) {
                      final order = controller.activeDeliveries[index];
                      return _ActiveDeliveryCard(
                        order: order,
                        onUpdateStatus: (status) async {
                          final success = await controller.updateDeliveryStatus(
                            order.id,
                            status,
                          );
                          if (success && mounted) {
                            _showSnackBar(
                              isSwahili
                                  ? 'Status imebadilishwa!'
                                  : 'Status updated!',
                              Colors.green,
                            );
                            _loadDeliveries();
                          }
                        },
                        onTrack: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.orderTracking,
                            arguments: order.id,
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isSwahili) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delivery_dining, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            isSwahili ? 'Hakuna usafirishaji unaotoka' : 'No active deliveries',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSwahili
                ? 'Oda zilizokubaliwa zitaonekana hapa'
                : 'Accepted orders will appear here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadDeliveries,
            icon: const Icon(Icons.refresh),
            label: Text(isSwahili ? 'Funga upya' : 'Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ActiveDeliveryCard extends StatelessWidget {
  final OrderModel order;
  final Function(String) onUpdateStatus;
  final VoidCallback onTrack;

  const _ActiveDeliveryCard({
    required this.order,
    required this.onUpdateStatus,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isSwahili = languageProvider.currentLocale.languageCode == 'sw';

    String getNextStatus() {
      switch (order.status) {
        case 'confirmed':
          return 'preparing';
        case 'preparing':
          return 'out_for_delivery';
        case 'out_for_delivery':
          return 'delivered';
        default:
          return 'preparing';
      }
    }

    String getNextStatusText() {
      switch (order.status) {
        case 'confirmed':
          return isSwahili ? 'ANZA KUANDAA' : 'START PREPARING';
        case 'preparing':
          return isSwahili ? 'ANZA USAFIRISHAJI' : 'START DELIVERY';
        case 'out_for_delivery':
          return isSwahili ? 'WASILISHA' : 'MARK DELIVERED';
        default:
          return isSwahili ? 'SASISHA' : 'UPDATE';
      }
    }

    Color getStatusColor() {
      switch (order.status) {
        case 'confirmed':
          return Colors.orange;
        case 'preparing':
          return Colors.blue;
        case 'out_for_delivery':
          return Colors.purple;
        case 'delivered':
          return Colors.green;
        default:
          return Colors.grey;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: getStatusColor().withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: getStatusColor().withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_shipping,
                        color: getStatusColor(),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Helpers.formatOrderId(order.id),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          Helpers.formatDate(order.orderDate),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: getStatusColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.getStatusText(isSwahili ? 'sw' : 'en'),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Water Order Info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.water_drop,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.waterType,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${order.quantity} Liters',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Helpers.formatPrice(order.totalPrice),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade200,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _getProgressValue(order.status),
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(getStatusColor()),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Progress Steps
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildProgressStep('Confirmed', order.status == 'confirmed' || _isStatusCompleted(order.status, 'confirmed')),
                    _buildProgressStep('Preparing', order.status == 'preparing' || _isStatusCompleted(order.status, 'preparing')),
                    _buildProgressStep('Out for Delivery', order.status == 'out_for_delivery' || _isStatusCompleted(order.status, 'out_for_delivery')),
                    _buildProgressStep('Delivered', order.status == 'delivered'),
                  ],
                ),
                const SizedBox(height: 16),

                // Customer Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.customerDetails?['full_name'] ?? 'Customer',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              order.customerDetails?['phone'] ?? 'No phone',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Delivery Address
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 20, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          order.deliveryAddress,
                          style: GoogleFonts.poppins(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTrack,
                        icon: const Icon(Icons.location_on, size: 18),
                        label: Text(isSwahili ? 'FUATILIA' : 'TRACK'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => onUpdateStatus(getNextStatus()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: getStatusColor(),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(getNextStatusText()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getProgressValue(String status) {
    switch (status) {
      case 'confirmed':
        return 0.25;
      case 'preparing':
        return 0.5;
      case 'out_for_delivery':
        return 0.75;
      case 'delivered':
        return 1.0;
      default:
        return 0.0;
    }
  }

  bool _isStatusCompleted(String currentStatus, String checkStatus) {
    const order = ['confirmed', 'preparing', 'out_for_delivery', 'delivered'];
    final currentIndex = order.indexOf(currentStatus);
    final checkIndex = order.indexOf(checkStatus);
    return currentIndex > checkIndex;
  }

  Widget _buildProgressStep(String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.green : Colors.grey.shade300,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: isActive ? Colors.green : Colors.grey.shade500,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}