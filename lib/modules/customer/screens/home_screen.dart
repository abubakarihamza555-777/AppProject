import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../localization/language_provider.dart';
import '../controllers/home_controller.dart';
import '../widgets/water_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final controller = context.read<HomeController>();
    await controller.loadWaterTypes();
    await controller.loadRecentOrders();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final controller = Provider.of<HomeController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('app_name')),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              _showLanguageDialog(context, languageProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColorDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${languageProvider.translate('welcome')}, ${controller.userName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      languageProvider.translate('order_water'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.requestWater);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      child: Text(languageProvider.translate('order_now')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Popular Water Types
              Text(
                languageProvider.translate('popular_water'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              controller.isLoading
                  ? const LoadingIndicator()
                  : SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.waterTypes.length,
                        itemBuilder: (context, index) {
                          return WaterCard(
                            waterType: controller.waterTypes[index],
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.requestWater,
                                arguments: controller.waterTypes[index],
                              );
                            },
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 24),

              // Recent Orders
              Text(
                languageProvider.translate('recent_orders'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              controller.recentOrders.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          languageProvider.translate('no_orders'),
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.recentOrders.length,
                      itemBuilder: (context, index) {
                        final order = controller.recentOrders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(Icons.local_drink),
                            title: Text(order.waterType),
                            subtitle: Text(
                              '${order.quantity} L - ${order.getStatusText(languageProvider.currentLocale.languageCode)}',
                            ),
                            trailing: Text('TZS ${order.totalPrice}'),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.orderTracking,
                                arguments: order.id,
                              );
                            },
                          ),
                        );
                      },
                    ),
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

  void _showLanguageDialog(BuildContext context, LanguageProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(provider.translate('select_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇬🇧'),
              title: Text(provider.translate('english')),
              onTap: () {
                provider.changeLanguage('en');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇹🇿'),
              title: Text(provider.translate('swahili')),
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
}
