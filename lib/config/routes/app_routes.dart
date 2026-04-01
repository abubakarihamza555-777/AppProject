class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  
  // Customer routes
  static const String customerHome = '/customer/home';
  static const String requestWater = '/customer/request-water';
  static const String vendorList = '/customer/vendors';
  static const String orderConfirmation = '/customer/order-confirmation';
  static const String orderTracking = '/customer/order-tracking';
  static const String payment = '/customer/payment';
  static const String orderHistory = '/customer/order-history';
  static const String profile = '/customer/profile';
  
  // Vendor routes
  static const String vendorDashboard = '/vendor/dashboard';
  static const String incomingOrders = '/vendor/incoming-orders';
  static const String activeDeliveries = '/vendor/active-deliveries';
  static const String orderDetails = '/vendor/order-details';
  static const String vendorEarnings = '/vendor/earnings';
  static const String vendorProfile = '/vendor/profile';
  
  // Admin routes
  static const String adminDashboard = '/admin/dashboard';
  static const String manageUsers = '/admin/manage-users';
  static const String manageOrders = '/admin/manage-orders';
  static const String reports = '/admin/reports';
  static const String paymentMonitoring = '/admin/payment-monitoring';
  
  // Chat routes
  static const String chat = '/chat';
  static const String conversations = '/conversations';
} 
