import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class RestaurantDashboard extends StatefulWidget {
  final String restaurantId;

  const RestaurantDashboard({super.key, required this.restaurantId});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard> {
  String _restaurantName = '';

  @override
  void initState() {
    super.initState();
    _loadRestaurantName();
  }

  Future<void> _loadRestaurantName() async {
    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final restaurant = await firestore.getRestaurantById(widget.restaurantId);
      if (mounted) {
        setState(() {
          _restaurantName = restaurant?.name ?? widget.restaurantId;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _restaurantName = widget.restaurantId;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context);
    final auth = Provider.of<AuthService>(context);

    // Check if user is authenticated
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Restaurant Dashboard'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Please Login First',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'You need to be logged in to view the dashboard.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$_restaurantName Dashboard'),
        backgroundColor: Colors.blue,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ID: ${widget.restaurantId}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats cards
          StreamBuilder<QuerySnapshot>(
            stream: firestore.getRestaurantOrders(widget.restaurantId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: LinearProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.red.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Error loading orders: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 12),
                          Text('No orders yet. Orders will appear here in real-time.'),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final orders = snapshot.data!.docs;
              final pending = orders.where((doc) => doc['status'] == 'pending').length;
              final accepted = orders.where((doc) => doc['status'] == 'accepted').length;
              final preparing = orders.where((doc) => doc['status'] == 'preparing').length;
              final ready = orders.where((doc) => doc['status'] == 'ready').length;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(child: _StatCard('Pending', pending.toString(), Colors.orange)),
                    const SizedBox(width: 8),
                    Expanded(child: _StatCard('Accepted', accepted.toString(), Colors.blue)),
                    const SizedBox(width: 8),
                    Expanded(child: _StatCard('Preparing', preparing.toString(), Colors.purple)),
                    const SizedBox(width: 8),
                    Expanded(child: _StatCard('Ready', ready.toString(), Colors.green)),
                  ],
                ),
              );
            },
          ),

          // Orders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore.getRestaurantOrders(widget.restaurantId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No orders yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          'Orders will appear here in real-time.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status'] ?? 'pending';
                      final table = data['tableNumber'] ?? 'Takeaway';
                      final items = data['items'] as List? ?? [];
                      final total = data['totalPrice'] ?? 0.0;
                      final timestamp = data['timestamp'] as Timestamp?;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.table_restaurant, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Table $table',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                items.map((i) => i['name']).join(', '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Rs ${total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  if (timestamp != null)
                                    Text(
                                      _formatTime(timestamp.toDate()),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: [
                                  _StatusButton(
                                    label: 'Accept',
                                    status: 'accepted',
                                    currentStatus: status,
                                    onPressed: () => _updateStatus(context, doc.id, 'accepted'),
                                    color: Colors.blue,
                                  ),
                                  _StatusButton(
                                    label: 'Prepare',
                                    status: 'preparing',
                                    currentStatus: status,
                                    onPressed: () => _updateStatus(context, doc.id, 'preparing'),
                                    color: Colors.purple,
                                  ),
                                  _StatusButton(
                                    label: 'Ready',
                                    status: 'ready',
                                    currentStatus: status,
                                    onPressed: () => _updateStatus(context, doc.id, 'ready'),
                                    color: Colors.green,
                                  ),
                                  _StatusButton(
                                    label: 'Complete',
                                    status: 'completed',
                                    currentStatus: status,
                                    onPressed: () => _updateStatus(context, doc.id, 'completed'),
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, String orderId, String newStatus) async {
    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      await firestore.updateOrderStatus(orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Order status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inMinutes < 1) return 'Just now';
    if (now.difference(time).inHours < 1) return '${now.difference(time).inMinutes}m ago';
    return '${now.difference(time).inHours}h ago';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final String status;
  final String currentStatus;
  final VoidCallback onPressed;
  final Color color;

  const _StatusButton({
    required this.label,
    required this.status,
    required this.currentStatus,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final statusOrder = ['pending', 'accepted', 'preparing', 'ready', 'completed'];
    final currentIndex = statusOrder.indexOf(currentStatus);
    final targetIndex = statusOrder.indexOf(status);

    // ✅ Enable ONLY if target is EXACTLY the next step
    final isEnabled = (targetIndex == currentIndex + 1);
    final isActive = (currentStatus == status);
    final isPast = (targetIndex < currentIndex);

    return ElevatedButton(
      onPressed: (isActive || !isEnabled || isPast) ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? color
            : (isEnabled ? Colors.blue.shade50 : Colors.grey[200]),
        foregroundColor: isActive ? Colors.white : (isEnabled ? Colors.blue : Colors.grey[600]),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(60, 30),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}