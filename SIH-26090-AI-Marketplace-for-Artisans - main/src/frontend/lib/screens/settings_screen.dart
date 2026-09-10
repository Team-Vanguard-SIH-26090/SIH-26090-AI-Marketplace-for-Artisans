import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- UPDATED TERRACOTTA THEME COLORS ---
  static const Color background = Color(0xFFF5F2EB); // Warm Sand
  static const Color primaryPurple = Color(0xFF9E4733); // Terracotta 
  static const Color lightLavender = Color(0xFFEADCCF); // Soft Almond
  static const Color textDark = Color(0xFF2C221E); // Espresso Brown
  static const Color textMuted = Color(0xFF8C7A70); // Earthy Grey

  bool notificationsEnabled = true;
  bool aiSuggestionsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: const Text(
          'Settings',
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
              'Manage your app preferences.',
              style: TextStyle(
                fontSize: 15,
                color: textMuted,
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              'Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),

            const SizedBox(height: 14),

            _settingSwitch(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Receive updates and important alerts',
              value: notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  notificationsEnabled = value;
                });
              },
            ),

            const SizedBox(height: 12),

            _settingSwitch(
              icon: Icons.auto_awesome_outlined,
              title: 'AI Suggestions',
              subtitle: 'Get helpful AI recommendations',
              value: aiSuggestionsEnabled,
              onChanged: (value) {
                setState(() {
                  aiSuggestionsEnabled = value;
                });
              },
            ),

            const SizedBox(height: 28),

            const Text(
              'App Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),

            const SizedBox(height: 14),

            _settingOption(
              icon: Icons.info_outline,
              title: 'About CraftConnect',
              subtitle: 'Learn more about the app',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'CraftConnect',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(
                    Icons.storefront_rounded,
                    color: primaryPurple,
                    size: 40,
                  ),
                  children: const [
                    Text(
                      'CraftConnect helps artisans digitize '
                      'their products and grow their craft business '
                      'with AI-powered tools.',
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),

            _settingOption(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy',
              subtitle: 'Manage your privacy information',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Privacy settings will be available soon.',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            _settingOption(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              subtitle: 'View app terms and conditions',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Terms & Conditions will be available soon.',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            Center(
              child: Text(
                'CraftConnect v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [

          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: lightLavender,
              borderRadius: BorderRadius.circular(12),
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

          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: primaryPurple,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _settingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [

            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: lightLavender,
                borderRadius: BorderRadius.circular(12),
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
}