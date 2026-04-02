import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/routes/app_routes.dart';
import '../controllers/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authController = context.read<AuthController>();

    // Check if user is authenticated in Supabase
    if (authController.isAuthenticated()) {
      try {
        // Load user data
        await authController.loadCurrentUser();
        final user = authController.currentUser;
        
        if (user != null) {
          switch (user.role) {
            case 'customer':
              Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
              return;
            case 'vendor':
              Navigator.pushReplacementNamed(context, AppRoutes.vendorDashboard);
              return;
            case 'admin':
              Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
              return;
          }
        }
      } catch (e) {
        print('Error loading user data: $e');
        // If there's an error loading user data, go to role selection
      }
    }

    // Navigate to role selection for new users
    Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColorDark,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.water_drop, size: 100, color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Water Delivery',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Pure Water, Delivered Fast',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 50),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
