import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../widgets/stats_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'manage_users_screen.dart';
import 'manage_orders_screen.dart';
import 'reports_screen.dart';
import 'payment_monitoring_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late AdminDashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AdminDashboardController();
    _controller.loadDashboard();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.refresh(),
            ),
          ],
        ),
        body: Consumer<AdminDashboardController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const LoadingIndicator();
            }

            if (controller.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${controller.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.loadDashboard(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final stats = controller.stats;
            if (stats == null) return const SizedBox();

            return RefreshIndicator(
              onRefresh: () => controller.loadDashboard(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        StatsCard(
                          title: 'Total Users',
                          value: stats.totalUsers.toString(),
                          icon: Icons.people,
                          color: Colors.blue,
                          onTap: () => _navigateToUsers(),
                        ),
                        StatsCard(
                          title: 'Total Vendors',
                          value: stats.totalVendors.toString(),
                          icon: Icons.store,
                          color: Colors.orange,
                          onTap: () => _navigateToVendors(),
                        ),
                        StatsCard(
                          title: 'Total Orders',
                          value: stats.totalOrders.toString(),
                          icon: Icons.shopping_cart,
                          color: Colors.green,
                          onTap: () => _navigateToOrders(),
                        ),
                        StatsCard(
                          title: 'Pending Orders',
                          value: stats.pendingOrders.toString(),
                          icon: Icons.pending,
                          color: Colors.red,
                          onTap: () => _navigateToOrders(),
                        ),
                        StatsCard(
                          title: 'Total Revenue',
                          value: 'TZS ${stats.totalRevenue.toStringAsFixed(0)}',
                          icon: Icons.attach_money,
                          color: Colors.purple,
                          onTap: () => _navigateToPayments(),
                        ),
                        StatsCard(
                          title: 'Active Vendors',
                          value: '${stats.activeVendors}/${stats.totalVendors}',
                          icon: Icons.storefront,
                          color: Colors.teal,
                          onTap: () => _navigateToVendors(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildQuickAction(
                          icon: Icons.person_add,
                          label: 'Manage Users',
                          color: Colors.blue,
                          onTap: () => _navigateToUsers(),
                        ),
                        _buildQuickAction(
                          icon: Icons.shopping_bag,
                          label: 'Manage Orders',
                          color: Colors.green,
                          onTap: () => _navigateToOrders(),
                        ),
                        _buildQuickAction(
                          icon: Icons.payment,
                          label: 'Payments',
                          color: Colors.purple,
                          onTap: () => _navigateToPayments(),
                        ),
                        _buildQuickAction(
                          icon: Icons.assessment,
                          label: 'Reports',
                          color: Colors.orange,
                          onTap: () => _navigateToReports(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (controller.recentOrders != null &&
                        controller.recentOrders!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent Orders',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...controller.recentOrders!.take(5).map((order) =>
                              ListTile(
                                leading: const Icon(Icons.shopping_cart),
                                title: Text('Order #${order.id.substring(0, 8)}'),
                                subtitle: Text('Status: ${order.status}'),
                                trailing: Text(
                                  'TZS ${order.totalAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () => _navigateToOrders(),
                              )),
                        ],
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

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
    );
  }

  void _navigateToVendors() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
    );
  }

  void _navigateToOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageOrdersScreen()),
    );
  }

  void _navigateToPayments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentMonitoringScreen()),
    );
  }

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportsScreen()),
    );
  }
} 
