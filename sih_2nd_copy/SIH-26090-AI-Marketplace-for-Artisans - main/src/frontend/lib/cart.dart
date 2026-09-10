import 'package:flutter/foundation.dart';

class CartItem {
  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });

  final String productId;
  final String name;
  final double price;
  final String? imageUrl;
  int quantity;

  double get total => price * quantity;
}

class CartController extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList(growable: false);
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get total => _items.values.fold(0, (sum, item) => sum + item.total);
  bool get isEmpty => _items.isEmpty;

  void add(Map<String, dynamic> product) {
    final id = product['_id']?.toString();
    if (id == null || id.isEmpty) return;
    final existing = _items[id];
    if (existing != null) {
      existing.quantity++;
    } else {
      _items[id] = CartItem(
        productId: id,
        name: _productName(product),
        price: _productPrice(product),
        imageUrl: product['image_url']?.toString(),
      );
    }
    notifyListeners();
  }

  void remove(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void decrease(String productId) {
    final item = _items[productId];
    if (item == null) return;
    if (item.quantity <= 1) {
      _items.remove(productId);
    } else {
      item.quantity--;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  static String _productName(Map<String, dynamic> product) =>
      (product['product_title_en'] ?? product['name'] ?? 'Untitled Product').toString();

  static double _productPrice(Map<String, dynamic> product) {
    final pricing = product['pricing'];
    final value = product['price'] ?? (pricing is Map ? pricing['suggested_price_inr'] : null);
    return double.tryParse(value.toString().replaceAll('₹', '').replaceAll(',', '').trim()) ?? 0;
  }
}

final cart = CartController();