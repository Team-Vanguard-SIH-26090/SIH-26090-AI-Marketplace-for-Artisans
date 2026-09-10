import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';
import '../auth.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const background = Color(0xFFF5F2EB);
  static const primary = Color(0xFF9E4733);
  static const textDark = Color(0xFF2C221E);
  static const muted = Color(0xFF8C7A70);
  List<Map<String, dynamic>> orders = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (Auth.artisanId == null) {
      setState(() => loading = false);
      return;
    }
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/orders?buyer_id=${Uri.encodeComponent(Auth.artisanId!)}'));
      if (response.statusCode != 200) throw Exception('Could not load your orders');
      orders = List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(title: const Text('My Orders', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)), backgroundColor: background, elevation: 0, iconTheme: const IconThemeData(color: textDark)),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: muted)))
              : orders.isEmpty
                  ? const Center(child: Text('Your purchase history will appear here.', style: TextStyle(color: muted)))
                  : RefreshIndicator(onRefresh: _load, child: ListView.builder(padding: const EdgeInsets.all(20), itemCount: orders.length, itemBuilder: (_, index) => _orderCard(orders[index]))),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final rawDate = order['created_at']?.toString() ?? '';
    final date = DateTime.tryParse(rawDate)?.toLocal();
    final dateText = date == null ? 'Date unavailable' : '${date.day}/${date.month}/${date.year}';
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: Text('Order #${order['_id']?.toString().substring(0, 6) ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, color: textDark))), Text(dateText, style: const TextStyle(fontSize: 12, color: muted))]),
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFEADCCF), borderRadius: BorderRadius.circular(20)), child: Text((order['status'] ?? 'placed').toString().toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primary))),
          const SizedBox(height: 14),
           ...items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
             Row(children: [Expanded(child: Text('${item['name'] ?? 'Product'} × ${item['quantity'] ?? 1}', style: const TextStyle(color: textDark))), Text('₹${(item['item_total'] ?? 0).toString()}', style: const TextStyle(color: muted))]),
             const SizedBox(height: 8),
             _trackingStepper((item['status'] ?? order['status'] ?? 'placed').toString()),
           ]))),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)), Text('₹${(order['total'] ?? 0).toString()}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primary))]),
        ],
      ),
    );
  }

  Widget _trackingStepper(String status) {
    const stages = ['placed', 'dispatched', 'in_transit', 'delivered'];
    final current = stages.indexOf(status);
    return Row(
      children: stages.asMap().entries.map((entry) {
        final index = entry.key;
        final active = index <= current;
        return Expanded(
          child: Row(children: [
            Column(children: [
              CircleAvatar(radius: 9, backgroundColor: active ? primary : Colors.black12, child: active ? const Icon(Icons.check, size: 11, color: Colors.white) : null),
              const SizedBox(height: 3),
              Text(entry.value.replaceAll('_', ' '), style: TextStyle(fontSize: 8, color: active ? primary : muted)),
            ]),
            if (index < stages.length - 1) Expanded(child: Container(height: 2, color: index < current ? primary : Colors.black12)),
          ]),
        );
      }).toList(),
    );
  }
}