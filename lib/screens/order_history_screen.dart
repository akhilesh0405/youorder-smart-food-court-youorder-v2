import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_theme.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final firestore = Provider.of<FirestoreService>(context);
    final userId = auth.user?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.secondaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.getUserOrders(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          
          final orders = snapshot.data?.docs ?? [];
          
          // Sort in memory to avoid Firebase Index requirements
          final sortedOrders = List<QueryDocumentSnapshot>.from(orders);
          sortedOrders.sort((a, b) {
            final t1 = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            final t2 = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            if (t1 == null) return 1;
            if (t2 == null) return -1;
            return t2.compareTo(t1); // Descending
          });
          
          if (sortedOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 80, color: Colors.grey[200]),
                  const SizedBox(height: 16),
                  const Text('No orders found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const Text('Your past orders will appear here', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';
              final total = data['totalPrice'] ?? 0.0;
              final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
              final items = data['items'] as List? ?? [];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[100]!),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: doc.id)),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                            _buildStatusBadge(status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          items.map((i) => "${i['quantity']}x ${i['name']}").join(', '),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Order ID: #${doc.id.substring(0, 6).toUpperCase()}', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                            Text(
                              'Rs ${total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'pending') color = Colors.orange;
    if (status == 'accepted') color = Colors.blue;
    if (status == 'preparing') color = Colors.purple;
    if (status == 'ready') color = Colors.teal;
    if (status == 'completed') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}