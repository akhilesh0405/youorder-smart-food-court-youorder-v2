import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context);
    final auth = Provider.of<AuthService>(context);

    // Check if user is authenticated
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.purple,
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
                'You need to be logged in to view the admin dashboard.',
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
        title: const Text('Mall Admin Dashboard'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing data...')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.getAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Error Loading Data',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
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
                    'No Orders Yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Orders will appear here when customers place orders.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs;
          final totalOrders = orders.length;
          final totalRevenue = orders.fold<double>(0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return sum + (data['totalPrice'] ?? 0.0);
          });

          // Count by restaurant
          final Map<String, int> restaurantCount = {};
          final Map<String, double> restaurantRevenue = {};
          for (var doc in orders) {
            final data = doc.data() as Map<String, dynamic>;
            final restId = data['restaurantId'] ?? 'Unknown';
            restaurantCount[restId] = (restaurantCount[restId] ?? 0) + 1;
            restaurantRevenue[restId] = (restaurantRevenue[restId] ?? 0) + (data['totalPrice'] ?? 0.0);
          }

          // Count by status
          final Map<String, int> statusCount = {};
          for (var doc in orders) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'unknown';
            statusCount[status] = (statusCount[status] ?? 0) + 1;
          }

          // Recent orders
          final recentOrders = orders.take(10).toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards Row 1
                  Row(
                    children: [
                      Expanded(
                        child: _AdminStatCard(
                          'Total Orders',
                          '$totalOrders',
                          Icons.receipt_long,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AdminStatCard(
                          'Total Revenue',
                          'Rs ${totalRevenue.toStringAsFixed(2)}',
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stats Cards Row 2 - Status
                  Row(
                    children: [
                      Expanded(
                        child: _AdminStatCard(
                          'Pending',
                          '${statusCount['pending'] ?? 0}',
                          Icons.pending,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AdminStatCard(
                          'Preparing',
                          '${statusCount['preparing'] ?? 0}',
                          Icons.kitchen,
                          Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AdminStatCard(
                          'Ready',
                          '${statusCount['ready'] ?? 0}',
                          Icons.room_service,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Restaurant Performance
                  const Text(
                    'Restaurant Performance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: restaurantCount.entries.map((entry) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple.withOpacity(0.1),
                              child: Text(entry.key.substring(0, 1).toUpperCase()),
                            ),
                            title: Text(entry.key),
                            subtitle: Text('${entry.value} orders'),
                            trailing: Text(
                              'Rs ${(restaurantRevenue[entry.key] ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Recent Orders
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Orders',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Showing ${recentOrders.length} of $totalOrders',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentOrders.length,
                    itemBuilder: (context, index) {
                      final doc = recentOrders[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status'] ?? 'pending';
                      final table = data['tableNumber'] ?? 'Takeaway';
                      final total = data['totalPrice'] ?? 0.0;
                      final restaurant = data['restaurantId'] ?? 'Unknown';
                      final timestamp = data['timestamp'] as Timestamp?;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                status.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          title: Text('Table $table - $restaurant'),
                          subtitle: Text('Status: $status'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
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
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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

class _AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AdminStatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}