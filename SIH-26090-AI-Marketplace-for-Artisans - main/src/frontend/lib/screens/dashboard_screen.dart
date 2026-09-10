import 'products_screen.dart';
import 'profile_screen.dart';
import 'image_studio_screen.dart';
import 'notifications_screen.dart';
import 'catalog_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth.dart';
import '../api.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> analytics = {};
  List<Map<String, dynamic>> artisanOrders = [];
  int unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    if (Auth.artisanId == null) return;
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/artisan/analytics?artisan_id=${Uri.encodeComponent(Auth.artisanId!)}')),
        http.get(Uri.parse('$apiBaseUrl/artisan/orders?artisan_id=${Uri.encodeComponent(Auth.artisanId!)}')),
        http.get(Uri.parse('$apiBaseUrl/notifications?user_id=${Uri.encodeComponent(Auth.artisanId!)}&limit=50')),
      ]);
      if (!mounted) return;
      setState(() {
        analytics = Map<String, dynamic>.from(jsonDecode(results[0].body));
        artisanOrders = List<Map<String, dynamic>>.from(jsonDecode(results[1].body));
        unreadNotifications = List<Map<String, dynamic>>.from(jsonDecode(results[2].body)).where((item) => item['read'] != true).length;
      });
    } catch (_) {
      // The dashboard remains useful when the backend is offline.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EB), // Warm Sand

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'CraftConnect',
          style: TextStyle(
            color: Color(0xFF2C221E), // Espresso
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
             IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
             icon: Badge(isLabelVisible: unreadNotifications > 0, label: Text('$unreadNotifications'), child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF2C221E))),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning, ${Auth.name ?? 'Artisan'}!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C221E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Let AI help you grow your craft business.',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF8C7A70),
              ),
            ),
            const SizedBox(height: 24),

            // Store summary card (Terracotta)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF9E4733), 
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Digital Store',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                         Text(
                           'Your craft marketplace',
                           style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _salesDashboard(),
            const SizedBox(height: 24),

            const Text(
              'AI Tools',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C221E),
              ),
            ),
            const SizedBox(height: 16),

            _largeFeatureCard(
              icon: Icons.camera_alt_rounded,
              title: 'Image Studio',
              subtitle: 'Enhance photos and create listings',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ImageStudioScreen()));
              },
            ),

            const SizedBox(height: 30),

            _largeFeatureCard(
              icon: Icons.storefront_rounded,
              title: 'Marketplace',
              subtitle: 'Browse and shop handmade products',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CatalogScreen()));
              },
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductsScreen()));
          }
          if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
          }
        },
        selectedItemColor: const Color(0xFF9E4733),
        unselectedItemColor: const Color(0xFF8C7A70),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _salesDashboard() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Sales Dashboard', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Color(0xFF2C221E))),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _metricCard(Icons.currency_rupee, 'Revenue', '₹${(analytics['revenue'] ?? 0).toStringAsFixed(0)}')),
        const SizedBox(width: 10),
        Expanded(child: _metricCard(Icons.inventory_2_outlined, 'Products Sold', '${analytics['products_sold'] ?? 0}')),
      ]),
      const SizedBox(height: 14),
      ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        collapsedBackgroundColor: Colors.white,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Orders Management', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C221E))),
        subtitle: Text('${artisanOrders.length} recent orders', style: const TextStyle(color: Color(0xFF8C7A70), fontSize: 12)),
        children: artisanOrders.take(5).expand((order) => (order['items'] as List? ?? []).map<Widget>((item) => _orderManagementRow(order, Map<String, dynamic>.from(item)))).toList(),
      ),
    ]);
  }

  Widget _metricCard(IconData icon, String label, String value) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFEADCCF), borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: const Color(0xFF9E4733)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C221E))),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8C7A70))),
        ]),
      );

  Widget _orderManagementRow(Map<String, dynamic> order, Map<String, dynamic> item) {
    const statuses = ['placed', 'dispatched', 'in_transit', 'delivered'];
    final selected = statuses.contains(item['status']) ? item['status'] as String : 'placed';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(children: [
        Expanded(child: Text(item['name']?.toString() ?? 'Product', style: const TextStyle(color: Color(0xFF2C221E)))),
        DropdownButton<String>(
          value: selected,
          items: statuses.map((status) => DropdownMenuItem(value: status, child: Text(status.replaceAll('_', ' ')))).toList(),
          onChanged: (status) async {
            if (status == null || Auth.artisanId == null) return;
            await http.patch(
              Uri.parse('$apiBaseUrl/orders/${order['_id']}/item-status'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'product_id': item['product_id'], 'artisan_id': Auth.artisanId, 'status': status}),
            );
            _loadSalesData();
          },
        ),
      ]),
    );
  }

  Widget _featureCard({required IconData icon, required String title, required String subtitle, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 155,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: const Color(0xFFD48331)), // Amber Accent
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C221E)),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8C7A70)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _largeFeatureCard({required IconData icon, required String title, required String subtitle, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFEADCCF), // Almond
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: const Color(0xFFD48331), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2C221E))),
                  const SizedBox(height: 5),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF8C7A70))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF9E4733)),
          ],
        ),
      ),
    );
  }

  Widget _productTile({required IconData icon, required String name, required String status}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: const Color(0xFFF5F2EB), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: const Color(0xFF9E4733)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C221E)))),
          Text(status, style: const TextStyle(fontSize: 12, color: Color(0xFF9E4733), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}