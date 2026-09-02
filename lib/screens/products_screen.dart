import 'package:flutter/material.dart';
import 'product_details_screen.dart';
import 'add_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final List<Map<String, String>> products = [
    {
      'name': 'Handmade Pottery',
      'price': '₹850',
      'category': 'Handmade Craft',
      'description':
          'Beautiful handcrafted pottery made by a skilled artisan.',
      'material': 'Natural Clay',
    },
    {
      'name': 'Traditional Handbag',
      'price': '₹1,200',
      'category': 'Handmade Craft',
      'description':
          'Beautiful traditional handbag crafted with care by artisans.',
      'material': 'Handwoven Fabric',
    },
    {
      'name': 'Decorative Wall Art',
      'price': '₹650',
      'category': 'Art & Craft',
      'description':
          'Elegant handmade wall art perfect for home decoration.',
      'material': 'Natural Materials',
    },
    {
      'name': 'Handwoven Basket',
      'price': '₹950',
      'category': 'Home Decor',
      'description':
          'Beautiful handwoven basket made by skilled artisans.',
      'material': 'Natural Bamboo',
    },
  ];

  // ADD NEW PRODUCT
  void _addProduct(
    String name,
    String price,
    String category,
    String description,
    String material,
  ) {
    setState(() {
      products.add({
        'name': name,
        'price': price,
        'category': category,
        'description': description,
        'material': material,
      });
    });
  }

  // UPDATE EXISTING PRODUCT
  void _updateProduct(
    String oldName,
    String newName,
    String newPrice,
    String newCategory,
    String newDescription,
    String newMaterial,
  ) {
    setState(() {
      final index = products.indexWhere(
        (product) => product['name'] == oldName,
      );

      if (index != -1) {
        products[index] = {
          'name': newName,
          'price': newPrice,
          'category': newCategory,
          'description': newDescription,
          'material': newMaterial,
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Products',
          style: TextStyle(
            color: Color(0xFF25213B),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF25213B),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // HEADER
            const Text(
              'Your Digital Store',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF25213B),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Manage your products and showcase your craft.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            // ADD PRODUCT BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddProductScreen(
                        onProductAdded: (
                          name,
                          price,
                          category,
                          description,
                          material,
                        ) {
                          _addProduct(
                            name,
                            price,
                            category,
                            description,
                            material,
                          );
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add New Product',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5DD3),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // PRODUCT COUNT
            Text(
              '${products.length} Products Listed',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF25213B),
              ),
            ),

            const SizedBox(height: 16),

            // PRODUCT LIST
            ...products.map(
              (product) => _productCard(
                context,
                product['name']!,
                product['price']!,
                product['category']!,
                product['description']!,
                product['material']!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(
    BuildContext context,
    String name,
    String price,
    String category,
    String description,
    String material,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              productName: name,
              category: category,
              price: price,
              description: description,
              material: material,

              // EDIT CALLBACK
              onProductUpdated: (
                newName,
                newPrice,
                newCategory,
                newDescription,
                newMaterial,
              ) {
                _updateProduct(
                  name,
                  newName,
                  newPrice,
                  newCategory,
                  newDescription,
                  newMaterial,
                );
              },
            ),
          ),
        );
      },

      borderRadius: BorderRadius.circular(18),

      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          children: [

            // PRODUCT ICON
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: const Color(0xFFE9E5FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 30,
                color: Color(0xFF6B5DD3),
              ),
            ),

            const SizedBox(width: 16),

            // PRODUCT INFORMATION
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF25213B),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B5DD3),
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Listed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}