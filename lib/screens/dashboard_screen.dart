import 'products_screen.dart';
import 'profile_screen.dart';
import 'image_studio_screen.dart';
import 'auto_catalog_screen.dart';
import 'smart_pricing_screen.dart';
import 'notifications_screen.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'CraftConnect',
          style: TextStyle(
            color: Color(0xFF35243A),
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
  icon: const Icon(
    Icons.notifications_none_rounded,
    color: Color(0xFF35243A),
  ),
),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good morning, Artisan!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF35243A),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Let AI help you grow your craft business.',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF6B6170),
              ),
            ),

            const SizedBox(height: 24),

            // Store summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF6B4E71),
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
                          '12 Products Listed',
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

            const Text(
              'AI Tools',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF35243A),
              ),
            ),

            const SizedBox(height: 16),

            // First two feature cards
            Row(
              children: [
                Expanded(
                  child: _featureCard(
                    icon: Icons.camera_alt_rounded,
                    title: 'Image Studio',
                    subtitle: 'Enhance photos',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ImageStudioScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _featureCard(
                    icon: Icons.mic_rounded,
                    title: 'Auto Catalog',
                    subtitle: 'Create listings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AutoCatalogScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Pricing feature
            _largeFeatureCard(
              icon: Icons.currency_rupee_rounded,
              title: 'Smart Pricing',
              subtitle: 'Get competitive price suggestions',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SmartPricingScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            const Text(
              'Recent Products',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF35243A),
              ),
            ),

            const SizedBox(height: 14),

            _productTile(
              icon: Icons.shopping_bag_outlined,
              name: 'Handcrafted Basket',
              status: 'Listed',
            ),

            const SizedBox(height: 10),

            _productTile(
              icon: Icons.checkroom_outlined,
              name: 'Handwoven Textile',
              status: 'Draft',
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if(index==1){
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductsScreen()));
          }
        
        if(index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }
        },
        selectedItemColor: const Color(0xFF6B4E71),
        unselectedItemColor: const Color(0xFF9A909D),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap:onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
      height: 155,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 34,
            color: const Color(0xFF6B4E71),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF35243A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B6170),
            ),
          ),
        ],
      ),
      )
    );
  }

  Widget _largeFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap:onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8DDEC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6B4E71),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF35243A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B6170),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Color(0xFF6B4E71),
          ),
        ],
      ),
      )
    );
  }

  Widget _productTile({
    required IconData icon,
    required String name,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8DDEC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6B4E71),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF35243A),
              ),
            ),
          ),
          Text(
            status,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B4E71),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}