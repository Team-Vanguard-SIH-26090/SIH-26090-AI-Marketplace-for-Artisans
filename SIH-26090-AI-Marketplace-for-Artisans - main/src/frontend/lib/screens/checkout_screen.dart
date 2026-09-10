import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';
import '../auth.dart';
import '../cart.dart';
import 'orders_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final addressController = TextEditingController(text: Auth.address ?? '');
  bool loading = false;

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (Auth.artisanId == null) {
      _message('Please log in before placing an order.');
      return;
    }
    if (addressController.text.trim().isEmpty || cart.isEmpty) {
      _message('Enter a delivery address and keep at least one item in the cart.');
      return;
    }
    setState(() => loading = true);
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'buyer_id': Auth.artisanId,
          'address': addressController.text.trim(),
          'items': cart.items.map((item) => {'product_id': item.productId, 'quantity': item.quantity}).toList(),
        }),
      );
      if (response.statusCode != 200) throw Exception(_error(response.body));
      cart.clear();
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('Order placed'), content: const Text('Your order has been placed with Cash on Delivery.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))]));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const OrdersScreen()), (route) => route.isFirst);
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _error(String body) {
    try {
      return jsonDecode(body)['detail'].toString();
    } catch (_) {
      return 'Could not place the order';
    }
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF5F2EB);
    const primary = Color(0xFF9E4733);
    const textDark = Color(0xFF2C221E);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(title: const Text('Checkout', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)), backgroundColor: background, elevation: 0, iconTheme: const IconThemeData(color: textDark)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Delivery details', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 12),
          TextField(controller: addressController, maxLines: 4, decoration: InputDecoration(labelText: 'Delivery address', alignLabelWithHint: true, filled: true, fillColor: Colors.white, prefixIcon: const Icon(Icons.location_on_outlined, color: primary), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Payment method', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)), const SizedBox(height: 12), const Row(children: [Icon(Icons.local_shipping_outlined, color: primary), SizedBox(width: 10), Text('Cash on Delivery', style: TextStyle(color: textDark)), Spacer(), Icon(Icons.check_circle, color: primary)])])),
          const SizedBox(height: 24),
          ListenableBuilder(listenable: cart, builder: (_, __) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Grand Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)), Text('₹${cart.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: primary))])),
          const SizedBox(height: 22),
          SizedBox(height: 54, child: ElevatedButton(onPressed: loading ? null : _placeOrder, style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Text('Place Order'))),
        ],
      ),
    );
  }
}