import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context);
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(auth),
          
          // Main Workspace
          Expanded(
            child: Column(
              children: [
                // Header
                _buildHeader(auth),
                
                // Content
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: firestore.getAllOrders(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final orders = snapshot.data?.docs ?? [];
                      return _buildDashboardContent(orders);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(AuthService auth) {
    return Container(
      width: 260,
      color: const Color(0xFF1D2939),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: const [
                Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text('YouOrder', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('Admin Control Panel', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          const SizedBox(height: 40),
          _buildSidebarItem(0, 'Overview', Icons.grid_view_rounded),
          _buildSidebarItem(1, 'All Orders', Icons.shopping_bag_rounded),
          _buildSidebarItem(2, 'Restaurants', Icons.restaurant_rounded),
          _buildSidebarItem(3, 'Customers', Icons.people_rounded),
          _buildSidebarItem(4, 'Analytics', Icons.analytics_rounded),
          const Spacer(),
          ListTile(
            onTap: () => auth.signOut(),
            leading: const Icon(Icons.logout_rounded, color: Colors.white54),
            title: const Text('Logout', style: TextStyle(color: Colors.white54)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => setState(() => _selectedIndex = index),
        leading: Icon(icon, color: isSelected ? Colors.blue : Colors.white54),
        title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildHeader(AuthService auth) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      color: Colors.white,
      child: Row(
        children: [
          const Text('Food Court Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
          const Spacer(),
          const Text('Grand Baie Mall', style: TextStyle(color: Colors.grey)),
          const SizedBox(width: 20),
          const CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: Icon(Icons.person_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(List<QueryDocumentSnapshot> orders) {
    final totalRevenue = orders.fold<double>(0, (sum, doc) => sum + (doc['totalPrice'] ?? 0.0));
    final pending = orders.where((doc) => doc['status'] == 'pending').length;
    final preparing = orders.where((doc) => doc['status'] == 'preparing').length;
    final ready = orders.where((doc) => doc['status'] == 'ready').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Stat Cards Row
          Row(
            children: [
              _buildStatCard('Total Orders', '${orders.length}', Icons.shopping_cart_rounded, Colors.blue),
              const SizedBox(width: 20),
              _buildStatCard('Total Revenue', 'Rs ${totalRevenue.toStringAsFixed(0)}', Icons.monetization_on_rounded, Colors.green),
              const SizedBox(width: 20),
              _buildStatCard('Pending', '$pending', Icons.pending_actions_rounded, Colors.orange),
              const SizedBox(width: 20),
              _buildStatCard('Preparing', '$preparing', Icons.kitchen_rounded, Colors.purple),
              const SizedBox(width: 20),
              _buildStatCard('Ready', '$ready', Icons.check_circle_rounded, Colors.teal),
            ],
          ),
          const SizedBox(height: 32),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Performance
              Expanded(
                flex: 1,
                child: _buildWhiteCard(
                  title: 'Restaurant Performance',
                  child: Column(
                    children: [
                      _buildPerformanceItem('KFC Mauritius', 4, 1896, Colors.red),
                      _buildPerformanceItem('Panarottis Pizza Pasta', 4, 2207, Colors.blue),
                      const Divider(height: 40),
                      _buildSummaryRow('Total Revenue', 'Rs ${totalRevenue.toStringAsFixed(0)}', isBold: true),
                      _buildSummaryRow('Total Orders', '${orders.length}', isBold: false),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 32),
              
              // Recent Orders
              Expanded(
                flex: 2,
                child: _buildWhiteCard(
                  title: 'Recent Orders',
                  child: DataTable(
                    horizontalMargin: 0,
                    columns: const [
                      DataColumn(label: Text('ORDER ID')),
                      DataColumn(label: Text('RESTAURANT')),
                      DataColumn(label: Text('TABLE')),
                      DataColumn(label: Text('STATUS')),
                      DataColumn(label: Text('TOTAL')),
                    ],
                    rows: orders.take(7).map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DataRow(cells: [
                        DataCell(Text('ORD-${doc.id.substring(0, 4).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(data['restaurantId']?.split('_')[0].toUpperCase() ?? 'N/A')),
                        DataCell(Text(data['tableNumber'] ?? 'N/A')),
                        DataCell(_buildStatusBadge(data['status'])),
                        DataCell(Text('Rs ${data['totalPrice']}')),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
            Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(String name, int orders, int revenue, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('$orders orders • Rs $revenue', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: 0.7, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(color), minHeight: 6, borderRadius: BorderRadius.circular(10)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {required bool isBold}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'pending') color = Colors.orange;
    if (status == 'preparing') color = Colors.purple;
    if (status == 'ready') color = Colors.teal;
    if (status == 'accepted') color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DashboardSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: child,
        ),
      ],
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  final Map<String, double> data;
  const _RevenueBarChart(this.data);

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: entries.isEmpty ? 100 : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < entries.length) {
                  return Text(entries[value.toInt()].key.split('_')[0].toUpperCase(), style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(entries.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entries[i].value,
                color: AppTheme.primaryColor,
                width: 40,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _StatusPieChart extends StatelessWidget {
  final Map<String, int> data;
  const _StatusPieChart(this.data);

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sections: data.entries.map((e) {
          final color = _getStatusColor(e.key);
          return PieChartSectionData(
            value: e.value.toDouble(),
            title: '${e.value}',
            color: color,
            radius: 50,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          );
        }).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'preparing': return Colors.blue;
      case 'ready': return Colors.green;
      case 'completed': return Colors.grey;
      default: return Colors.purple;
    }
  }
}

class _RecentOrdersTable extends StatelessWidget {
  final List<QueryDocumentSnapshot> orders;
  const _RecentOrdersTable(this.orders);

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columnSpacing: 20,
      columns: const [
        DataColumn(label: Text('Order ID')),
        DataColumn(label: Text('Restaurant')),
        DataColumn(label: Text('Total')),
        DataColumn(label: Text('Status')),
      ],
      rows: orders.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'pending';
        return DataRow(cells: [
          DataCell(Text(doc.id.substring(0, 5).toUpperCase())),
          DataCell(Text(data['restaurantId']?.split('_')[0].toUpperCase() ?? 'N/A')),
          DataCell(Text('Rs ${data['totalPrice']}')),
          DataCell(Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(status.toUpperCase(), style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold)),
          )),
        ]);
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'preparing': return Colors.blue;
      case 'ready': return Colors.green;
      case 'completed': return Colors.grey;
      default: return Colors.purple;
    }
  }
}