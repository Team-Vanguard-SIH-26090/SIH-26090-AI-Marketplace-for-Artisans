import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';
import '../auth.dart';
import 'product_details_screen.dart';
import 'add_product_screen.dart';
import 'catalog_screen.dart';
import 'dashboard_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const background = Color(0xFFF5F2EB);
  static const primary = Color(0xFF9E4733);
  static const light = Color(0xFFEADCCF);
  static const textDark = Color(0xFF2C221E);
  static const muted = Color(0xFF8C7A70);
  List<Map<String, dynamic>> products = [];
  bool loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (Auth.artisanId == null) { if (mounted) setState(() => loading = false); return; }
    try {
      final r = await http.get(Uri.parse('$apiBaseUrl/products?artisan_id=${Uri.encodeComponent(Auth.artisanId!)}'));
      if (r.statusCode == 200) products = List<Map<String, dynamic>>.from(jsonDecode(r.body));
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  String _name(Map<String, dynamic> p) => (p['product_title_en'] ?? p['name'] ?? 'Untitled Product').toString();
  String _description(Map<String, dynamic> p) => (p['description_en'] ?? p['description'] ?? '').toString();
  String _price(Map<String, dynamic> p) => '₹${p['pricing']?['suggested_price_inr'] ?? p['price'] ?? '-'}';

  Future<void> _delete(String id) async {
    final r = await http.delete(Uri.parse('$apiBaseUrl/products/$id'));
    if (r.statusCode == 200) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('My Products', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Browse marketplace',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogScreen())),
            icon: const Icon(Icons.storefront_outlined),
          ),
        ],
      ),
      body: loading ? const Center(child: CircularProgressIndicator(color: primary)) : RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Your Digital Store', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 6),
          const Text('Manage your products and showcase your craft.', style: TextStyle(color: muted)),
          const SizedBox(height: 24),
          SizedBox(height: 52, child: ElevatedButton.icon(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(onProductAdded: (_, __, ___, ____, _____) {}))); await _load(); }, icon: const Icon(Icons.add), label: const Text('Add New Product'), style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white))),
          const SizedBox(height: 28),
          Text('${products.length} Products Listed', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 16),
          if (products.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: Text('No products saved yet.', style: TextStyle(color: muted)))),
          ...products.map((p) => InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(
              productName: _name(p), category: (p['category'] ?? 'Handicraft').toString(), price: _price(p), description: _description(p), material: (p['material'] ?? '').toString(), imageUrl: p['image_url']?.toString(), onProductUpdated: (_, __, ___, ____, _____) {},
            ))),
            child: Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Row(children: [
              p['image_url'] != null ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(p['image_url'], width: 65, height: 65, fit: BoxFit.cover)) : Container(width: 65, height: 65, decoration: BoxDecoration(color: light, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.shopping_bag_outlined, size: 30, color: primary)),
              const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_name(p), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)), const SizedBox(height: 6), Text(_price(p), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primary)), const SizedBox(height: 4), const Text('Saved', style: TextStyle(fontSize: 12, color: Colors.green))])),
              IconButton(onPressed: () => _delete(p['_id'].toString()), icon: const Icon(Icons.delete_outline, color: primary)),
            ])),
          )),
        ]),
      ),
    );
  }
}
