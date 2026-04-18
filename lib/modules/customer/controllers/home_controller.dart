import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../../vendor/services/vendor_service.dart';
import '../../auth/controllers/auth_controller.dart';

class HomeController extends ChangeNotifier {
  String userName = 'Customer';
  List<DeliveryService> deliveryServices = [];
  List<OrderModel> recentOrders = [];
  List<Map<String, dynamic>> availableVendors = [];
  bool isLoading = false;
  bool isLoadingVendors = false;
  int? customerDistrictId;
  int? customerWardId;
  String? customerDistrictName;
  static const int pricePerLiter = 100; // 1L = 100 TZS
  static const double adminCommissionPercentage = 0.10; // 10% admin commission

  final VendorService _vendorService = VendorService();

  Future<void> loadDeliveryServices() async {
    deliveryServices = [
      DeliveryService(
        id: 'towable',
        name: 'Towable Browser',
        minCapacity: 400,
        maxCapacity: 2000,
        description: 'Perfect for residential delivery',
        icon: 'agriculture',
        basePrice: 0, // Price calculated dynamically
      ),
      DeliveryService(
        id: 'medium_truck',
        name: 'Medium Truck',
        minCapacity: 3000,
        maxCapacity: 5000,
        description: 'Ideal for small businesses',
        icon: 'local_shipping',
        basePrice: 0, // Price calculated dynamically
      ),
      DeliveryService(
        id: 'heavy_truck',
        name: 'Heavy Duty Truck',
        minCapacity: 8000,
        maxCapacity: 16000,
        description: 'Best for large events and construction',
        icon: 'airport_shuttle',
        basePrice: 0, // Price calculated dynamically
      ),
    ];
    notifyListeners();
  }

  Future<void> loadRecentOrders() async {
    isLoading = true;
    notifyListeners();

    try {
      final authController = AuthController();
      await authController.initialize();
      final userId = authController.currentUser?.id;

      if (userId != null) {
        final orderService = OrderService();
        recentOrders = await orderService.getCustomerOrders(userId);
      }
    } catch (e) {
      print('Error loading recent orders: $e');
      recentOrders = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Load vendors based on customer location
  Future<void> loadVendorsByLocation({int? districtId, int? wardId}) async {
    customerDistrictId = districtId;
    customerWardId = wardId;

    // Set district name from districts list
    if (districtId != null) {
      final district = districts.firstWhere(
        (d) => d['id'] == districtId,
        orElse: () => {'name': 'Unknown'},
      );
      customerDistrictName = district['name'] as String?;
    }

    isLoadingVendors = true;
    notifyListeners();

    try {
      // Fetch real vendors from database
      final vendors = await _vendorService.getAllVendors();

      // Convert vendor models to maps for UI compatibility and filter by active/verified
      availableVendors = vendors
          .where((vendor) => vendor.isActive && vendor.isVerified)
          .map((vendor) => {
                'id': vendor.id,
                'business_name': vendor.businessName,
                'users': {
                  'full_name':
                      vendor.businessName, // Use business name as display name
                  'phone': vendor.businessPhone,
                  'profile_image': vendor.profileImage,
                },
                'rating': vendor.rating,
                'total_deliveries': vendor.totalDeliveries,
                'business_address': vendor.businessAddress,
                'service_areas': [], // TODO: Add service areas to vendor model
                'vehicle_type': 'medium_truck', // Default vehicle type
                'min_capacity': 3000, // Default capacity
                'max_capacity': 5000, // Default capacity
                'is_active': vendor.isActive,
                'is_verified': vendor.isVerified,
              })
          .toList();

      // Filter by location if specified (currently all vendors since service_areas not implemented)
      if (districtId != null) {
        // For now, keep all vendors. In future, filter by service_areas
        // availableVendors = availableVendors.where((vendor) {
        //   final serviceAreas = vendor['service_areas'] as List<dynamic>? ?? [];
        //   return serviceAreas.contains(districtId);
        // }).toList();
      }
    } catch (e) {
      print('Error loading vendors: $e');
      availableVendors = [];
    } finally {
      isLoadingVendors = false;
      notifyListeners();
    }
  }

  // Check if vendor can handle the requested quantity
  bool canVendorHandleQuantity(
      Map<String, dynamic> vendor, int requiredLiters) {
    final minCapacity = vendor['min_capacity'] as int? ?? 0;
    final maxCapacity = vendor['max_capacity'] as int? ?? 0;
    return requiredLiters >= minCapacity && requiredLiters <= maxCapacity;
  }

  // Get filtered vendors based on quantity requirement
  List<Map<String, dynamic>> getVendorsForQuantity(int requiredLiters) {
    return availableVendors
        .where((vendor) => canVendorHandleQuantity(vendor, requiredLiters))
        .toList();
  }

  // Get vehicle capacity info
  Map<String, dynamic> getVehicleCapacityInfo(String vehicleType) {
    final capacities = {
      'towable': {'min': 400, 'max': 2000, 'name': 'Towable Browser'},
      'medium_truck': {'min': 3000, 'max': 5000, 'name': 'Medium Truck'},
      'heavy_truck': {'min': 8000, 'max': 16000, 'name': 'Heavy Duty Truck'},
    };
    return capacities[vehicleType] ?? {'min': 0, 'max': 0, 'name': 'Unknown'};
  }

  // Get customer location display
  String getCustomerLocationDisplay() {
    if (customerDistrictId != null && customerWardId != null) {
      final districtName = districts.firstWhere(
        (d) => d['id'] == customerDistrictId,
        orElse: () => {'name': 'Unknown'},
      )['name'];
      final wardName = wards.firstWhere(
        (w) => w['id'] == customerWardId,
        orElse: () => {'name': 'Unknown'},
      )['name'];
      return '$wardName, $districtName';
    }
    return 'Dar es Salaam'; // Default to city instead of 'Location not set'
  }

  // Helper methods for location data
  static const List<Map<String, dynamic>> districts = [
    {'id': 1, 'name': 'Ilala'},
    {'id': 2, 'name': 'Temeke'},
  ];

  static const List<Map<String, dynamic>> wards = [
    {'id': 1, 'name': 'Kariakoo'},
    {'id': 2, 'name': 'Upanga'},
    {'id': 3, 'name': 'Tandika'},
    {'id': 4, 'name': 'Chang\'ombe'},
  ];

  // Calculate total price with admin commission
  double calculateTotalPrice(int liters) {
    double waterCost = liters * pricePerLiter.toDouble();
    double adminCommission = waterCost * adminCommissionPercentage;
    return waterCost + adminCommission;
  }

  // Get admin commission amount
  double getAdminCommission(int liters) {
    return (liters * pricePerLiter.toDouble()) * adminCommissionPercentage;
  }

  // Get vendor earnings (water cost minus admin commission)
  double getVendorEarnings(int liters) {
    return (liters * pricePerLiter.toDouble()) *
        (1 - adminCommissionPercentage);
  }
}

class DeliveryService {
  final String id;
  final String name;
  final int minCapacity;
  final int maxCapacity;
  final String description;
  final String icon;
  final int basePrice;

  DeliveryService({
    required this.id,
    required this.name,
    required this.minCapacity,
    required this.maxCapacity,
    required this.description,
    required this.icon,
    required this.basePrice,
  });

  // Calculate price based on liters
  double getPrice(int liters) {
    return liters * HomeController.pricePerLiter.toDouble();
  }

  // Get price range
  String getPriceRange() {
    int minPrice = minCapacity * HomeController.pricePerLiter;
    int maxPrice = maxCapacity * HomeController.pricePerLiter;
    return 'TZS ${minPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} - ${maxPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }
}
