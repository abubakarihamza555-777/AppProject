import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../localization/language_provider.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/services/profile_completion_service.dart';
import '../../../shared/services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _localAuth = LocalAuthentication();
  bool _rememberMe = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('saved_email');
      final password = prefs.getString('saved_password');
      final remember = prefs.getBool('remember_me') ?? false;

      if (email != null && password != null && remember) {
        setState(() {
          _emailController.text = email;
          _passwordController.text = password;
          _rememberMe = remember;
        });
      }
    } catch (e) {
      print('Error loading saved credentials: $e');
    }
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_email', _emailController.text);
        await prefs.setString('saved_password', _passwordController.text);
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
        await prefs.setBool('remember_me', false);
      }
    } catch (e) {
      print('Error saving credentials: $e');
    }
  }

  Future<void> _loginWithBiometric() async {
    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        // Load saved credentials and login
        await _loadSavedCredentials();
        if (_emailController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty) {
          await _handleLogin();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    // Prevent multiple simultaneous login attempts
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authController = context.read<AuthController>();
      final success = await authController.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        // Save credentials if remember me is checked
        if (_rememberMe) {
          await _saveCredentials();
        }

        // Get the user to determine navigation
        final user = authController.currentUser;
        final profileService = ProfileCompletionService();

        if (user != null) {
          switch (user.role) {
            case 'customer':
              final isProfileCompleted =
                  await profileService.isCustomerProfileCompleted();
              if (mounted) {
                if (isProfileCompleted) {
                  Navigator.pushReplacementNamed(
                      context, AppRoutes.customerHome);
                } else {
                  Navigator.pushReplacementNamed(
                      context, AppRoutes.customerProfileCompletion);
                }
              }
              break;

            case 'vendor':
              final isProfileCompleted =
                  await profileService.isVendorProfileCompleted();
              if (mounted) {
                if (isProfileCompleted) {
                  Navigator.pushReplacementNamed(
                      context, AppRoutes.vendorDashboard);
                } else {
                  Navigator.pushReplacementNamed(
                      context, AppRoutes.vendorProfileCompletion);
                }
              }
              break;

            case 'admin':
              if (mounted) {
                Navigator.pushReplacementNamed(
                    context, AppRoutes.adminDashboard);
              }
              break;

            default:
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
              }
          }
        } else if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
        }
      } else if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(
          authController.errorMessage ?? 'Login failed',
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Login failed: ${e.toString()}', Colors.red);
      }
    }
  }

  void _navigateToHome(UserModel user) async {
    final profileCompletionService = context.read<ProfileCompletionService>();
    final notificationService = context.read<NotificationService>();

    switch (user.role) {
      case 'customer':
        if (await profileCompletionService.shouldShowCustomerProfilePrompt()) {
          _showProfileCompletionDialog(
              context,
              'customer',
              profileCompletionService,
              notificationService,
              AppRoutes.customerProfileCompletion);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
        }
        return;
      case 'vendor':
        if (await profileCompletionService.shouldShowVendorProfilePrompt()) {
          _showProfileCompletionDialog(
              context,
              'vendor',
              profileCompletionService,
              notificationService,
              AppRoutes.vendorProfileCompletion);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.vendorDashboard);
        }
        return;
      case 'admin':
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        return;
      default:
        Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
    }
  }

  void _showProfileCompletionDialog(
    BuildContext context,
    String userType,
    ProfileCompletionService profileCompletionService,
    NotificationService notificationService,
    String completionRoute,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.person_outline,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                userType == 'customer'
                    ? 'Complete Your Profile'
                    : 'Complete Your Business Profile',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userType == 'customer'
                  ? 'To get the best water delivery service, please complete your profile with your location and preferences.'
                  : 'To start receiving water delivery orders, please complete your business profile with service areas and vehicle details.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (userType == 'customer')
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileItem(
                    icon: Icons.location_on_outlined,
                    title: 'Set Your Location',
                    description:
                        'Tell us your district and ward for nearby vendors',
                  ),
                  SizedBox(height: 8),
                  _ProfileItem(
                    icon: Icons.home_outlined,
                    title: 'House Details',
                    description: 'Add your house number for accurate delivery',
                  ),
                ],
              )
            else
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileItem(
                    icon: Icons.business_outlined,
                    title: 'Business Information',
                    description:
                        'Complete your business details and service areas',
                  ),
                  SizedBox(height: 8),
                  _ProfileItem(
                    icon: Icons.local_shipping_outlined,
                    title: 'Vehicle Details',
                    description: 'Add your delivery vehicle information',
                  ),
                ],
              ),
          ],
        ),
        actions: [
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  if (userType == 'customer') {
                    await profileCompletionService.markCustomerPromptShown();
                    Navigator.pushReplacementNamed(
                        context, AppRoutes.customerHome);
                  } else {
                    await profileCompletionService.markVendorPromptShown();
                    Navigator.pushReplacementNamed(
                        context, AppRoutes.vendorDashboard);
                  }
                },
                child: const Text('Skip for Now'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  if (userType == 'customer') {
                    await profileCompletionService.markCustomerPromptShown();
                  } else {
                    await profileCompletionService.markVendorPromptShown();
                  }

                  Navigator.pushReplacementNamed(context, completionRoute);

                  await notificationService.showSystemNotification(
                    'Profile Completion',
                    userType == 'customer'
                        ? 'Please complete your customer profile for better service'
                        : 'Please complete your vendor profile to start receiving orders',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Complete Profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 24.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).viewInsets.bottom,
              ),
              child: IntrinsicHeight(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),

                      // App Logo/Icon
                      Icon(
                        Icons.water_drop,
                        size: 60,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(height: 16),

                      // Welcome Title
                      Text(
                        'Welcome to Dar Water',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Login to continue',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      // Login Form
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Email/Phone Field
                              CustomTextField(
                                label: 'Email or Phone',
                                controller: _emailController,
                                prefixIcon: Icons.email_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter email or phone';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),

                              // Password Field
                              CustomTextField(
                                label: 'Password',
                                controller: _passwordController,
                                isPassword: true,
                                prefixIcon: Icons.lock_outline,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter password';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),

                              // Remember Me & Forgot Password
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const Text('Remember me',
                                      style: TextStyle(fontSize: 12)),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                          context, AppRoutes.forgotPassword);
                                    },
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                          color: Colors.blue.shade600,
                                          fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Login Button
                              Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade600,
                                      Colors.blue.shade800
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.shade200,
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading || auth.isLoading
                                      ? null
                                      : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                  ),
                                  child: _isLoading || auth.isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 3)
                                      : const Text('Login',
                                          style:
                                              TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Biometric Login
                      if (_emailController.text.isNotEmpty &&
                          _passwordController.text.isNotEmpty)
                        Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _loginWithBiometric,
                            icon: Icon(Icons.fingerprint,
                                color: Colors.grey.shade700, size: 18),
                            label: Text('Login with Biometric',
                                style: TextStyle(
                                    color: Colors.grey.shade700, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, AppRoutes.roleSelection);
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
