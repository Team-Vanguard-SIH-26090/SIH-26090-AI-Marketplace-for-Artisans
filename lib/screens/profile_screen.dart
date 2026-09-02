import 'package:flutter/material.dart';
import 'personal_information_screen.dart';
import 'my_store_screen.dart';
import 'language_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color background = Color(0xFFF7F7FA);
  static const Color primaryPurple = Color(0xFF6B5DD3);
  static const Color lightLavender = Color(0xFFE9E5FF);
  static const Color textDark = Color(0xFF25213B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: textDark,
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 20),

            // --------------------------------
            // PROFILE ICON
            // --------------------------------

            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: lightLavender,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.person,
                size: 55,
                color: primaryPurple,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Artisan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'CraftConnect Artisan',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 30),

            // --------------------------------
            // PROFILE OPTIONS
            // --------------------------------

           _profileOption(
                context,
                Icons.person_outline,
                'Personal Information',
                'Manage your personal details',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const PersonalInformationScreen(),
                    ),
                  );
                },
              ),

            _profileOption(
  context,
  Icons.storefront_outlined,
  'My Store',
  'Manage your digital store',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyStoreScreen(),
      ),
    );
  },
),

            _profileOption(
  context,
  Icons.language,
  'Language',
  'Choose your preferred language',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LanguageScreen(),
      ),
    );
  },
),

            _profileOption(
  context,
  Icons.settings_outlined,
  'Settings',
  'Manage your app preferences',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  },
),
            _profileOption(
  context,
  Icons.help_outline,
  'Help & Support',
  'Get help and find answers',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpSupportScreen(),
      ),
    );
  },
),
            const SizedBox(height: 20),

            // --------------------------------
            // LOGOUT BUTTON
            // --------------------------------

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showLogoutDialog(context);
                },

                icon: const Icon(Icons.logout),

                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryPurple,

                  side: const BorderSide(
                    color: primaryPurple,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --------------------------------
  // PROFILE OPTION
  // --------------------------------

  Widget _profileOption(
  BuildContext context,
  IconData icon,
  String title,
  String subtitle, {
  VoidCallback? onTap,
}) {
    return InkWell(
  onTap: onTap ??
      () {
        _showOptionMessage(
          context,
          title,
          subtitle,
        );
      },

      borderRadius: BorderRadius.circular(16),

      child: Container(
        margin: const EdgeInsets.only(bottom: 14),

        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),

        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,

              decoration: BoxDecoration(
                color: lightLavender,
                borderRadius: BorderRadius.circular(13),
              ),

              child: Icon(
                icon,
                color: primaryPurple,
              ),
            ),

            const SizedBox(width: 16),

            // Text
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
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(
              Icons.arrow_forward_ios,
              size: 15,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------
  // OPTION MESSAGE
  // --------------------------------

  void _showOptionMessage(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.transparent,

      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),

          decoration: const BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Container(
                width: 45,
                height: 5,

                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 22),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  child: const Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------
  // LOGOUT DIALOG
  // --------------------------------

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Log Out',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),

          content: const Text(
            'Are you sure you want to log out?',
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                // Go back to the previous screen
                Navigator.pop(context);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
              ),

              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }
}