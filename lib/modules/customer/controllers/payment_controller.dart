import 'package:flutter/material.dart';
import '../services/payment_service.dart';

class PaymentController extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  
  bool _isProcessing = false;
  String? _errorMessage;
  
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  
  Future<bool> processPayment({
    required String orderId,
    required double amount,
    required String method,
    String? mobileNumber,
  }) async {
    _setProcessing(true);
    _clearError();
    
    try {
      final success = await _paymentService.processPayment(
        orderId: orderId,
        amount: amount,
        method: method,
        mobileNumber: mobileNumber,
      );
      
      _setProcessing(false);
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setProcessing(false);
      return false;
    }
  }
  
  void _setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
} 
