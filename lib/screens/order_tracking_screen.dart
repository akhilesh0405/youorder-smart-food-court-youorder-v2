import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../widgets/app_theme.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestore.getOrderStream(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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

          return Column(
            children: [
              // Summary Header
              Container(
                padding: const EdgeInsets.fromLTRB(30, 60, 30, 30),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHeaderInfo('Order ID', 'ORD-${orderId.substring(0, 4).toUpperCase()}'),
                        _buildHeaderInfo('Table', tableNumber),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHeaderInfo('Total', 'Rs ${totalPrice.toStringAsFixed(2)}'),
                        _buildHeaderInfo('Est. Wait', '~$estimatedWait min'),
                      ],
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Status',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                      ),
                      const SizedBox(height: 30),
                      
                      _buildStatusItem('Order Placed', 'Waiting for restaurant', Icons.access_time_rounded, status, 'pending'),
                      _buildStatusLine(status, 'pending'),
                      _buildStatusItem('Accepted', 'Restaurant confirmed', Icons.check_circle_rounded, status, 'accepted'),
                      _buildStatusLine(status, 'accepted'),
                      _buildStatusItem('Preparing', 'Kitchen is cooking', Icons.restaurant_rounded, status, 'preparing'),
                      _buildStatusLine(status, 'preparing'),
                      _buildStatusItem('Ready', 'Pick up your order', Icons.notifications_active_rounded, status, 'ready'),
                      _buildStatusLine(status, 'ready'),
                      _buildStatusItem('Completed', 'Enjoy your meal!', Icons.check_circle_outline_rounded, status, 'completed'),
                      
                      const SizedBox(height: 50),
                      
                      const Text(
                        'Items Ordered',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: items.map<Widget>((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${item['quantity']}× ${item['name']}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text('Rs ${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                          child: const Text('Back to Home', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatusItem(String title, String subtitle, IconData icon, String currentStatus, String itemStatus) {
    final statusOrder = ['pending', 'accepted', 'preparing', 'ready', 'completed'];
    final currentIndex = statusOrder.indexOf(currentStatus);
    final itemIndex = statusOrder.indexOf(itemStatus);
    
    final isCompleted = itemIndex < currentIndex;
    final isCurrent = itemIndex == currentIndex;
    final isPending = itemIndex > currentIndex;

    Color iconColor = isCompleted ? Colors.green : (isCurrent ? (itemStatus == 'preparing' ? Colors.blue : Colors.green) : Colors.grey[300]!);
    Color textColor = isPending ? Colors.grey[400]! : AppTheme.secondaryColor;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor,
            shape: BoxShape.circle,
            boxShadow: isCurrent ? [BoxShadow(color: iconColor.withOpacity(0.3), blurRadius: 10)] : null,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            Text(subtitle, style: TextStyle(color: isPending ? Colors.grey[300] : Colors.grey[500], fontSize: 12)),
            if (isCurrent && itemStatus == 'preparing')
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('••• In progress', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusLine(String currentStatus, String afterStatus) {
    final statusOrder = ['pending', 'accepted', 'preparing', 'ready', 'completed'];
    final currentIndex = statusOrder.indexOf(currentStatus);
    final afterIndex = statusOrder.indexOf(afterStatus);
    
    final isCompleted = afterIndex < currentIndex;

    return Container(
      margin: const EdgeInsets.only(left: 19),
      height: 30,
      width: 2,
      color: isCompleted ? Colors.green : Colors.grey[200],
    );
  }
}
