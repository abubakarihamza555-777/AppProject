import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../localization/language_provider.dart';
import '../../../core/utils/helpers.dart';
import '../controllers/vendor_dashboard_controller.dart';
import '../widgets/vendor_stats_card.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final controller = context.read<VendorDashboardController>();
    await controller.loadDashboardData('temp_vendor_id'); // Replace with actual vendor ID
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final controller = Provider.of<VendorDashboardController>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('vendor_dashboard')),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: controller.isLoading
          ? const LoadingIndicator()
          : RefreshIndicator(
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
                            languageProvider.translate('good_morning'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Vendor Name',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: VendorStatsCard(
                            title: languageProvider.translate('incoming_orders'),
                            value: controller.incomingOrdersCount.toString(),
                            icon: Icons.shopping_bag,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: VendorStatsCard(
                            title: languageProvider.translate('active_deliveries'),
                            value: controller.activeDeliveriesCount.toString(),
                            icon: Icons.delivery_dining,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: VendorStatsCard(
                            title: languageProvider.translate('today_earnings'),
                            value: Helpers.formatPrice(controller.todayEarnings),
                            icon: Icons.today,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: VendorStatsCard(
                            title: languageProvider.translate('total_earnings'),
                            value: Helpers.formatPrice(controller.totalEarnings),
                            icon: Icons.account_balance_wallet,
                            color: Colors.purple,
                          ),
                        ),
                      ],
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
                    ListView.builder(
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
                            trailing: Text(Helpers.formatPrice(order.totalPrice)),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/vendor/order-details',
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
              // Already on dashboard
              break;
            case 1:
              Navigator.pushNamed(context, '/vendor/earnings');
              break;
            case 2:
              Navigator.pushNamed(context, '/vendor/profile');
              break;
          }
        },
      ),
    );
  }
} 
