import 'package:flutter/material.dart';
import '../models/order_model.dart';

class HomeController extends ChangeNotifier {
  String userName = 'Customer';
  List<DeliveryService> deliveryServices = [];
  List<OrderModel> recentOrders = [];
  List<Map<String, dynamic>> availableVendors = [];
  bool isLoading = false;
  bool isLoadingVendors = false;
  int? customerDistrictId;
  int? customerWardId;
  static const int pricePerLiter = 100; // 1L = 100 TZS
  static const double adminCommissionPercentage = 0.10; // 10% admin commission

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

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    recentOrders = [];
    isLoading = false;
    notifyListeners();
  }

  // Load vendors based on customer location
  Future<void> loadVendorsByLocation({int? districtId, int? wardId}) async {
    customerDistrictId = districtId;
    customerWardId = wardId;
    
    if (districtId != null && wardId != null) {
      isLoadingVendors = true;
      notifyListeners();
      
      try {
        // For now, use mock data since we don't have the full service implemented
        availableVendors = [
          {
            'id': '1',
            'business_name': 'Quick Water Delivery',
            'users': {
              'full_name': 'John Doe',
              'phone': '+255 712 345 678',
              'profile_image': null,
            },
            'rating': 4.5,
            'total_deliveries': 150,
            'business_address': 'Ilala, Dar es Salaam',
            'service_areas': [districtId],
            'vehicle_type': 'medium_truck',
          },
          {
            'id': '2', 
            'business_name': 'Fast Water Services',
            'users': {
              'full_name': 'Jane Smith',
              'phone': '+255 713 456 789',
              'profile_image': null,
            },
            'rating': 4.8,
            'total_deliveries': 200,
            'business_address': 'Temeke, Dar es Salaam',
            'service_areas': [districtId],
            'vehicle_type': 'towable',
          },
        ];
      } catch (e) {
        print('Error loading vendors: $e');
        availableVendors = [];
      } finally {
        isLoadingVendors = false;
        notifyListeners();
      }
    } else {
      // Load all vendors if no location specified
      isLoadingVendors = true;
      notifyListeners();
      
      try {
        availableVendors = [
          {
            'id': '1',
            'business_name': 'Quick Water Delivery',
            'users': {
              'full_name': 'John Doe',
              'phone': '+255 712 345 678',
              'profile_image': null,
            },
            'rating': 4.5,
            'total_deliveries': 150,
            'business_address': 'Ilala, Dar es Salaam',
            'service_areas': [1, 2],
            'vehicle_type': 'medium_truck',
          },
          {
            'id': '2',
            'business_name': 'Fast Water Services', 
            'users': {
              'full_name': 'Jane Smith',
              'phone': '+255 713 456 789',
              'profile_image': null,
            },
            'rating': 4.8,
            'total_deliveries': 200,
            'business_address': 'Temeke, Dar es Salaam',
            'service_areas': [1, 2],
            'vehicle_type': 'towable',
          },
          {
            'id': '3',
            'business_name': 'Heavy Water Transport',
            'users': {
              'full_name': 'Mike Johnson',
              'phone': '+255 714 567 890',
              'profile_image': null,
            },
            'rating': 4.2,
            'total_deliveries': 100,
            'business_address': 'Ilala, Dar es Salaam',
            'service_areas': [1, 2],
            'vehicle_type': 'heavy_truck',
          },
        ];
      } catch (e) {
        print('Error loading vendors: $e');
        availableVendors = [];
      } finally {
        isLoadingVendors = false;
        notifyListeners();
      }
    }
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
    return 'Location not set';
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
    return (liters * pricePerLiter.toDouble()) * (1 - adminCommissionPercentage);
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
