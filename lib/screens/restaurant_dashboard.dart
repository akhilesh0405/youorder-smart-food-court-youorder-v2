import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_theme.dart';

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
        setState(() => _restaurantName = restaurant?.name ?? widget.restaurantId);
      }
    } catch (e) {
      if (mounted) setState(() => _restaurantName = widget.restaurantId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context);
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('$_restaurantName Panel'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
            onPressed: () => auth.signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.getRestaurantOrders(widget.restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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

          final pending = sortedOrders.where((doc) => doc['status'] == 'pending').length;
          final active = sortedOrders.where((doc) => ['accepted', 'preparing'].contains(doc['status'])).length;
          final ready = sortedOrders.where((doc) => doc['status'] == 'ready').length;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Row
                Row(
                  children: [
                    Expanded(child: _SummaryCard('New Orders', '$pending', Colors.orange, Icons.new_releases_rounded)),
                    const SizedBox(width: 20),
                    Expanded(child: _SummaryCard('In Progress', '$active', Colors.blue, Icons.restaurant_rounded)),
                    const SizedBox(width: 20),
                    Expanded(child: _SummaryCard('Ready', '$ready', Colors.green, Icons.check_circle_rounded)),
                  ],
                ),
                const SizedBox(height: 32),
                
                Text(
                  'Order Queue',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: sortedOrders.isEmpty
                      ? const Center(child: Text('No active orders'))
                      : ListView.builder(
                          itemCount: sortedOrders.length,
                          itemBuilder: (context, index) {
                            final doc = sortedOrders[index];
                            final data = doc.data() as Map<String, dynamic>;
                            return _OrderListItem(orderId: doc.id, data: data, onUpdate: (status) => _updateStatus(context, doc.id, status));
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _updateStatus(BuildContext context, String orderId, String newStatus) async {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    await firestore.updateOrderStatus(orderId, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order $newStatus'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
      );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _OrderListItem extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final Function(String) onUpdate;

  const _OrderListItem({required this.orderId, required this.data, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'pending';
    final items = data['items'] as List? ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Order #${orderId.substring(0, 5).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 12),
                    _StatusBadge(status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(items.map((i) => "${i['quantity']}x ${i['name']}").join(', '), style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 4),
                Text('Table: ${data['tableNumber']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.primaryColor)),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              if (status == 'pending') 
                _ActionButton('Accept', () => onUpdate('accepted'), Colors.blue),
              if (status == 'accepted') 
                _ActionButton('Prepare', () => onUpdate('preparing'), Colors.orange),
              if (status == 'preparing') 
                _ActionButton('Ready', () => onUpdate('ready'), Colors.green),
              if (status == 'ready') 
                _ActionButton('Complete', () => onUpdate('completed'), Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (status == 'pending') color = Colors.orange;
    if (status == 'preparing') color = Colors.blue;
    if (status == 'ready') color = Colors.green;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton(this.label, this.onTap, this.color);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}