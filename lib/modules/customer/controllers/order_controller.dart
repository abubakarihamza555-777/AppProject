import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';

class OrderController extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  
  bool _isLoading = false;
  List<OrderModel> _orders = [];
  OrderModel? _currentOrder;
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  List<OrderModel> get orders => _orders;
  OrderModel? get currentOrder => _currentOrder;
  String? get errorMessage => _errorMessage;
  
  // Create new order
  Future<bool> createOrder({
    required String customerId,
    required String vendorId,
    required String waterType,
    required int quantity,
    required double totalPrice,
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final order = await _orderService.createOrder(
        customerId: customerId,
        vendorId: vendorId,
        waterType: waterType,
        quantity: quantity,
        totalPrice: totalPrice,
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
      );
      
      if (order != null) {
        _currentOrder = order;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Failed to create order';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }
  
  // Get customer orders
  Future<void> getCustomerOrders(String customerId) async {
    _setLoading(true);
    _clearError();
    
    try {
      _orders = await _orderService.getCustomerOrders(customerId);
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }
  
  // Get order by ID
  Future<void> getOrderById(String orderId) async {
    _setLoading(true);
    _clearError();
    
    try {
      _currentOrder = await _orderService.getOrderById(orderId);
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }
  
  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _orderService.updateOrderStatus(orderId, status);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }
  
  // Cancel order
  Future<bool> cancelOrder(String orderId) async {
    return updateOrderStatus(orderId, 'cancelled');
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
}
