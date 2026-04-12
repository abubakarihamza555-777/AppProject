import 'dart:async';
import 'package:flutter/material.dart';
import '../services/vendor_service.dart';
import '../../customer/models/order_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../config/supabase/supabase_client.dart';

class VendorOrderController extends ChangeNotifier {
  final VendorService _vendorService = VendorService();
  
  bool _isLoading = false;
  List<OrderModel> _incomingOrders = [];
  List<OrderModel> _activeDeliveries = [];
  List<OrderModel> _allOrders = [];
  OrderModel? _selectedOrder;
  StreamSubscription? _orderSubscription;
  
  bool get isLoading => _isLoading;
  List<OrderModel> get incomingOrders => _incomingOrders;
  List<OrderModel> get activeDeliveries => _activeDeliveries;
  List<OrderModel> get allOrders => _allOrders;
  OrderModel? get selectedOrder => _selectedOrder;

  // Get real vendor ID from AuthController
  Future<String> _getCurrentVendorId() async {
    final authController = AuthController();
    final userId = authController.currentUser?.id;
    
    if (userId == null) {
      throw Exception('No authenticated user found');
    }
    
    final vendor = await _vendorService.getVendorByUserId(userId);
    if (vendor == null) {
      throw Exception('No vendor profile found for user');
    }
    
    return vendor.id;
  }
  
  Future<void> loadOrders([String? vendorId]) async {
    _setLoading(true);
    
    try {
      if (vendorId != null) {
        _incomingOrders = await _vendorService.getIncomingOrders(vendorId);
        _activeDeliveries = await _vendorService.getActiveDeliveries(vendorId);
        _allOrders = await _vendorService.getVendorOrders(vendorId);
      } else {
        final currentVendorId = await _getCurrentVendorId();
        _incomingOrders = await _vendorService.getIncomingOrders(currentVendorId);
        _activeDeliveries = await _vendorService.getActiveDeliveries(currentVendorId);
        _allOrders = await _vendorService.getVendorOrders(currentVendorId);
            }
    } catch (e) {
      print('Error loading orders: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> acceptOrder(String orderId) async {
    _setLoading(true);
    
    try {
      final success = await _vendorService.acceptOrder(orderId);
      if (success) {
        // Remove from incoming orders
        _incomingOrders.removeWhere((order) => order.id == orderId);
      }
      return success;
    } catch (e) {
      print('Error accepting order: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> rejectOrder(String orderId, {String? reason}) async {
    _setLoading(true);
    
    try {
      final success = await _vendorService.rejectOrder(orderId, reason: reason);
      if (success) {
        _incomingOrders.removeWhere((order) => order.id == orderId);
      }
      return success;
    } catch (e) {
      print('Error rejecting order: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> updateDeliveryStatus(String orderId, String status) async {
    _setLoading(true);
    
    try {
      final success = await _vendorService.updateDeliveryStatus(orderId, status);
      return success;
    } catch (e) {
      print('Error updating delivery status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  void selectOrder(OrderModel order) {
    _selectedOrder = order;
    notifyListeners();
  }

  Future<void> getOrderById(String orderId) async {
    _setLoading(true);
    try {
      // First try to get from DB directly
      final order = await _vendorService.getOrderById(orderId);
      if (order != null) {
        _selectedOrder = order;
      } else {
        _selectedOrder = null;
      }
    } catch (e) {
      print('Error fetching order: $e');
      _selectedOrder = null;
    } finally {
      _setLoading(false);
    }
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Start listening for new orders
  Future<void> startListeningForOrders() async {
    try {
      final vendorId = await _getCurrentVendorId();
      
      _orderSubscription = SupabaseConfig.client
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('vendor_id', vendorId)
          .listen((event) {
        // Show notification for new orders
        if (event.isNotEmpty) {
          // Check if this is a new order by looking at the first event
          for (final orderData in event) {
            if (orderData['status'] == 'pending' || orderData['status'] == 'placed') {
              _showNewOrderNotification(orderData);
            }
          }
        }
        // Reload orders to update UI
        loadOrders();
      });
    } catch (e) {
      print('Error starting order listener: $e');
    }
  }

  // Stop listening for orders
  void stopListeningForOrders() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
  }

  // Show notification for new order
  void _showNewOrderNotification(Map<String, dynamic> orderData) {
    // This would integrate with your notification service
    print('New order received: ${orderData['id']}');
    // You can integrate with your existing NotificationService here
  }

  @override
  void dispose() {
    stopListeningForOrders();
    super.dispose();
  }
} 
