import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../../modules/auth/screens/splash_screen.dart';
import '../../modules/auth/screens/login_screen.dart';
import '../../modules/auth/screens/register_screen.dart';
import '../../modules/auth/screens/forgot_password_screen.dart';
import '../../modules/customer/screens/home_screen.dart';
import '../../modules/customer/screens/request_water_screen.dart';
import '../../modules/customer/screens/vendor_list_screen.dart';
import '../../modules/customer/screens/order_confirmation_screen.dart';
import '../../modules/customer/screens/order_tracking_screen.dart';
import '../../modules/customer/screens/payment_screen.dart';
import '../../modules/customer/screens/order_history_screen.dart';
import '../../modules/customer/screens/profile_screen.dart';
import '../../modules/vendor/screens/vendor_dashboard.dart';
import '../../modules/vendor/screens/incoming_orders_screen.dart';
import '../../modules/vendor/screens/active_deliveries_screen.dart';
import '../../modules/vendor/screens/order_details_screen.dart';
import '../../modules/vendor/screens/earnings_screen.dart';
import '../../modules/vendor/screens/vendor_profile_screen.dart';
import '../../modules/admin/screens/admin_dashboard.dart';
import '../../modules/admin/screens/manage_users_screen.dart';
import '../../modules/admin/screens/manage_orders_screen.dart';
import '../../modules/admin/screens/reports_screen.dart';
import '../../modules/admin/screens/payment_monitoring_screen.dart';
import '../../modules/chat/screens/chat_screen.dart';
import '../../modules/chat/screens/conversations_list_screen.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth routes
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      
      // Customer routes
      case AppRoutes.customerHome:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.requestWater:
        return MaterialPageRoute(builder: (_) => const RequestWaterScreen());
      case AppRoutes.vendorList:
        return MaterialPageRoute(builder: (_) => const VendorListScreen());
      case AppRoutes.orderConfirmation:
        return MaterialPageRoute(builder: (_) => const OrderConfirmationScreen());
      case AppRoutes.orderTracking:
        return MaterialPageRoute(builder: (_) => const OrderTrackingScreen());
      case AppRoutes.payment:
        return MaterialPageRoute(builder: (_) => const PaymentScreen());
      case AppRoutes.orderHistory:
        return MaterialPageRoute(builder: (_) => const OrderHistoryScreen());
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      
      // Vendor routes
      case AppRoutes.vendorDashboard:
        return MaterialPageRoute(builder: (_) => const VendorDashboard());
      case AppRoutes.incomingOrders:
        return MaterialPageRoute(builder: (_) => const IncomingOrdersScreen());
      case AppRoutes.activeDeliveries:
        return MaterialPageRoute(builder: (_) => const ActiveDeliveriesScreen());
      case AppRoutes.orderDetails:
        return MaterialPageRoute(builder: (_) => const OrderDetailsScreen());
      case AppRoutes.vendorEarnings:
        return MaterialPageRoute(builder: (_) => const EarningsScreen());
      case AppRoutes.vendorProfile:
        return MaterialPageRoute(builder: (_) => const VendorProfileScreen());
      
      // Admin routes
      case AppRoutes.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      case AppRoutes.manageUsers:
        return MaterialPageRoute(builder: (_) => const ManageUsersScreen());
      case AppRoutes.manageOrders:
        return MaterialPageRoute(builder: (_) => const ManageOrdersScreen());
      case AppRoutes.reports:
        return MaterialPageRoute(builder: (_) => const ReportsScreen());
      case AppRoutes.paymentMonitoring:
        return MaterialPageRoute(builder: (_) => const PaymentMonitoringScreen());
      
      // Chat routes
      case AppRoutes.chat:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: args['conversationId'],
            receiverId: args['receiverId'],
            receiverName: args['receiverName'],
          ),
        );
      case AppRoutes.conversations:
        return MaterialPageRoute(builder: (_) => const ConversationsListScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
} 
