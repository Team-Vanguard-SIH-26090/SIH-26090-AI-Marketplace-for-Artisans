import 'package:flutter/material.dart';
import '../cart.dart';
import 'add_product_screen.dart';
import 'image_studio_screen.dart';

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({
    super.key,
    required this.productName,
    required this.category,
    required this.price,
    required this.description,
    required this.material,
    this.imagePath,
    this.imageUrl,
    this.product,
    this.isBuyer = false,
    required this.onProductUpdated,
    this.artisanName,
  });

  final String productName;
  final String category;
  final String price;
  final String description;
  final String material;
  final String? imagePath;
  final String? imageUrl;
  final Map<String, dynamic>? product;
  final bool isBuyer;
  final Function(String name, String price, String category, String description, String material) onProductUpdated;
  final String? artisanName;

  static const background = Color(0xFFF5F2EB);
  static const primary = Color(0xFF9E4733);
  static const light = Color(0xFFEADCCF);
  static const textDark = Color(0xFF2C221E);
  static const muted = Color(0xFF8C7A70);

  double get _numericPrice => double.tryParse(price.replaceAll('₹', '').replaceAll(',', '').trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(title: const Text('Product Details', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)), backgroundColor: background, elevation: 0, iconTheme: const IconThemeData(color: textDark)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(onTap: imageUrl == null ? null : () => _showFullImage(context), child: _image()),
            const SizedBox(height: 24),
            Text(productName, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            Text(category, style: const TextStyle(color: muted)),
             if (isBuyer) ...[
               const SizedBox(height: 12),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                 decoration: BoxDecoration(color: light, borderRadius: BorderRadius.circular(12)),
                 child: Row(children: [
                   const Icon(Icons.handshake_outlined, color: primary, size: 18),
                   const SizedBox(width: 8),
                   Text('Crafted by ${artisanName ?? 'Local Artisan'}', style: const TextStyle(color: textDark, fontWeight: FontWeight.w600)),
                 ]),
               ),
             ],
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: light, borderRadius: BorderRadius.circular(18)), child: Row(children: [const Icon(Icons.currency_rupee_rounded, color: primary, size: 28), const SizedBox(width: 10), Text(price, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: primary))])),
            const SizedBox(height: 24),
            const Text('Product Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textDark)),
            const SizedBox(height: 14),
            _infoCard(Icons.spa_outlined, 'Material', material.isEmpty ? 'Not specified' : material),
            const SizedBox(height: 12),
            _infoCard(Icons.description_outlined, 'Description', description.isEmpty ? 'No description available.' : description),
            if (isBuyer) ...[
              const SizedBox(height: 24),
              SizedBox(height: 54, child: ElevatedButton.icon(onPressed: product == null ? null : () { cart.add(product!); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart'))); }, icon: const Icon(Icons.add_shopping_cart), label: const Text('Add to Cart'), style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
            ] else ...[
              const SizedBox(height: 28),
              SizedBox(height: 54, child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(initialName: productName, initialPrice: price, initialCategory: category, initialDescription: description, initialMaterial: material, isEditing: true, onProductAdded: onProductUpdated))), icon: const Icon(Icons.edit_outlined), label: const Text('Edit Product'), style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
              const SizedBox(height: 12),
              SizedBox(height: 54, child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImageStudioScreen())), icon: const Icon(Icons.auto_awesome_outlined), label: const Text('Enhance Product Photo'), style: OutlinedButton.styleFrom(foregroundColor: primary, side: const BorderSide(color: primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _image() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.network(imageUrl!, height: 300, width: double.infinity, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _placeholder()));
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(height: 300, width: double.infinity, decoration: BoxDecoration(color: light, borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.shopping_bag_outlined, size: 80, color: primary));

  void _showFullImage(BuildContext context) {
    showDialog<void>(context: context, builder: (_) => Dialog(backgroundColor: Colors.black, insetPadding: const EdgeInsets.all(12), child: InteractiveViewer(child: Image.network(imageUrl!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Padding(padding: EdgeInsets.all(40), child: Icon(Icons.broken_image_outlined, size: 60, color: Colors.white))))));
  }

  Widget _infoCard(IconData icon, String title, String value) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: light, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: primary)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, color: muted)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textDark, height: 1.4))]))]),
  );
}