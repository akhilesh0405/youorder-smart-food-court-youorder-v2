import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _orderType = 'Dine-in';
  final TextEditingController _tableController = TextEditingController();
  bool _isPlacingOrder = false;

  Future<void> _placeOrder(BuildContext context, CartProvider cart) async {
    if (_orderType == 'Dine-in' && _tableController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a table number.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final userId = auth.user?.uid ?? 'anonymous';

      final orderData = {
        'restaurantId': cart.items.isNotEmpty ? cart.items.first.menuItem.restaurantId : '',
        'userId': userId,
        'tableNumber': _orderType == 'Dine-in' ? _tableController.text.trim() : 'Takeaway',
        'items': cart.getOrderItems(),
        'status': 'pending',
        'totalPrice': cart.totalAmount,
        'timestamp': FieldValue.serverTimestamp(),
        'estimatedWaitTime': 10,
      };

      final orderId = await firestore.placeOrder(orderData);
      print('✅ Order placed with ID: $orderId');

      cart.clearCart();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(orderId: orderId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Type Selection
            const Text(
              'Order Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: _orderType == 'Dine-in'
                        ? Colors.blue.withOpacity(0.1)
                        : null,
                    child: ListTile(
                      title: const Text('Dine-in'),
                      leading: Radio(
                        value: 'Dine-in',
                        groupValue: _orderType,
                        onChanged: (value) {
                          setState(() => _orderType = value!);
                        },
                      ),
                      onTap: () => setState(() => _orderType = 'Dine-in'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    color: _orderType == 'Takeaway'
                        ? Colors.blue.withOpacity(0.1)
                        : null,
                    child: ListTile(
                      title: const Text('Takeaway'),
                      leading: Radio(
                        value: 'Takeaway',
                        groupValue: _orderType,
                        onChanged: (value) {
                          setState(() => _orderType = value!);
                        },
                      ),
                      onTap: () => setState(() => _orderType = 'Takeaway'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Table Number (only for Dine-in)
            if (_orderType == 'Dine-in') ...[
              const Text(
                'Table Number',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tableController,
                decoration: const InputDecoration(
                  labelText: 'Enter table number (e.g., A12)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.table_restaurant),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tip: Enter the table number printed on your table.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],

            if (_orderType == 'Takeaway') ...[
              const Card(
                color: Colors.green,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.takeout_dining, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You will pick up your order from the counter.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Order Summary
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: cart.items.length,
                          itemBuilder: (context, index) {
                            final item = cart.items[index];
                            return ListTile(
                              title: Text(item.menuItem.name),
                              subtitle: Text(
                                'Rs ${item.menuItem.price.toStringAsFixed(2)} x ${item.quantity}',
                              ),
                              trailing: Text(
                                'Rs ${item.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(thickness: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rs ${cart.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Place Order Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPlacingOrder ? null : () => _placeOrder(context, cart),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.green,
                ),
                child: _isPlacingOrder
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Place Order',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}