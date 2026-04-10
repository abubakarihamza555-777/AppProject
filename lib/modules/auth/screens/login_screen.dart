import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../localization/language_provider.dart';
import '../controllers/auth_controller.dart';
import '../../../core/services/profile_completion_service.dart';
import '../../../core/notifications/notification_service.dart';

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
  bool _obscurePassword = true;
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
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  Future<void> _loginWithBiometric() async {
    final isAvailable = await _localAuth.canCheckBiometrics;
    if (!isAvailable) return;
    
    final isAuthenticated = await _localAuth.authenticate(
      localizedReason: 'Login to Dar Water',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
    
    if (isAuthenticated && mounted) {
      // Auto-fill last used credentials and login
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final savedPassword = prefs.getString('saved_password');
      if (savedEmail != null && savedPassword != null) {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _handleLogin();
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_rememberMe) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', _emailController.text);
      await prefs.setString('saved_password', _passwordController.text);
    }
    
    setState(() => _isLoading = true);
    
    final auth = context.read<AuthController>();
    final ok = await auth.signIn(email: _emailController.text.trim(), password: _passwordController.text);
    
    setState(() => _isLoading = false);
    if (!mounted) return;

    if (!ok) {
      final languageProvider = context.read<LanguageProvider>();
      final msg = auth.errorMessage ?? languageProvider.translate('login_failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = auth.currentUser;
    if (user != null) {
      switch (user.role) {
        case 'customer':
          Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
          break;
        case 'vendor':
          Navigator.pushReplacementNamed(context, AppRoutes.vendorDashboard);
          break;
        case 'admin':
          Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
          break;
        default:
          Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Back button with style
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Welcome text
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue ordering water',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Email field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Password field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Remember me & Forgot password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() => _rememberMe = value ?? false);
                              },
                              activeColor: Colors.blue,
                            ),
                            const Text('Remember me'),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.forgotPassword);
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.blue.shade600),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Login button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade800],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200,
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Biometric login
                    FutureBuilder<bool>(
                      future: _localAuth.canCheckBiometrics,
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == true) {
                          return Center(
                            child: TextButton.icon(
                              onPressed: _loginWithBiometric,
                              icon: Icon(
                                Icons.fingerprint,
                                color: Colors.blue.shade600,
                              ),
                              label: Text(
                                'Use Fingerprint',
                                style: TextStyle(color: Colors.blue.shade600),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Or continue with',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Social login buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialLoginCircle(
                          icon: 'assets/icons/google.png',
                          color: Colors.red,
                          onTap: () {
                            // TODO: Implement Google login
                          },
                        ),
                        const SizedBox(width: 20),
                        _SocialLoginCircle(
                          icon: Icons.facebook,
                          color: Colors.blue.shade700,
                          onTap: () {
                            // TODO: Implement Facebook login
                          },
                        ),
                        const SizedBox(width: 20),
                        _SocialLoginCircle(
                          icon: Icons.apple,
                          color: Colors.black,
                          onTap: () {
                            // TODO: Implement Apple login
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.roleSelection,
                            );
                          },
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialLoginCircle extends StatelessWidget {
  final dynamic icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialLoginCircle({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: icon is String
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(icon),
              )
            : Icon(icon, color: color, size: 24),
      ),
    );
  }
}
    final profileCompletionService = context.read<ProfileCompletionService>();
    final notificationService = context.read<NotificationService>();
    
    switch (user?.role) {
      case 'customer':
        // Check if customer needs to complete profile
        if (profileCompletionService.shouldShowCustomerProfilePrompt()) {
          _showProfileCompletionDialog(
            context, 
            'customer', 
            profileCompletionService, 
            notificationService,
            AppRoutes.customerProfileCompletion
          );
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
        }
        return;
      case 'vendor':
        // Check if vendor needs to complete profile
        if (profileCompletionService.shouldShowVendorProfilePrompt()) {
          _showProfileCompletionDialog(
            context, 
            'vendor', 
            profileCompletionService, 
            notificationService,
            AppRoutes.vendorProfileCompletion
          );
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
                userType == 'customer' ? 'Complete Your Profile' : 'Complete Your Business Profile',
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
                    description: 'Tell us your district and ward for nearby vendors',
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
                    description: 'Complete your business details and service areas',
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
                    // Mark prompt as shown and proceed to home
                    if (userType == 'customer') {
                      await profileCompletionService.markCustomerPromptShown();
                      Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
                    } else {
                      await profileCompletionService.markVendorPromptShown();
                      Navigator.pushReplacementNamed(context, AppRoutes.vendorDashboard);
                    }
                  },
                  child: const Text('Skip for Now'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    // Mark prompt as shown and navigate to profile completion
                    if (userType == 'customer') {
                      await profileCompletionService.markCustomerPromptShown();
                    } else {
                      await profileCompletionService.markVendorPromptShown();
                    }
                    
                    Navigator.pushReplacementNamed(context, completionRoute);
                    
                    // Show notification
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // App Logo/Icon
              Icon(
                Icons.water_drop,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 20),
              
              // Welcome Title
              Text(
                languageProvider.translate('welcome_to_dar_water_app'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              
              Text(
                languageProvider.translate('login_with_email_or_phone'),
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Login Form
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      spreadRadius: 1,
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
                        label: languageProvider.translate('email_or_phone'),
                        controller: _email,
                        prefixIcon: Icons.email_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageProvider.translate('please_enter_email_or_phone');
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Password Field
                      CustomTextField(
                        label: languageProvider.translate('password'),
                        controller: _password,
                        isPassword: true,
                        prefixIcon: Icons.lock_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageProvider.translate('please_enter_password');
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Login Button
                      CustomButton(
                        text: languageProvider.translate('login'),
                        onPressed: _isLoading || auth.isLoading 
                            ? null 
                            : _submit,
                        isLoading: _isLoading || auth.isLoading,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Forgot Password
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.forgotPassword);
                        },
                        child: Text(languageProvider.translate('forgot_password')),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    languageProvider.translate('dont_have_account'),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
                    },
                    child: Text(languageProvider.translate('register')),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
