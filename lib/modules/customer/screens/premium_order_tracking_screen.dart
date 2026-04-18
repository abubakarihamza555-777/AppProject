import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/helpers.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import '../../../config/routes/app_routes.dart';

class PremiumOrderTrackingScreen extends StatefulWidget {
  const PremiumOrderTrackingScreen({super.key});

  @override
  State<PremiumOrderTrackingScreen> createState() =>
      _PremiumOrderTrackingScreenState();
}

class _PremiumOrderTrackingScreenState extends State<PremiumOrderTrackingScreen>
    with TickerProviderStateMixin {
  String? _orderId;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  // Real data from database
  OrderModel? _order;
  Map<String, dynamic>? _vendorDetails;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get order ID from arguments - safe to use context here
    if (_orderId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _orderId = args;
      }
    }

    // Load data after dependencies are ready - safe to use Provider
    if (_orderId != null && _isLoading) {
      _loadOrderData();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderData() async {
    if (_orderId == null) {
      setState(() {
        _errorMessage = 'No order ID provided';
        _isLoading = false;
      });
      return;
    }

    try {
      final orderController =
          Provider.of<OrderController>(context, listen: false);
      await orderController.getOrderById(_orderId!);

      final order = orderController.currentOrder;
      if (order != null) {
        setState(() {
          _order = order;
          _vendorDetails = order.vendorDetails;
          _isLoading = false;
        });

        // Load vendor details separately if needed
        await _loadVendorDetails(order.vendorId);
      } else {
        setState(() {
          _errorMessage = 'Order not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading order: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVendorDetails(String vendorId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('vendors')
          .select('*, users(full_name, phone)')
          .eq('id', vendorId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _vendorDetails = response;
        });
      }
    } catch (e) {
      print('Error loading vendor details: $e');
    }
  }

  String _getStatusText(String status) {
    final statusMap = {
      'placed': 'Order Placed',
      'confirmed': 'Vendor Confirmed',
      'preparing': 'Preparing Water',
      'out_for_delivery': 'Out for Delivery',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
    };
    return statusMap[status] ?? status;
  }

  String _getStatusDescription(String status) {
    final descMap = {
      'placed': 'Your order has been received',
      'confirmed': 'Vendor has accepted your order',
      'preparing': 'Your water is being prepared',
      'out_for_delivery': 'Your water is on the way',
      'delivered': 'Your water has been delivered',
      'cancelled': 'Order was cancelled',
    };
    return descMap[status] ?? 'Processing';
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'placed':
        return Icons.receipt;
      case 'confirmed':
        return Icons.thumb_up;
      case 'preparing':
        return Icons.water_drop;
      case 'out_for_delivery':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'placed':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'out_for_delivery':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  double _getProgressValue(String status) {
    switch (status) {
      case 'placed':
        return 0.2;
      case 'confirmed':
        return 0.4;
      case 'preparing':
        return 0.6;
      case 'out_for_delivery':
        return 0.8;
      case 'delivered':
        return 1.0;
      default:
        return 0.0;
    }
  }

  List<Map<String, dynamic>> _getStatusSteps() {
    final steps = [
      {'status': 'placed', 'title': 'Order Placed', 'icon': Icons.receipt},
      {'status': 'confirmed', 'title': 'Confirmed', 'icon': Icons.thumb_up},
      {'status': 'preparing', 'title': 'Preparing', 'icon': Icons.water_drop},
      {
        'status': 'out_for_delivery',
        'title': 'Out for Delivery',
        'icon': Icons.local_shipping
      },
      {'status': 'delivered', 'title': 'Delivered', 'icon': Icons.check_circle},
    ];

    final currentStatus = _order?.status ?? 'placed';
    final currentIndex = steps.indexWhere((s) => s['status'] == currentStatus);

    return steps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      final isCompleted = index <= currentIndex;
      final isCurrent = index == currentIndex;

      return {
        ...step,
        'isCompleted': isCompleted,
        'isCurrent': isCurrent,
        'color': isCompleted ? Colors.green : Colors.grey,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_order == null) {
      return const Scaffold(
        body: Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPremiumHeader(),
            _buildProgressSection(),
            _buildLiveTrackingSection(),
            _buildOrderStatusSection(),
            _buildVendorInfoSection(),
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    final isDelivered = _order?.status == 'delivered';
    final headerColor =
        isDelivered ? Colors.green.shade700 : Colors.blue.shade700;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [headerColor, headerColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Track Your Order',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${_order!.shortId}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Placed: ${Helpers.formatDate(_order!.orderDate)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_order!.status)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(_order!.status),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    final progress = _getProgressValue(_order!.status);
    final statusColor = _getStatusColor(_order!.status);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Progress',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTrackingSection() {
    final statusColor = _getStatusColor(_order!.status);
    final isOutForDelivery = _order!.status == 'out_for_delivery';
    final isDelivered = _order!.status == 'delivered';

    return FadeTransition(
      opacity: _slideController,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isDelivered
                                ? Icons.check_circle
                                : Icons.location_on,
                            color: statusColor,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDelivered ? 'Order Delivered!' : 'Live Tracking',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          isDelivered
                              ? 'Your water has been delivered successfully'
                              : (isOutForDelivery
                                  ? 'Your water is on the way!'
                                  : 'Waiting for vendor confirmation'),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Map placeholder with status
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.1),
                      Colors.grey.shade100
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isDelivered ? Icons.check_circle : Icons.local_shipping,
                        size: 48,
                        color: statusColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isDelivered
                            ? 'Delivery Completed'
                            : (isOutForDelivery
                                ? 'Driver En Route'
                                : 'Preparing for Dispatch'),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                      if (isOutForDelivery && !isDelivered) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Estimated delivery: 30-45 minutes',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Delivery info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.1),
                      statusColor.withValues(alpha: 0.05)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: statusColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Address',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            _order!.deliveryAddress,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStatusSection() {
    final statusSteps = _getStatusSteps();

    return FadeTransition(
      opacity: _slideController,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.timeline, color: Colors.orange.shade700),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Order Timeline',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...statusSteps.map((step) => _buildStatusStep(
                    title: step['title'] as String,
                    icon: _getStatusIcon(step['status'] as String),
                    isCompleted: step['isCompleted'] as bool,
                    isCurrent: step['isCurrent'] as bool,
                    color: step['color'] as Color,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusStep({
    required String title,
    required IconData icon,
    required bool isCompleted,
    required bool isCurrent,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCompleted
                    ? color.withValues(alpha: 0.2)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCompleted ? color : Colors.grey.shade300,
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: Icon(
                icon,
                color: isCompleted ? color : Colors.grey.shade500,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCompleted
                          ? Colors.grey.shade800
                          : Colors.grey.shade500,
                    ),
                  ),
                  if (isCurrent && _order != null)
                    Text(
                      _getStatusDescription(_order!.status),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            if (isCompleted) Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
        if (title != 'Delivered')
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Container(
              height: 30,
              width: 2,
              color: isCompleted ? color : Colors.grey.shade300,
            ),
          ),
      ],
    );
  }

  Widget _buildVendorInfoSection() {
    final vendorName = _vendorDetails?['business_name'] ??
        _order?.vendorDetails?['business_name'] ??
        'Vendor';
    final vendorRating =
        (_vendorDetails?['rating'] ?? _order?.vendorDetails?['rating'] ?? 0.0)
            .toDouble();
    final vendorPhone = _vendorDetails?['business_phone'] ??
        _order?.vendorDetails?['phone'] ??
        'Not available';

    return FadeTransition(
      opacity: _slideController,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.store, color: Colors.purple.shade700),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Vendor Information',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade50, Colors.purple.shade100],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.purple.shade200,
                          child: Icon(Icons.store,
                              color: Colors.purple.shade700, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vendorName,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                'Water Delivery Vendor',
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoChip(
                            Icons.star,
                            vendorRating.toString(),
                            Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoChip(
                            Icons.local_shipping,
                            'Water Delivery',
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Call vendor
                        if (vendorPhone != 'Not available') {
                          Helpers.makePhoneCall(vendorPhone);
                        }
                      },
                      icon: const Icon(Icons.phone),
                      label: Text(
                        'Call Vendor',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to chat
                      },
                      icon: const Icon(Icons.chat),
                      label: Text(
                        'Message',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_order!.status == 'delivered') {
      return Container(
        margin: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home),
                label: const Text('Back to Home'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.requestWater);
                },
                icon: const Icon(Icons.repeat),
                label: const Text('Order Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Back to Orders'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
