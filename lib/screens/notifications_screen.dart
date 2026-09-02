import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const Color background = Color(0xFFF7F5FB);
  static const Color primaryPurple = Color(0xFF7C5CBF);
  static const Color lightLavender = Color(0xFFEDE7F6);
  static const Color textDark = Color(0xFF2D2A3D);
  static const Color textMuted = Color(0xFF6F6C7D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: textDark,
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Stay updated with your craft business.',
              style: TextStyle(
                fontSize: 15,
                color: textMuted,
              ),
            ),

            const SizedBox(height: 24),

            _notificationCard(
              icon: Icons.auto_awesome_rounded,
              title: 'AI Image Ready',
              message:
                  'Your product photo has been enhanced successfully.',
              time: 'Just now',
            ),

            const SizedBox(height: 12),

            _notificationCard(
              icon: Icons.currency_rupee_rounded,
              title: 'Smart Pricing Update',
              message:
                  'Your latest product has a suggested price of ₹850.',
              time: '2 hours ago',
            ),

            const SizedBox(height: 12),

            _notificationCard(
              icon: Icons.inventory_2_outlined,
              title: 'Product Listed',
              message:
                  'Your Handwoven Basket has been added to your digital store.',
              time: 'Yesterday',
            ),

            const SizedBox(height: 12),

            _notificationCard(
              icon: Icons.storefront_outlined,
              title: 'Welcome to CraftConnect',
              message:
                  'Start adding your products and grow your digital store.',
              time: '2 days ago',
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationCard({
    required IconData icon,
    required String title,
    required String message,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: lightLavender,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: primaryPurple,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: textMuted,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: primaryPurple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}