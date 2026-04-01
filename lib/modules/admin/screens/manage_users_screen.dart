import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_management_controller.dart';
import '../widgets/user_list_tile.dart';
import '../../auth/models/user_model.dart';
import '../../vendor/models/vendor_model.dart';
import '../../../shared/widgets/loading_indicator.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  late UserManagementController _controller;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = UserManagementController();
    _tabController = TabController(length: 2, vsync: this);
    
    _controller.loadUsers();
    _controller.loadVendors();
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Users'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Users'),
              Tab(text: 'Vendors'),
            ],
          ),
        ),
        body: Consumer<UserManagementController>(
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
                      onPressed: () {
                        controller.loadUsers();
                        controller.loadVendors();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                // Users tab
                RefreshIndicator(
                  onRefresh: () => controller.loadUsers(),
                  child: ListView.builder(
                    itemCount: controller.users.length,
                    itemBuilder: (context, index) {
                      final user = controller.users[index];
                      return UserListTile(
                        user: user,
                        onSuspend: user.isActive
                            ? () => _showSuspendDialog(context, user)
                            : null,
                        onActivate: !user.isActive
                            ? () => _activateUser(context, user)
                            : null,
                        onViewDetails: () => _showUserDetails(context, user),
                      );
                    },
                  ),
                ),
                // Vendors tab
                RefreshIndicator(
                  onRefresh: () => controller.loadVendors(),
                  child: ListView.builder(
                    itemCount: controller.vendors.length,
                    itemBuilder: (context, index) {
                      final vendor = controller.vendors[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: vendor.isVerified
                                ? Colors.green
                                : Colors.orange,
                            child: Text(
                              vendor.businessName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(vendor.businessName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(vendor.businessPhone),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: vendor.isVerified
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  vendor.isVerified ? 'Verified' : 'Pending Approval',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: vendor.isVerified
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: !vendor.isVerified
                              ? ElevatedButton(
                                  onPressed: () => _approveVendor(context, vendor),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Approve'),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () => _showVendorDetails(context, vendor),
                                ),
                          onTap: () => _showVendorDetails(context, vendor),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showSuspendDialog(
      BuildContext context, UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend User'),
        content: Text('Are you sure you want to suspend ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.suspendUser(user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User suspended successfully')),
        );
      }
    }
  }

  Future<void> _activateUser(BuildContext context, UserModel user) async {
    await _controller.activateUser(user);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User activated successfully')),
      );
    }
  }

  Future<void> _approveVendor(BuildContext context, VendorModel vendor) async {
    await _controller.approveVendor(vendor);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${vendor.businessName} approved successfully')),
      );
    }
  }

  void _showUserDetails(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user.email}'),
            const SizedBox(height: 8),
            Text('Role: ${user.role}'),
            const SizedBox(height: 8),
            Text('Status: ${user.isActive ? 'Active' : 'Suspended'}'),
            const SizedBox(height: 8),
            Text('Joined: ${user.createdAt.toLocal()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showVendorDetails(BuildContext context, VendorModel vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vendor.businessName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Owner: ${vendor.userId}'),
              const SizedBox(height: 8),
              Text('Phone: ${vendor.businessPhone}'),
              const SizedBox(height: 8),
              Text('Address: ${vendor.businessAddress}'),
              const SizedBox(height: 8),
              Text('Rating: ${vendor.rating.toStringAsFixed(1)}'),
              const SizedBox(height: 8),
              Text('Total Deliveries: ${vendor.totalDeliveries}'),
              const SizedBox(height: 8),
              Text('Status: ${vendor.isVerified ? 'Verified' : 'Pending'}'),
              const SizedBox(height: 8),
              Text('Joined: ${vendor.createdAt.toLocal()}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
