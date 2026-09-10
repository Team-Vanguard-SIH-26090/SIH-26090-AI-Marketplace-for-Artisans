import 'package:flutter/material.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_localizations.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  // --- UPDATED TERRACOTTA THEME COLORS ---
  static const Color background = Color(0xFFF5F2EB); // Warm Sand
  static const Color primaryPurple = Color(0xFF9E4733); // Terracotta 
  static const Color lightLavender = Color(0xFFEADCCF); // Soft Almond
  static const Color textDark = Color(0xFF2C221E); // Espresso Brown
  static const Color textMuted = Color(0xFF8C7A70); // Earthy Grey

  String selectedLanguage = 'English';

  final List<Map<String, String>> languages = const [
    {'name': 'English', 'code': 'en'},
    {'name': 'हिन्दी', 'code': 'hi'},
    {'name': 'मराठी', 'code': 'mr'},
    {'name': 'தமிழ்', 'code': 'ta'},
    {'name': 'বাংলা', 'code': 'bn'},
  ];

  @override
  void initState() {
    super.initState();
    selectedLanguage = _languageName(AppLocale.instance.locale.languageCode);
  }

  String _languageName(String code) => languages.firstWhere(
        (language) => language['code'] == code,
        orElse: () => languages.first,
      )['name']!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: const Text(
          'Language',
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

            const SizedBox(height: 10),

            Text(
              context.strings.text('choose_language'),
              style: const TextStyle(
                fontSize: 15,
                color: textMuted,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Available Languages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),

            const SizedBox(height: 14),

            ...languages.map(
              (language) => _languageOption(language['name']!, language['code']!),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightLavender,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: primaryPurple,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your language preference will be used '
                      'for AI-generated product listings and '
                      'other app content.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(String language, String code) {
    final bool isSelected = selectedLanguage == language;

    return InkWell(
      onTap: () {
        setState(() => selectedLanguage = language);
        AppLocale.instance.setLanguage(code);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$language selected as your preferred language.',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primaryPurple
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [

            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? lightLavender
                    : const Color(0xFFEFE8E0), // Warmed up the unselected grey
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.language,
                color: isSelected
                    ? primaryPurple
                    : textMuted,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                language,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
            ),

            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: primaryPurple,
              )
            else
              const Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }
}