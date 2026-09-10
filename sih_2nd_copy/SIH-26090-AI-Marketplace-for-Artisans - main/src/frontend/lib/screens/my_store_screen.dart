import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';
import '../auth.dart';

class MyStoreScreen extends StatefulWidget {
  const MyStoreScreen({super.key});

  @override
  State<MyStoreScreen> createState() => _MyStoreScreenState();
}

class _MyStoreScreenState extends State<MyStoreScreen> {
  static const background = Color(0xFFF5F2EB);
  static const primary = Color(0xFF9E4733);
  static const light = Color(0xFFEADCCF);
  static const textDark = Color(0xFF2C221E);
  static const muted = Color(0xFF8C7A70);
  int productCount = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    if (Auth.artisanId == null) {
      setState(() => loading = false);
      return;
    }
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/products?artisan_id=${Uri.encodeComponent(Auth.artisanId!)}&limit=100'));
      if (response.statusCode == 200) productCount = (jsonDecode(response.body) as List).length;
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(title: const Text('My Store', style: TextStyle(color: textDark, fontWeight: FontWeight.w600)), backgroundColor: background, elevation: 0, iconTheme: const IconThemeData(color: textDark)),
      body: RefreshIndicator(
        onRefresh: _loadCount,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: light, borderRadius: BorderRadius.circular(22)),
              child: Column(children: [Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: const Icon(Icons.storefront_rounded, size: 42, color: primary)), const SizedBox(height: 16), Text('${Auth.name ?? 'CraftConnect'} Store', textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: textDark)), const SizedBox(height: 6), const Text('Showcase your handmade creations.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: muted))]),
            ),
            const SizedBox(height: 24),
            const Text('Store Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textDark)),
            const SizedBox(height: 14),
            Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Row(children: [const Icon(Icons.inventory_2_outlined, color: primary, size: 28), const SizedBox(width: 16), const Text('Products Listed', style: TextStyle(color: muted)), const Spacer(), Text(loading ? '—' : '$productCount', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark))])),
            const SizedBox(height: 24),
            const Text('Store Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textDark)),
            const SizedBox(height: 14),
            _infoCard(Icons.storefront_outlined, 'Store Name', '${Auth.name ?? 'CraftConnect'} Store'),
            _infoCard(Icons.location_on_outlined, 'Delivery Location', Auth.address?.isNotEmpty == true ? Auth.address! : 'Add an address in Personal Information'),
            const SizedBox(height: 20),
            const Text('Product view counts are not shown. This overview reports your actual number of listed products.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: muted, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: light, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: primary)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, color: muted)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textDark))]))]),
  );
}