import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
        backgroundColor: background,
        elevation: 0,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
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
              'How can we help you?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Find answers or get help with CraftConnect.',
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
            ),

            const SizedBox(height: 24),

            // Contact Support
            _supportOption(
              context,
              icon: Icons.headset_mic_outlined,
              title: 'Contact Support',
              subtitle: 'Get help from the CraftConnect team',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Support contact feature will be available soon.',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Report Problem
            _supportOption(
              context,
              icon: Icons.bug_report_outlined,
              title: 'Report a Problem',
              subtitle: 'Tell us if something is not working',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Problem reporting feature will be available soon.',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),

            const SizedBox(height: 12),

            _faqCard(
              question: 'How do I add a product?',
              answer:
                  'Open My Products from the dashboard and tap '
                  'Add New Product. Enter your product details '
                  'and save the product.',
            ),

            _faqCard(
              question: 'How does AI Image Studio work?',
              answer:
                  'Upload your product photo and select the AI '
                  'enhancements you want, such as background '
                  'removal, lighting improvement and smart crop.',
            ),

            _faqCard(
              question: 'How does Auto Catalog work?',
              answer:
                  'Describe your product using voice input. '
                  'CraftConnect can turn your description into '
                  'a marketplace-ready product listing.',
            ),

            _faqCard(
              question: 'What is Smart Pricing?',
              answer:
                  'Smart Pricing provides an AI-based suggested '
                  'price using product information such as category, '
                  'material and craftsmanship.',
            ),

            _faqCard(
              question: 'Can I edit my products?',
              answer:
                  'Yes. Open My Products, select a product and '
                  'use the edit option to update its information.',
            ),

            const SizedBox(height: 24),

            // How CraftConnect works
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: lightLavender,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Icon(
                    Icons.lightbulb_outline,
                    color: primaryPurple,
                    size: 26,
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          'Need more help?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),

                        SizedBox(height: 5),

                        Text(
                          'Explore the AI tools and product features '
                          'to make your craft business easier to manage.',
                          style: TextStyle(
                            fontSize: 13,
                            color: textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                'CraftConnect Support • v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _supportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [

            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: lightLavender,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: primaryPurple,
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

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqCard({
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 2,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        iconColor: primaryPurple,
        collapsedIconColor: textMuted,
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 13,
                color: textMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}