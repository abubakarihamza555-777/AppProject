class AppConstants {
  static const String appName = 'Water Delivery';
  static const String appVersion = '1.0.0';
  
  // Shared Preferences Keys
  static const String prefUserId = 'user_id';
  static const String prefUserRole = 'user_role';
  static const String prefUserEmail = 'user_email';
  static const String prefLanguageCode = 'language_code';
  static const String prefIsLoggedIn = 'is_logged_in';
  
  // Water Types
  static const List<String> waterTypes = [
    'Mineral Water',
    'Distilled Water',
    'Spring Water',
    'Alkaline Water',
    'Sparkling Water',
  ];
  
  // Water Prices (per liter)
  static const Map<String, double> waterPrices = {
    'Mineral Water': 2500,
    'Distilled Water': 2000,
    'Spring Water': 1500,
    'Alkaline Water': 3000,
    'Sparkling Water': 3500,
  };
  
  // Delivery Fee
  static const double deliveryFee = 1000;
  
  // Order Status
  static const List<String> orderStatus = [
    'pending',
    'confirmed',
    'preparing',
    'delivered',
    'cancelled',
  ];
  
  // Payment Methods
  static const List<String> paymentMethods = [
    'cash',
    'mobile_money',
    'card',
  ];
}