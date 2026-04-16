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
  List<OrderModel> _recentOrders = [];
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  int get incomingOrdersCount => _incomingOrdersCount;
  int get activeDeliveriesCount => _activeDeliveriesCount;
  double get todayEarnings => _todayEarnings;
  double get totalEarnings => _totalEarnings;
  double get pendingEarnings => _pendingEarnings;
  List<OrderModel> get recentOrders => _recentOrders;
  String? get errorMessage => _errorMessage;

  // Get real vendor ID from AuthController
  Future<String?> _getCurrentVendorId() async {
    try {
      final authController = AuthController();
      await authController.initialize();
      
      // Wait a bit for auth to fully initialize if needed
      int retries = 0;
      while (authController.currentUser == null && retries < 5) {
        await Future.delayed(const Duration(milliseconds: 200));
        await authController.initialize();
        retries++;
      }
      
      final userId = authController.currentUser?.id;
      
      if (userId == null) {
        print('❌ No authenticated user found after $retries retries');
        return null;
      }
      
      print('✅ Found user ID: $userId');
      
      final vendor = await _vendorService.getVendorByUserId(userId);
      if (vendor == null) {
        print('❌ No vendor profile found for user: $userId');
        return null;
      }
      
      print('✅ Found vendor ID: ${vendor.id}');
      return vendor.id;
      
    } catch (e) {
      print('❌ Error getting vendor ID: $e');
      return null;
    }
  }
  
  Future<void> loadDashboardData() async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      // Initialize auth and wait for it
      final authController = AuthController();
      await authController.initialize();
      
      // Retry logic for auth initialization
      int retries = 0;
      while (authController.currentUser == null && retries < 5) {
        print('⏳ Waiting for auth to initialize... (attempt ${retries + 1})');
        await Future.delayed(const Duration(milliseconds: 300));
        await authController.initialize();
        retries++;
      }
      
      if (authController.currentUser == null) {
        throw Exception('No authenticated user found after initialization');
      }
      
      print('✅ Auth initialized, user: ${authController.currentUser?.email}');
      
      final vendorId = await _getCurrentVendorId();
      if (vendorId == null) {
        throw Exception('No vendor profile found. Please complete your vendor profile first.');
      }
      
      print('📊 Loading dashboard data for vendor: $vendorId');
      
      // Load all data in parallel for better performance
      final results = await Future.wait([
        _vendorService.getIncomingOrders(vendorId),
        _vendorService.getActiveDeliveries(vendorId),
        _vendorService.getVendorOrders(vendorId),
        _earningsService.getTotalEarnings(vendorId),
        _earningsService.getPendingEarnings(vendorId),
        _vendorService.getTodayEarnings(vendorId),
      ]);
      
      final incomingOrders = results[0] as List<OrderModel>;
      final activeDeliveries = results[1] as List<OrderModel>;
      final allOrders = results[2] as List<OrderModel>;
      _totalEarnings = results[3] as double;
      _pendingEarnings = results[4] as double;
      _todayEarnings = results[5] as double;
      
      _incomingOrdersCount = incomingOrders.length;
      _activeDeliveriesCount = activeDeliveries.length;
      _recentOrders = allOrders.take(5).toList();
      
      print('✅ Dashboard data loaded:');
      print('   - Incoming orders: $_incomingOrdersCount');
      print('   - Active deliveries: $_activeDeliveriesCount');
      print('   - Today earnings: $_todayEarnings');
      print('   - Total earnings: $_totalEarnings');
      
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Error loading dashboard data: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }
  
  void _setLoading(bool value) {
    // Use WidgetsBinding to avoid calling during build
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