import 'package:flutter/material.dart';
import '../cart.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const background = Color(0xFFF5F2EB);
  static const primary = Color(0xFF9E4733);
  static const textDark = Color(0xFF2C221E);
  static const muted = Color(0xFF8C7A70);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(title: const Text('Shopping Cart', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)), backgroundColor: background, elevation: 0, iconTheme: const IconThemeData(color: textDark)),
      body: ListenableBuilder(
        listenable: cart,
        builder: (context, _) {
          if (cart.isEmpty) {
            return const Center(child: Text('Your cart is empty.', style: TextStyle(color: muted)));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: cart.items.length,
                  itemBuilder: (_, index) => _item(context, cart.items[index]),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Grand Total', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textDark)), Text('₹${cart.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary))]),
                    const SizedBox(height: 14),
                    SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())), style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text('Proceed to Checkout'))),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _item(BuildContext context, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)),
      child: Row(
        children: [
          item.imageUrl == null || item.imageUrl!.isEmpty
              ? Container(width: 68, height: 68, decoration: BoxDecoration(color: const Color(0xFFEADCCF), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.shopping_bag_outlined, color: primary))
              : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(item.imageUrl!, width: 68, height: 68, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 68, height: 68, color: const Color(0xFFEADCCF), child: const Icon(Icons.broken_image_outlined, color: primary)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)), const SizedBox(height: 5), Text('₹${item.price.toStringAsFixed(0)} each', style: const TextStyle(color: muted)), const SizedBox(height: 8), Row(children: [IconButton(onPressed: () => cart.decrease(item.productId), icon: const Icon(Icons.remove_circle_outline, color: primary), constraints: const BoxConstraints(), padding: EdgeInsets.zero), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold))), IconButton(onPressed: () => cart.add({'_id': item.productId, 'name': item.name, 'price': item.price, 'image_url': item.imageUrl}), icon: const Icon(Icons.add_circle_outline, color: primary), constraints: const BoxConstraints(), padding: EdgeInsets.zero)])])),
          IconButton(onPressed: () => cart.remove(item.productId), icon: const Icon(Icons.delete_outline, color: primary)),
        ],
      ),
    );
  }
}