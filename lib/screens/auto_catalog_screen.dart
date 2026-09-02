import 'package:flutter/material.dart';
import 'products_screen.dart';

class AutoCatalogScreen extends StatefulWidget {
  const AutoCatalogScreen({super.key});
  @override
  State<AutoCatalogScreen> createState() => _AutoCatalogScreenState();
}
  class _AutoCatalogScreenState extends State<AutoCatalogScreen> {

  static const Color background = Color(0xFFF7F5FB);
  static const Color primaryPurple = Color(0xFF7C5CBF);
  static const Color lightLavender = Color(0xFFEDE7F6);
  static const Color textDark = Color(0xFF2D2A3D);
  static const Color textMuted = Color(0xFF6F6C7D);
  String selectedLanguage = 'English';
 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        title: const Text(
          'Auto Catalog',
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
              'Turn your craft into a professional product listing.',
              style: TextStyle(
                fontSize: 15,
                color: textMuted,
              ),
            ),

            const SizedBox(height: 24),

            // Voice input card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: lightLavender,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_none_rounded,
                      size: 38,
                      color: primaryPurple,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Describe your product',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    'Speak naturally in your preferred language.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Voice input started. Describe your product naturally.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.mic_rounded),
                      label: const Text('Start Voice Input'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryPurple,
                        side: const BorderSide(
                          color: primaryPurple,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Generated Listing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),

            const SizedBox(height: 14),

            // Product name
            _infoCard(
              icon: Icons.shopping_bag_outlined,
              title: 'Product Name',
              value: 'Handcrafted Traditional Basket',
            ),

            const SizedBox(height: 12),

            // Category
            _infoCard(
              icon: Icons.category_outlined,
              title: 'Category',
              value: 'Handmade & Home Decor',
            ),

            const SizedBox(height: 12),

            // Description
            _infoCard(
              icon: Icons.description_outlined,
              title: 'Description',
              value:
                  'Beautifully handcrafted traditional basket made by skilled artisans using natural materials.',
            ),

            const SizedBox(height: 28),

            // Language
            const Text(
              'Listing Language',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedLanguage,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'English',
                      child: Text('English'),
                    ),
                    DropdownMenuItem(
                      value: 'Hindi',
                      child: Text('Hindi'),
                    ),
                    DropdownMenuItem(
                      value: 'Hinglish',
                      child: Text('Hinglish'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedLanguage = value!;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductsScreen(),
                  ),
                 );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Create Listing',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            

            const SizedBox(height: 14),

            const Text(
              'AI can convert your voice description into a marketplace-ready listing.',
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

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
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
          Icon(
            icon,
            color: primaryPurple,
            size: 25,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: textMuted,
                  ),
                ),

                const SizedBox(height: 5),

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
      ),
    );
  }
}