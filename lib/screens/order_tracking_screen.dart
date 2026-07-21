import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestore.getOrderStream(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'pending';
          final tableNumber = data['tableNumber'] ?? 'Takeaway';
          final totalPrice = data['totalPrice'] ?? 0.0;
          final items = data['items'] as List? ?? [];
          final estimatedWait = data['estimatedWaitTime'] ?? 10;

          // Status steps
          final statusSteps = ['pending', 'accepted', 'preparing', 'ready', 'completed'];
          final currentStepIndex = statusSteps.indexOf(status);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Order #',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              orderId.substring(0, 8).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Table'),
                            Text(
                              tableNumber,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total'),
                            Text(
                              'Rs ${totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimated Wait'),
                            Text(
                              '$estimatedWait minutes',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Status Timeline
                const Text(
                  'Order Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: statusSteps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final step = statusSteps[index];
                      final isCompleted = index <= currentStepIndex;
                      final isCurrent = index == currentStepIndex;
                      final isPast = index < currentStepIndex;

                      IconData icon;
                      Color color;
                      switch (step) {
                        case 'pending':
                          icon = Icons.receipt_long;
                          color = isCompleted ? Colors.orange : Colors.grey;
                          break;
                        case 'accepted':
                          icon = Icons.check_circle;
                          color = isCompleted ? Colors.blue : Colors.grey;
                          break;
                        case 'preparing':
                          icon = Icons.kitchen;
                          color = isCompleted ? Colors.orange : Colors.grey;
                          break;
                        case 'ready':
                          icon = Icons.room_service;
                          color = isCompleted ? Colors.green : Colors.grey;
                          break;
                        case 'completed':
                          icon = Icons.done_all;
                          color = isCompleted ? Colors.green : Colors.grey;
                          break;
                        default:
                          icon = Icons.circle;
                          color = Colors.grey;
                      }

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.2),
                          ),
                          child: Icon(icon, color: color),
                        ),
                        title: Text(
                          step.toUpperCase(),
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isPast ? Colors.grey : Colors.black,
                          ),
                        ),
                        trailing: isCurrent
                            ? const Icon(Icons.arrow_forward, color: Colors.blue)
                            : isPast
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                      );
                    },
                  ),
                ),

                // Order Items
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: items.map<Widget>((item) {
                          return ListTile(
                            title: Text(item['name'] ?? 'Unknown'),
                            subtitle: Text('x${item['quantity'] ?? 1}'),
                            trailing: Text(
                              'Rs ${(item['price'] ?? 0.0).toStringAsFixed(2)}',
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}