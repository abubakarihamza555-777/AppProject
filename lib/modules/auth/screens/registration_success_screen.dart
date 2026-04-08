import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../../config/routes/app_routes.dart';
import '../../../localization/language_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/custom_button.dart';

class RegistrationSuccessScreen extends StatefulWidget {
  final String userRole;
  final String userName;

  const RegistrationSuccessScreen({
    super.key,
    required this.userRole,
    required this.userName,
  });

  @override
  State<RegistrationSuccessScreen> createState() => _RegistrationSuccessScreenState();
}

class _RegistrationSuccessScreenState extends State<RegistrationSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildSuccessCard(LanguageProvider languageProvider, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode 
          ? Theme.of(context).colorScheme.surface
          : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success animation
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Success message
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Text(
                  languageProvider.translate('registration_successful'),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode 
                      ? Colors.white
                      : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  languageProvider.translate('account_created'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: themeProvider.isDarkMode 
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // User info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode 
                      ? Colors.grey.shade800
                      : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: themeProvider.isDarkMode 
                              ? Colors.white
                              : Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${languageProvider.translate('full_name')}: ${widget.userName}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: themeProvider.isDarkMode 
                                ? Colors.white
                                : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.assignment_ind,
                            color: themeProvider.isDarkMode 
                              ? Colors.white
                              : Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${languageProvider.translate('role')}: ${widget.userRole == 'customer' ? (languageProvider.currentLocale.languageCode == 'sw' ? 'Mteja' : 'Customer') : (languageProvider.currentLocale.languageCode == 'sw' ? 'Mtoa Huduma' : 'Vendor')}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: themeProvider.isDarkMode 
                                ? Colors.white
                                : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action buttons
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                CustomButton(
                  text: languageProvider.translate('complete_profile'),
                  onPressed: () {
                    if (widget.userRole == 'customer') {
                      Navigator.pushNamed(context, AppRoutes.customerProfileCompletion);
                    } else {
                      Navigator.pushNamed(context, AppRoutes.vendorProfileCompletion);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.customerHome,
                      (route) => false,
                    );
                  },
                  child: Text(
                    languageProvider.translate('skip_for_now'),
                    style: GoogleFonts.poppins(
                      color: themeProvider.isDarkMode 
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode 
        ? const Color(0xFF000000)
        : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Welcome illustration
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: themeProvider.isDarkMode 
                          ? [Colors.blue.shade800, Colors.blue.shade900]
                          : [Colors.blue.shade400, Colors.blue.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Icon(
                      Icons.water_drop,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Success card
                _buildSuccessCard(languageProvider, themeProvider),
                
                const SizedBox(height: 24),
                
                // Additional info
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode 
                        ? Colors.blue.shade900.withValues(alpha: 0.3)
                        : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: themeProvider.isDarkMode 
                          ? Colors.blue.shade700.withValues(alpha: 0.3)
                          : Colors.blue.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: themeProvider.isDarkMode 
                            ? Colors.blue.shade300
                            : Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            languageProvider.translate('profile_completion_required'),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: themeProvider.isDarkMode 
                                ? Colors.blue.shade300
                                : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
