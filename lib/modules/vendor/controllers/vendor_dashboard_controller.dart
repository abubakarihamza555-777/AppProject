import 'package:flutter/material.dart';
import '../services/vendor_service.dart';
import '../services/earnings_service.dart';
import '../../customer/models/order_model.dart';
import '../../auth/controllers/auth_controller.dart';

class VendorDashboardController extends ChangeNotifier {
  final VendorService _vendorService = VendorService();
  final EarningsService _earningsService = EarningsService();
  
  bool _isLoading = false;
  int _incomingOrdersCount = 0;
  int _activeDeliveriesCount = 0;
  double _todayEarnings = 0;
  double _totalEarnings = 0;
  double _pendingEarnings = 0;
  List<OrderModel> _incomingOrders = [];
  List<OrderModel> _activeDeliveries = [];
  List<OrderModel> _recentOrders = [];
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  int get incomingOrdersCount => _incomingOrdersCount;
  int get activeDeliveriesCount => _activeDeliveriesCount;
  double get todayEarnings => _todayEarnings;
  double get totalEarnings => _totalEarnings;
  double get pendingEarnings => _pendingEarnings;
  List<OrderModel> get recentOrders => _recentOrders;
  List<OrderModel> get incomingOrders => _incomingOrders;
  List<OrderModel> get activeDeliveries => _activeDeliveries;
  String? get errorMessage => _errorMessage;

  Future<String?> _getCurrentVendorId() async {
    try {
      final authController = AuthController();
      await authController.initialize();
      
      int retries = 0;
      while (authController.currentUser == null && retries < 5) {
        await Future.delayed(const Duration(milliseconds: 200));
        await authController.initialize();
        retries++;
      }
      
      final userId = authController.currentUser?.id;
      if (userId == null) return null;
      
      final vendor = await _vendorService.getVendorByUserId(userId);
      return vendor?.id;
    } catch (e) {
      print('Error getting vendor ID: $e');
      return null;
    }
  }
  
  Future<void> loadDashboardData() async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final authController = AuthController();
      await authController.initialize();
      
      int retries = 0;
      while (authController.currentUser == null && retries < 5) {
        await Future.delayed(const Duration(milliseconds: 300));
        await authController.initialize();
        retries++;
      }
      
      if (authController.currentUser == null) {
        throw Exception('No authenticated user found');
      }
      
      final vendorId = await _getCurrentVendorId();
      if (vendorId == null) {
        throw Exception('No vendor profile found');
      }
      
      // Load all data
      final incomingOrders = await _vendorService.getIncomingOrders(vendorId);
      final activeDeliveries = await _vendorService.getActiveDeliveries(vendorId);
      final allOrders = await _vendorService.getVendorOrders(vendorId);
      
      _incomingOrders = incomingOrders;
      _activeDeliveries = activeDeliveries;
      _incomingOrdersCount = incomingOrders.length;
      _activeDeliveriesCount = activeDeliveries.length;
      _recentOrders = allOrders.take(5).toList();
      
      // Load earnings
      _totalEarnings = await _earningsService.getTotalEarnings(vendorId);
      _pendingEarnings = await _earningsService.getPendingEarnings(vendorId);
      _todayEarnings = await _vendorService.getTodayEarnings(vendorId);
      
      print('Dashboard loaded: Incoming: $_incomingOrdersCount, Active: $_activeDeliveriesCount, Today: $_todayEarnings');
      
    } catch (e) {
      _errorMessage = e.toString();
      print('Error loading dashboard: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }
  
  void _setLoading(bool value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isLoading != value) {
        _isLoading = value;
        notifyListeners();
      }
    });
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}