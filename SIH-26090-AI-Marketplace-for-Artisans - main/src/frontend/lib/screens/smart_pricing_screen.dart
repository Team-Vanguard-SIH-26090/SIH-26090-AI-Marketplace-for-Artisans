import 'package:flutter/material.dart';

class SmartPricingScreen extends StatelessWidget {
  const SmartPricingScreen({super.key});

  // --- UPDATED TERRACOTTA THEME COLORS ---
  static const Color background = Color(0xFFF5F2EB); // Warm Sand
  static const Color primaryPurple = Color(0xFF9E4733); // Terracotta 
  static const Color lightLavender = Color(0xFFEADCCF); // Soft Almond
  static const Color textDark = Color(0xFF2C221E); // Espresso Brown
  static const Color textMuted = Color(0xFF8C7A70); // Earthy Grey

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        title: const Text(
          'Smart Pricing',
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const Text(
              'Get a smart price suggestion for your handmade products.',
              style: TextStyle(
                fontSize: 15,
                color: textMuted,
              ),
            ),

            const SizedBox(height: 24),

            // Product details
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    'Product Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),

                  const SizedBox(height: 18),

                  _detailRow(
                    Icons.shopping_bag_outlined,
                    'Product',
                    'Handcrafted Basket',
                  ),

                  const SizedBox(height: 14),

                  _detailRow(
                    Icons.category_outlined,
                    'Category',
                    'Home Decor',
                  ),

                  const SizedBox(height: 14),

                  _detailRow(
                    Icons.spa_outlined,
                    'Material',
                    'Natural Bamboo',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // AI result
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: lightLavender,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [

                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: primaryPurple,
                    size: 34,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'AI Suggested Price',
                    style: TextStyle(
                      fontSize: 16,
                      color: textMuted,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    '₹850',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: primaryPurple,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Recommended range: ₹750 – ₹950',
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Why this price?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'The suggested price considers the product category, '
                'material, craftsmanship and estimated market value. '
                'You can adjust the final price according to your needs.',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'AI is calculating the best price for your product...',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text(
                  'Get Smart Price',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'AI-powered pricing assistance for your craft business.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: lightLavender,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: primaryPurple,
            size: 22,
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
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}