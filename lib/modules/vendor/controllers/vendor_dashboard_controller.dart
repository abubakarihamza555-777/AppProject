import 'package:flutter/material.dart';
import '../services/vendor_service.dart';
import '../services/earnings_service.dart';
import '../../customer/models/order_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../config/supabase/supabase_client.dart';

class VendorDashboardController extends ChangeNotifier {
  final VendorService _vendorService = VendorService();
  final EarningsService _earningsService = EarningsService();
  
  bool _isLoading = false;
  int _incomingOrdersCount = 0;
  int _activeDeliveriesCount = 0;
  double _todayEarnings = 0;
  double _totalEarnings = 0;
  double _pendingEarnings = 0;
  List<OrderModel> _recentOrders = [];
  
  bool get isLoading => _isLoading;
  int get incomingOrdersCount => _incomingOrdersCount;
  int get activeDeliveriesCount => _activeDeliveriesCount;
  double get todayEarnings => _todayEarnings;
  double get totalEarnings => _totalEarnings;
  double get pendingEarnings => _pendingEarnings;
  List<OrderModel> get recentOrders => _recentOrders;

  // Get real vendor ID from AuthController
  Future<String> _getCurrentVendorId() async {
    final authController = AuthController();
    final userId = authController.currentUser?.id;
    
    if (userId == null) {
      throw Exception('No authenticated user found');
    }
    
    final vendor = await _vendorService.getVendorByUserId(userId!);
    if (vendor == null) {
      throw Exception('No vendor profile found for user');
    }
    
    return vendor.id;
  }
  
  Future<void> loadDashboardData() async {
    _setLoading(true);
    
    try {
      final vendorId = await _getCurrentVendorId();
      final incomingOrders = await _vendorService.getIncomingOrders(vendorId);
      final activeDeliveries = await _vendorService.getActiveDeliveries(vendorId);
      final allOrders = await _vendorService.getVendorOrders(vendorId);
      
      _incomingOrdersCount = incomingOrders.length;
      _activeDeliveriesCount = activeDeliveries.length;
      _totalEarnings = await _earningsService.getTotalEarnings(vendorId);
      _pendingEarnings = await _earningsService.getPendingEarnings(vendorId);
      _recentOrders = allOrders.take(5).toList();
      
      // Calculate today's earnings
      final today = DateTime.now();
      _todayEarnings = 0;
      for (var order in allOrders) {
        if (order.orderDate.day == today.day &&
            order.orderDate.month == today.month &&
            order.orderDate.year == today.year &&
            order.status == 'delivered') {
          _todayEarnings += order.totalPrice;
        }
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
