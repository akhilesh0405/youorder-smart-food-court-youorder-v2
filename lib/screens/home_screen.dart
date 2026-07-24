import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/restaurant.dart';
import '../widgets/app_theme.dart';
import '../widgets/modern_widgets.dart';
import 'menu_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'order_tracking_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final firestore = Provider.of<FirestoreService>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Blue Background Header
          Container(
            height: 250,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Custom App Bar Elements
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 28),
                            const SizedBox(width: 8),
                            const Text(
                              'YouOrder',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout_rounded, color: Colors.white),
                              onPressed: () => auth.signOut(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search restaurants...',
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                        fillColor: Colors.white.withOpacity(0.15),
                        filled: true,
                        hintStyle: const TextStyle(color: Colors.white70),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                
                // User Greeting Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Good afternoon,',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                auth.user?.displayName ?? 'John Doe',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('👋', style: TextStyle(fontSize: 20)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                'Table T-07 • Grand Baie Food Court',
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Restaurants Section
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Restaurants Near You',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ),
                ),
                
                StreamBuilder<List<Restaurant>>(
                  stream: firestore.getRestaurants(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                    }
                    final restaurants = snapshot.data ?? [];
                    return SliverToBoxAdapter(
                      child: SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: restaurants.length,
                          itemBuilder: (context, index) {
                            final restaurant = restaurants[index];
                            return ModernRestaurantCard(
                              name: restaurant.name,
                              imageUrl: restaurant.imageUrl,
                              location: restaurant.location,
                              rating: restaurant.rating,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MenuScreen(
                                      restaurantId: restaurant.id,
                                      restaurantName: restaurant.name,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                
                // Quick Access Grid
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 30, 20, 10),
                    child: Text(
                      'Quick Access',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ),
                ),
                
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildQuickAccessItem(
                        context, 
                        'My Cart', 
                        Icons.shopping_cart_outlined, 
                        const Color(0xFFE3F2FD), 
                        Colors.blue, 
                        const CartScreen()
                      ),
                      _buildQuickAccessItem(
                        context, 
                        'Tracking', 
                        Icons.access_time_rounded, 
                        const Color(0xFFFFF3E0), 
                        Colors.orange, 
                        null, 
                        onTap: () async {
                          print('📡 Finding latest order for tracking...');
                          final uid = auth.user?.uid;
                          if (uid == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in again.')));
                            return;
                          }
                          
                          // Show a small loader snackbar while searching
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Searching for your latest order...'), duration: Duration(seconds: 1)),
                          );

                          try {
                            final ordersSnapshot = await FirebaseFirestore.instance
                                .collection('orders')
                                .where('userId', isEqualTo: uid)
                                .get();
                            
                            if (ordersSnapshot.docs.isNotEmpty && context.mounted) {
                              // Find latest order manually
                              final docs = List<QueryDocumentSnapshot>.from(ordersSnapshot.docs);
                              docs.sort((a, b) {
                                final t1 = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                                final t2 = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                                if (t1 == null) return 1;
                                if (t2 == null) return -1;
                                return t2.compareTo(t1);
                              });
                              
                              final orderId = docs.first.id;
                              print('✅ Found latest order: $orderId');
                              Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)));
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active orders to track')));
                            }
                          } catch (e) {
                            print('❌ Tracking error: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error finding order: $e')));
                            }
                          }
                        }
                      ),
                      _buildQuickAccessItem(
                        context, 
                        'Orders', 
                        Icons.history_rounded, 
                        const Color(0xFFE8F5E9), 
                        Colors.green, 
                        const OrderHistoryScreen()
                      ),
                    ],
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessItem(BuildContext context, String label, IconData icon, Color bgColor, Color iconColor, Widget? target, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {
        if (target != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => target));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: iconColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final IconData icon;

  const _CategoryItem(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}