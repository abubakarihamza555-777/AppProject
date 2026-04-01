import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../../../modules/customer/models/order_model.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/enums/order_status.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  final AdminService _adminService = AdminService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _subscribeToOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _orders = await _adminService.getAllOrders();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _subscribeToOrders() {
    _adminService.subscribeToOrders().listen((orders) {
      if (mounted) {
        setState(() => _orders = orders);
      }
    });
  }

  List<OrderModel> get _filteredOrders {
    if (_filter == 'all') return _orders;
    return _orders.where((o) => o.status == _filter).toList();
  }

  Future<void> _updateOrderStatus(OrderModel order, String newStatus) async {
    try {
      await _adminService.updateOrderStatus(order.id, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order ${order.id.substring(0, 8)} updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              initialValue: _filter,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Orders')),
                ...OrderStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status.name,
                    child: Text(status.name.toUpperCase()),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _filter = value!);
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOrders,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _filteredOrders.isEmpty
                  ? const Center(
                      child: Text('No orders found'),
                    )
                  : ListView.builder(
                      itemCount: _filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = _filteredOrders[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ExpansionTile(
                            leading: _getStatusIcon(order.status),
                            title: Text('Order #${order.id.substring(0, 8)}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Customer: ${order.customerId}'),
                                Text('Amount: TZS ${order.totalAmount.toStringAsFixed(0)}'),
                                Text('Status: ${order.status.toUpperCase()}'),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Order Details',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...order.items.map((item) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${item['quantity']}x ${item['name']}'),
                                          Text('TZS ${(item['price'] * item['quantity']).toStringAsFixed(0)}'),
                                        ],
                                      ),
                                    )),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Total'),
                                        Text(
                                          'TZS ${order.totalAmount.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (order.status == 'pending')
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  _updateOrderStatus(order, 'confirmed'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                              ),
                                              child: const Text('Confirm Order'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  _updateOrderStatus(order, 'cancelled'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              child: const Text('Cancel'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (order.status == 'confirmed')
                                      ElevatedButton(
                                        onPressed: () =>
                                            _updateOrderStatus(order, 'preparing'),
                                        child: const Text('Start Preparing'),
                                      ),
                                    if (order.status == 'preparing')
                                      ElevatedButton(
                                        onPressed: () =>
                                            _updateOrderStatus(order, 'out_for_delivery'),
                                        child: const Text('Out for Delivery'),
                                      ),
                                    if (order.status == 'out_for_delivery')
                                      ElevatedButton(
                                        onPressed: () =>
                                            _updateOrderStatus(order, 'delivered'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        child: const Text('Mark as Delivered'),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _getStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status) {
      case 'pending':
        icon = Icons.pending;
        color = Colors.orange;
        break;
      case 'confirmed':
        icon = Icons.check_circle;
        color = Colors.blue;
        break;
      case 'preparing':
        icon = Icons.kitchen;
        color = Colors.purple;
        break;
      case 'out_for_delivery':
        icon = Icons.local_shipping;
        color = Colors.teal;
        break;
      case 'delivered':
        icon = Icons.delivery_dining;
        color = Colors.green;
        break;
      case 'completed':
        icon = Icons.done_all;
        color = Colors.green;
        break;
      default:
        icon = Icons.error;
        color = Colors.red;
    }

    return Icon(icon, color: color);
  }
} 
