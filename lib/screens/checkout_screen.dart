import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_theme.dart';
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
          behavior: SnackBarBehavior.floating,
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
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Checkout',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Spacer for centering
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Order Type'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildOrderTypeButton('Dine-in', Icons.chair_alt_rounded),
                      const SizedBox(width: 16),
                      _buildOrderTypeButton('Takeaway', Icons.shopping_bag_outlined),
                    ],
                  ),
                  const SizedBox(height: 30),

                  if (_orderType == 'Dine-in') ...[
                    _buildSectionLabel('Table Number'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tableController,
                      decoration: const InputDecoration(
                        hintText: 'T-07',
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

                  _buildSectionLabel('Order Summary'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        ...cart.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item.quantity}× ${item.menuItem.name}',
                                style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.secondaryColor),
                              ),
                              Text(
                                'Rs ${item.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                              ),
                            ],
                          ),
                        )),
                        const Divider(height: 32),
                        _buildPriceRow('Subtotal', 'Rs ${cart.totalAmount.toStringAsFixed(2)}', isTotal: false),
                        _buildPriceRow('Service Fee', 'Rs 15.00', isTotal: false),
                        const SizedBox(height: 8),
                        _buildPriceRow('Total', 'Rs ${(cart.totalAmount + 15).toStringAsFixed(2)}', isTotal: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildSectionLabel('Payment Method'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_outlined, color: AppTheme.primaryColor),
                        const SizedBox(width: 16),
                        const Text('Pay at Counter', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // Bottom CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
            child: SizedBox(
              width: double.infinity,
              height: 65,
              child: ElevatedButton(
                onPressed: _isPlacingOrder ? null : () => _placeOrder(context, cart),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: _isPlacingOrder
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 22),
                          const SizedBox(width: 10),
                          Text('Place Order - Rs ${(cart.totalAmount + 15).toStringAsFixed(2)}'),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
    );
  }

  Widget _buildOrderTypeButton(String type, IconData icon) {
    final isSelected = _orderType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _orderType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white,
            border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!, width: 2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.1), blurRadius: 10)] : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {required bool isTotal}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppTheme.secondaryColor : Colors.grey[500],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.bold,
              color: isTotal ? AppTheme.secondaryColor : AppTheme.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}