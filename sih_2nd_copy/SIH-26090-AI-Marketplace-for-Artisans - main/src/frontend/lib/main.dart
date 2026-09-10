import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'l10n/app_locale.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocale.instance.load();
  runApp(const CraftConnectApp());
}

class CraftConnectApp extends StatelessWidget {
  const CraftConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLocale.instance,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CraftConnect',
        locale: AppLocale.instance.locale,
        supportedLocales: AppLocalizations.supported,
        localeResolutionCallback: (deviceLocale, supportedLocales) {
          final code = deviceLocale?.languageCode;
          return supportedLocales.any((locale) => locale.languageCode == code)
              ? Locale(code!)
              : const Locale('en');
        },
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFF4F5F7),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F2937)),
          textTheme: GoogleFonts.poppinsTextTheme(),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}