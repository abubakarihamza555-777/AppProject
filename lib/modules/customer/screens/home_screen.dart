import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../localization/language_provider.dart';
import '../controllers/home_controller.dart';
import '../widgets/delivery_service_card.dart';
import '../widgets/vendor_card.dart';

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
    await controller.loadDeliveryServices();
    await controller.loadRecentOrders();
    // Load vendors (will show all if no location set)
    await controller.loadVendorsByLocation();
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
                      Colors.blue.shade600,
                      Colors.blue.shade800,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Dar es Salaam',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${languageProvider.translate('welcome')}, ${controller.userName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Get clean water delivered to your doorstep',
                      style: TextStyle(
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
                        foregroundColor: Colors.blue.shade700,
                      ),
                      child: const Text('Request Water Delivery'),
                    ),
                  ],
                ),
              ),

              // Quick Info Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Professional water delivery using car tanks throughout Dar es Salaam. Fast, reliable service.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Water Delivery Services
              const Text(
                'Water Delivery Services - Dar es Salaam',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              controller.isLoading
                  ? const LoadingIndicator()
                  : SizedBox(
                      height: 240,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.deliveryServices.length,
                        itemBuilder: (context, index) {
                          final service = controller.deliveryServices[index];
                          return DeliveryServiceCard(
                            service: service,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.requestWater,
                                arguments: service,
                              );
                            },
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 24),

              // Available Vendors
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Vendors in ${controller.getCustomerLocationDisplay()}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Navigate to vendor list or filters
                    },
                    icon: const Icon(Icons.filter_list, size: 16),
                    label: const Text('View All', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              controller.isLoadingVendors
                  ? const LoadingIndicator()
                  : controller.availableVendors.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.store_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No vendors available in your area',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try setting your location in profile',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.availableVendors.length,
                          itemBuilder: (context, index) {
                            final vendor = controller.availableVendors[index];
                            return VendorCard(
                              vendor: vendor,
                              onTap: () {
                                // TODO: Navigate to vendor details
                              },
                            );
                          },
                        ),
              const SizedBox(height: 24),

              // Recent Orders
              const Text(
                'Recent Water Deliveries',
                style: TextStyle(
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
                          'No recent deliveries',
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
                            leading: Icon(
                              order.serviceType == 'small' ? Icons.directions_car : Icons.local_shipping,
                              color: Colors.blue,
                            ),
                            title: Text('${order.serviceType?.toUpperCase() ?? 'CAR'} Tank Delivery'),
                            subtitle: Text(
                              '${order.quantity} L - ${order.getStatusText('en')}',
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
