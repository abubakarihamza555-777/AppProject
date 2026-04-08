import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../localization/language_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../controllers/home_controller.dart';
import '../widgets/delivery_service_card.dart';
import '../widgets/vendor_card.dart';

class PremiumHomeScreen extends StatefulWidget {
  const PremiumHomeScreen({super.key});

  @override
  State<PremiumHomeScreen> createState() => _PremiumHomeScreenState();
}

class _PremiumHomeScreenState extends State<PremiumHomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late AnimationController _fadeController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    _fadeController.forward();
    
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final controller = context.read<HomeController>();
    await controller.loadDeliveryServices();
    await controller.loadRecentOrders();
    await controller.loadVendorsByLocation();
  }

  Widget _buildPremiumHeader(HomeController controller, LanguageProvider languageProvider, ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeProvider.isDarkMode 
            ? [Colors.blue.shade800, Colors.blue.shade900]
            : [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // User greeting
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.currentLocale.languageCode == 'sw' 
                            ? 'Karibu, ${controller.userName}' 
                            : 'Welcome, ${controller.userName}',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              controller.getCustomerLocationDisplay(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  Row(
                    children: [
                      // Theme toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            context.read<ThemeProvider>().toggleTheme();
                          },
                          icon: Icon(
                            themeProvider.isDarkMode 
                              ? Icons.light_mode 
                              : Icons.dark_mode,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Language toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => _showLanguageDialog(context, languageProvider),
                          icon: const Icon(Icons.language, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Notifications
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            IconButton(
                              onPressed: () {
                                // Navigate to notifications
                              },
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Quick stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.local_shipping,
                        '${controller.availableVendors.length}',
                        languageProvider.currentLocale.languageCode == 'sw' 
                          ? 'Wenye Huduma' 
                          : 'Vendors',
                        Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        Icons.history,
                        '${controller.recentOrders.length}',
                        languageProvider.currentLocale.languageCode == 'sw' 
                          ? 'Oda Zilizopita' 
                          : 'Recent Orders',
                        Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        Icons.water_drop,
                        '100 TZS/L',
                        languageProvider.currentLocale.languageCode == 'sw' 
                          ? 'Bei ya Maji' 
                          : 'Water Price',
                        Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(LanguageProvider languageProvider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              languageProvider.currentLocale.languageCode == 'sw' 
                ? 'Vitendo Haraka' 
                : 'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    Icons.water_drop,
                    languageProvider.currentLocale.languageCode == 'sw' 
                      ? 'Oda Maji' 
                      : 'Order Water',
                    Colors.blue,
                    () => Navigator.pushNamed(context, AppRoutes.requestWater),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    Icons.history,
                    languageProvider.currentLocale.languageCode == 'sw' 
                      ? 'Historia' 
                      : 'History',
                    Colors.green,
                    () => Navigator.pushNamed(context, AppRoutes.orderHistory),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    Icons.person,
                    languageProvider.currentLocale.languageCode == 'sw' 
                      ? 'Wasifu' 
                      : 'Profile',
                    Colors.orange,
                    () => Navigator.pushNamed(context, AppRoutes.profile),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedVendors(HomeController controller, LanguageProvider languageProvider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  languageProvider.currentLocale.languageCode == 'sw' 
                    ? 'Wenye Huduma Bora' 
                    : 'Featured Vendors',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to all vendors
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text(
                    languageProvider.currentLocale.languageCode == 'sw' 
                      ? 'Ona Zote' 
                      : 'View All',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            controller.isLoadingVendors
                ? const Center(child: LoadingIndicator())
                : controller.availableVendors.isEmpty
                    ? _buildEmptyVendors(languageProvider)
                    : SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.availableVendors.length > 3 ? 3 : controller.availableVendors.length,
                          itemBuilder: (context, index) {
                            final vendor = controller.availableVendors[index];
                            return Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 12),
                              child: _buildVendorCard(vendor, languageProvider),
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> vendor, LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue.shade100,
            child: Icon(
              Icons.store,
              color: Colors.blue.shade700,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          
          // Vendor name
          Text(
            vendor['business_name'] ?? 'Unknown Vendor',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Rating
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 2),
              Text(
                '${vendor['rating'] ?? 0.0}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                ' (${vendor['total_deliveries'] ?? 0})',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Vehicle type
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getVehicleTypeName(vendor['vehicle_type'], languageProvider),
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getVehicleTypeName(String? vehicleType, LanguageProvider languageProvider) {
    if (languageProvider.currentLocale.languageCode == 'sw') {
      switch (vehicleType) {
        case 'towable':
          return 'Towable Browser';
        case 'medium_truck':
          return 'Lori ya Kati';
        case 'heavy_truck':
          return 'Lori Kubwa';
        default:
          return 'Gari Maji';
      }
    } else {
      switch (vehicleType) {
        case 'towable':
          return 'Towable Browser';
        case 'medium_truck':
          return 'Medium Truck';
        case 'heavy_truck':
          return 'Heavy Truck';
        default:
          return 'Water Vehicle';
      }
    }
  }

  Widget _buildEmptyVendors(LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.store_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            languageProvider.currentLocale.languageCode == 'sw' 
              ? 'Hakuna Wenye Huduma' 
              : 'No Vendors Available',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            languageProvider.currentLocale.languageCode == 'sw' 
              ? 'Weka mahali pako kuona wenye huduma karibu nawe' 
              : 'Set your location to see nearby vendors',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(HomeController controller, LanguageProvider languageProvider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              languageProvider.currentLocale.languageCode == 'sw' 
                ? 'Shughuli Zilizopita' 
                : 'Recent Activity',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            controller.recentOrders.isEmpty
                ? _buildEmptyActivity(languageProvider)
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.recentOrders.length > 3 ? 3 : controller.recentOrders.length,
                    itemBuilder: (context, index) {
                      final order = controller.recentOrders[index];
                      return _buildActivityItem(order, languageProvider);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActivity(LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            languageProvider.currentLocale.languageCode == 'sw' 
              ? 'Hakuna Shughuli Zilizopita' 
              : 'No Recent Activity',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            languageProvider.currentLocale.languageCode == 'sw' 
              ? 'Anza kuweka oda za maji kuona shughuli zako hapa' 
              : 'Start ordering water to see your activity here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(dynamic order, LanguageProvider languageProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.local_shipping,
              color: Colors.blue.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageProvider.currentLocale.languageCode == 'sw' 
                    ? 'Oda ya Maji' 
                    : 'Water Order',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${order.quantity ?? 0} L - ${languageProvider.currentLocale.languageCode == 'sw' ? 'TSh' : 'TZS'} ${order.totalPrice ?? 0}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          provider.currentLocale.languageCode == 'sw' 
            ? 'Chagua Lugha' 
            : 'Select Language',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: Text('English', style: GoogleFonts.poppins()),
              onTap: () {
                provider.changeLanguage('en');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇹🇿', style: TextStyle(fontSize: 24)),
              title: Text('Swahili', style: GoogleFonts.poppins()),
              onTap: () {
                provider.changeLanguage('sw');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final controller = Provider.of<HomeController>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode 
        ? const Color(0xFF000000)
        : const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildPremiumHeader(controller, languageProvider, themeProvider),
              const SizedBox(height: 20),
              _buildQuickActions(languageProvider),
              _buildFeaturedVendors(controller, languageProvider),
              _buildRecentActivity(controller, languageProvider),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              Navigator.pushNamed(context, AppRoutes.orderHistory);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.profile);
              break;
          }
        },
      ),
    );
  }
}
