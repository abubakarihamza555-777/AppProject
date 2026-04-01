import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../../../modules/auth/models/user_model.dart';
import '../../../modules/vendor/models/vendor_model.dart';
import '../../../shared/mixins/loading_mixin.dart';
import '../../../shared/mixins/error_handler_mixin.dart';

class UserManagementController extends ChangeNotifier
    with LoadingMixin, ErrorHandlerMixin {
  final AdminService _adminService;

  List<UserModel> _users = [];
  List<VendorModel> _vendors = [];
  List<VendorModel> _pendingVendors = [];

  UserManagementController({AdminService? adminService})
      : _adminService = adminService ?? AdminService();

  // Getters
  List<UserModel> get users => _users;
  List<VendorModel> get vendors => _vendors;
  List<VendorModel> get pendingVendors => _pendingVendors;

  Future<void> loadUsers() async {
    setLoading(true);
    clearError();

    try {
      _users = await _adminService.getAllUsers();
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadVendors() async {
    setLoading(true);
    clearError();

    try {
      _vendors = await _adminService.getAllVendors();
      _pendingVendors = _vendors.where((v) => !v.isVerified).toList();
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> approveVendor(VendorModel vendor) async {
    setLoading(true);
    try {
      await _adminService.approveVendor(vendor.id);
      _pendingVendors.removeWhere((v) => v.id == vendor.id);
      final index = _vendors.indexWhere((v) => v.id == vendor.id);
      if (index != -1) {
        _vendors[index] = _vendors[index].copyWith(isVerified: true);
      }
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> suspendUser(UserModel user) async {
    setLoading(true);
    try {
      await _adminService.suspendUser(user.id);
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = _users[index].copyWith(isActive: false);
      }
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> activateUser(UserModel user) async {
    setLoading(true);
    try {
      await _adminService.activateUser(user.id);
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = _users[index].copyWith(isActive: true);
      }
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  void filterUsers(String query) {
    // Implement search/filter logic
    notifyListeners();
  }
} 
