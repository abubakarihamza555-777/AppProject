// lib/modules/auth/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../config/routes/app_routes.dart';
import '../controllers/auth_controller.dart';
import '../../../shared/services/profile_completion_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for animation
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    // Initialize auth controller
    final authController = context.read<AuthController>();
    await authController.initialize();
    
    // Check if user is authenticated
    if (authController.isAuthenticated) {
      final user = authController.currentUser;
      final profileService = ProfileCompletionService();
      
      if (user != null) {
        switch (user.role) {
          case 'customer':
            // Check if profile is completed
            final isProfileCompleted = await profileService.isCustomerProfileCompleted();
            if (isProfileCompleted) {
              Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.customerProfileCompletion);
            }
            break;
            
          case 'vendor':
            final isProfileCompleted = await profileService.isVendorProfileCompleted();
            if (isProfileCompleted) {
              Navigator.pushReplacementNamed(context, AppRoutes.vendorDashboard);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.vendorProfileCompletion);
            }
            break;
            
          case 'admin':
            Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
            break;
            
          default:
            Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
        }
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
      }
    } else {
      // Not authenticated, go to role selection
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeIn,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo/Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // App Name
                    Shimmer.fromColors(
                      baseColor: Theme.of(context).primaryColor,
                      highlightColor: Theme.of(context).primaryColor.withAlpha(76),
                      child: const Text(
                        'Water Delivery',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Tagline
                    Text(
                      'Fresh Water at Your Doorstep',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 50),
                    
                    // Loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
