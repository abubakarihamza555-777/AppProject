import 'package:flutter/material.dart';
import '../services/vendor_service.dart';
import '../../customer/models/order_model.dart';

class VendorOrderController extends ChangeNotifier {
  final VendorService _vendorService = VendorService();
  
  bool _isLoading = false;
  List<OrderModel> _incomingOrders = [];
  List<OrderModel> _activeDeliveries = [];
  List<OrderModel> _allOrders = [];
  OrderModel? _selectedOrder;
  
  bool get isLoading => _isLoading;
  List<OrderModel> get incomingOrders => _incomingOrders;
  List<OrderModel> get activeDeliveries => _activeDeliveries;
  List<OrderModel> get allOrders => _allOrders;
  OrderModel? get selectedOrder => _selectedOrder;
  
  Future<void> loadOrders(String vendorId) async {
    _setLoading(true);
    
    try {
      _incomingOrders = await _vendorService.getIncomingOrders(vendorId);
      _activeDeliveries = await _vendorService.getActiveDeliveries(vendorId);
      _allOrders = await _vendorService.getVendorOrders(vendorId);
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
      // Try local cache first
      final cached = _allOrders.where((o) => o.id == orderId).toList();
      if (cached.isNotEmpty) {
        _selectedOrder = cached.first;
        return;
      }

      // Fall back: reload and pick
      await loadOrders('temp_vendor_id');
      _selectedOrder = _allOrders.where((o) => o.id == orderId).cast<OrderModel?>().firstWhere(
            (o) => o != null,
            orElse: () => null,
          );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
} 
