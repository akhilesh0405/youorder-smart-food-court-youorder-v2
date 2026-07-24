import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../widgets/app_theme.dart';
import '../widgets/modern_widgets.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const MenuScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context);
    final cart = Provider.of<CartProvider>(context);
    
    // Determine restaurant color
    final themeColor = widget.restaurantName.toLowerCase().contains('kfc') 
        ? const Color(0xFFE4002B) 
        : (widget.restaurantName.toLowerCase().contains('panarottis') 
            ? const Color(0xFF0061C1) 
            : AppTheme.primaryColor);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Branded Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            widget.restaurantName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on_rounded, size: 12, color: Colors.white70),
                              SizedBox(width: 4),
                              Text(
                                'Grand Baie Mall',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_basket_outlined, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CartScreen()),
                            );
                          },
                        ),
                        if (cart.itemCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                '${cart.itemCount}',
                                style: TextStyle(
                                  color: themeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Categories Horizontal Scroll
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('All'),
                      _buildCategoryChip('Burgers'),
                      _buildCategoryChip('Chicken'),
                      _buildCategoryChip('Sides'),
                      _buildCategoryChip('Drinks'),
                      _buildCategoryChip('Pizzas'),
                      _buildCategoryChip('Pastas'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Items List
          Expanded(
            child: StreamBuilder<List<MenuItem>>(
              stream: firestore.getMenuItems(widget.restaurantId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var items = snapshot.data ?? [];
                
                // Filter by category
                if (_selectedCategory != 'All') {
                  items = items.where((item) => 
                    item.category.toLowerCase().contains(_selectedCategory.toLowerCase())
                  ).toList();
                }

                if (items.isEmpty) {
                  return const Center(child: Text('No menu items available in this category.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ModernFoodCard(
                      name: item.name,
                      imageUrl: item.imageUrl,
                      price: item.price,
                      category: item.category,
                      onTap: () {
                        cart.addItem(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added ${item.name} to cart!'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: themeColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      trailing: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0061C1).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Color(0xFF0061C1),
                          size: 24,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
