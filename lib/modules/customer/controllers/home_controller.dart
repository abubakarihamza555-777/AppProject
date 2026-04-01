import 'package:flutter/material.dart';
import '../models/order_model.dart';

class HomeController extends ChangeNotifier {
  String userName = 'Customer';
  List<String> waterTypes = [];
  List<OrderModel> recentOrders = [];
  bool isLoading = false;

  Future<void> loadWaterTypes() async {
    waterTypes = [
      'Mineral Water',
      'Distilled Water',
      'Spring Water',
      'Alkaline Water',
    ];
    notifyListeners();
  }

  Future<void> loadRecentOrders() async {
    isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    recentOrders = [];
    isLoading = false;
    notifyListeners();
  }
} 
