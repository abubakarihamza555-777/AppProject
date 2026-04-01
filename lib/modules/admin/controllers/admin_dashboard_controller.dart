import 'package:flutter/material.dart';
import '../models/admin_stats.dart';
import '../services/admin_service.dart';
import '../../customer/models/order_model.dart';
import '../../auth/models/user_model.dart';
import '../../../shared/mixins/loading_mixin.dart';
import '../../../shared/mixins/error_handler_mixin.dart';

class AdminDashboardController extends ChangeNotifier
    with LoadingMixin, ErrorHandlerMixin {
  final AdminService _adminService;

  AdminStats? _stats;
  List<OrderModel>? _recentOrders;
  List<UserModel>? _recentUsers;

  AdminDashboardController({AdminService? adminService})
      : _adminService = adminService ?? AdminService();

  // Getters
  AdminStats? get stats => _stats;
  List<OrderModel>? get recentOrders => _recentOrders;
  List<UserModel>? get recentUsers => _recentUsers;

  Future<void> loadDashboard() async {
    setLoading(true);
    clearError();

    try {
      await Future.wait([
        _loadStats(),
        _loadRecentOrders(),
        _loadRecentUsers(),
      ]);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> _loadStats() async {
    _stats = await _adminService.getDashboardStats();
    notifyListeners();
  }

  Future<void> _loadRecentOrders() async {
    final allOrders = await _adminService.getAllOrders();
    _recentOrders = allOrders.take(10).toList();
    notifyListeners();
  }

  Future<void> _loadRecentUsers() async {
    final allUsers = await _adminService.getAllUsers();
    _recentUsers = allUsers.take(10).toList();
    notifyListeners();
  }

  void refresh() {
    loadDashboard();
  }
} 
