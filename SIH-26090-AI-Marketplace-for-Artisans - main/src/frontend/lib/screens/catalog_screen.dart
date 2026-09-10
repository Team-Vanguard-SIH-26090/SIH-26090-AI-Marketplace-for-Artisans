import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';
import '../cart.dart';
import 'cart_screen.dart';
import 'product_details_screen.dart';
import '../l10n/app_localizations.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  static const background = Color(0xFFF5F2EB);
  static const primary = Color(0xFF9E4733);
  static const textDark = Color(0xFF2C221E);
  static const muted = Color(0xFF8C7A70);

  final searchController = TextEditingController();
  List<Map<String, dynamic>> products = [];
  bool loading = true;
  String? error;
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final search = searchController.text.trim();
      final query = <String, String>{'active_only': 'true', 'limit': '100'};
      if (search.isNotEmpty) query['search'] = search;
      final uri = Uri.parse('$apiBaseUrl/products').replace(queryParameters: query);
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception(_error(response.body));
      }
      products = List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _error(String body) {
    try {
      return jsonDecode(body)['detail'].toString();
    } catch (_) {
      return 'Could not load the marketplace';
    }
  }

  String _name(Map<String, dynamic> product) =>
      (product['product_title_en'] ?? product['name'] ?? 'Untitled Product').toString();

  String _description(Map<String, dynamic> product) =>
      (product['description_en'] ?? product['description'] ?? 'Handmade product').toString();

  double _price(Map<String, dynamic> product) {
    final pricing = product['pricing'];
    final value = product['price'] ?? (pricing is Map ? pricing['suggested_price_inr'] : null);
    return double.tryParse(value.toString().replaceAll('₹', '').replaceAll(',', '').trim()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text('Marketplace', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        actions: [
          ListenableBuilder(
            listenable: cart,
            builder: (_, __) => IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              icon: Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
             Text(context.strings.text('discover'), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 6),
            const Text('Support artisans by shopping unique, handcrafted pieces.', style: TextStyle(color: muted)),
            const SizedBox(height: 20),
             _heroCarousel(),
             const SizedBox(height: 18),
             Text(context.strings.text('categories'), style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)),
             const SizedBox(height: 10),
             SizedBox(
               height: 42,
               child: ListView(
                 scrollDirection: Axis.horizontal,
                 children: ['All', 'Home Decor', 'Clothing', 'Jewellery', 'Art & Craft']
                     .map((category) => Padding(
                           padding: const EdgeInsets.only(right: 8),
                           child: ChoiceChip(
                             label: Text(category == 'All' ? context.strings.text('all') : category),
                             selected: selectedCategory == category,
                             selectedColor: primary,
                             labelStyle: TextStyle(color: selectedCategory == category ? Colors.white : textDark),
                             onSelected: (_) => setState(() => selectedCategory = category),
                           ),
                         ))
                     .toList(),
               ),
             ),
             const SizedBox(height: 18),
            TextField(
              controller: searchController,
              onSubmitted: (_) => _load(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search products, categories...',
                prefixIcon: const Icon(Icons.search, color: primary),
                suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.arrow_forward, color: primary)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 22),
            if (loading)
              const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator(color: primary)))
            else if (error != null)
              _messageCard(error!, Icons.cloud_off_outlined)
            else if (products.isEmpty)
              _messageCard('No active products matched your search.', Icons.storefront_outlined)
            else
              ...products.where((product) => selectedCategory == 'All' || product['category'] == selectedCategory).map(_productCard),
          ],
        ),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    final imageUrl = product['image_url']?.toString();
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(
            productName: _name(product),
            category: (product['category'] ?? 'Handicraft').toString(),
            price: '₹${_price(product).toStringAsFixed(0)}',
            description: _description(product),
            material: (product['material'] ?? '').toString(),
            artisanName: (product['artisan_name'] ?? 'Local Artisan').toString(),
            imageUrl: imageUrl,
            isBuyer: true,
            product: product,
            onProductUpdated: (_, __, ___, ____, _____) {},
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(18),
       child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
         decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(18),
           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 5))],
         ),
        child: Row(
          children: [
            _image(imageUrl, 88),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_name(product), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 5),
                  Text(_description(product), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: muted)),
                  const SizedBox(height: 8),
                   Row(
                     children: [
                       Text('₹${_price(product).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: primary)),
                       const SizedBox(width: 8),
                       if ((product['material'] ?? '').toString().isNotEmpty)
                         Chip(label: Text(product['material'].toString()), visualDensity: VisualDensity.compact, backgroundColor: const Color(0xFFEADCCF)),
                     ],
                   ),
                ],
              ),
            ),
             ElevatedButton(
               onPressed: () {
                 cart.add(product);
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
               },
               style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
               child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image(String? url, double size) {
    if (url == null || url.isEmpty) {
      return Container(width: size, height: size, decoration: BoxDecoration(color: const Color(0xFFEADCCF), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.shopping_bag_outlined, color: primary, size: 32));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(url, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: size, height: size, color: const Color(0xFFEADCCF), child: const Icon(Icons.broken_image_outlined, color: primary))),
    );
  }

  Widget _messageCard(String message, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: Column(children: [Icon(icon, size: 42, color: primary), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: muted))]),
  );

  Widget _heroCarousel() => SizedBox(
        height: 150,
        child: PageView(
          children: [
            _hero('Handmade, with a story', 'Shop directly from India’s artisan community', Icons.auto_awesome),
            _hero('Crafted for your home', 'Discover materials, techniques and traditions', Icons.home_work_outlined),
            _hero('Every purchase matters', 'Support independent makers', Icons.favorite_outline),
          ],
        ),
      );

  Widget _hero(String title, String subtitle, IconData icon) => Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
          Icon(icon, color: Colors.white, size: 46),
        ]),
      );
}