import 'package:flutter/material.dart';
import 'add_product_screen.dart';
import 'image_studio_screen.dart';
import 'dart:io';

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({
    super.key,
    required this.productName,
    required this.category,
    required this.price,
    required this.description,
    required this.material,
    this.imagePath,
    required this.onProductUpdated,
  });

  final String productName;
  final String category;
  final String price;
  final String description;
  final String material;
  final String? imagePath;

  final Function(
    String name,
    String price,
    String category,
    String description,
    String material,
  ) onProductUpdated;

  static const Color background = Color(0xFFF7F5FB);
  static const Color primaryPurple = Color(0xFF7C5CBF);
  static const Color lightLavender = Color(0xFFEDE7F6);
  static const Color textDark = Color(0xFF2D2A3D);
  static const Color textMuted = Color(0xFF6F6C7D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: textDark,
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // PRODUCT IMAGE
            // Product image
Container(
  height: 230,
  width: double.infinity,
  decoration: BoxDecoration(
    color: lightLavender,
    borderRadius: BorderRadius.circular(24),
  ),
  child: imagePath != null
      ? ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.file(
            File(imagePath!),
            fit: BoxFit.cover,
          ),
        )
      : const Icon(
          Icons.shopping_bag_outlined,
          size: 80,
          color: primaryPurple,
        ),
),

            const SizedBox(height: 24),

            // PRODUCT NAME
            Text(
              productName,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),

            const SizedBox(height: 8),

            // CATEGORY
            Text(
              category,
              style: const TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
            ),

            const SizedBox(height: 20),

            // PRICE
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: lightLavender,
                borderRadius: BorderRadius.circular(18),
              ),

              child: Row(
                children: [

                  const Icon(
                    Icons.currency_rupee_rounded,
                    color: primaryPurple,
                    size: 28,
                  ),

                  const SizedBox(width: 10),

                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: primaryPurple,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // PRODUCT INFORMATION
            const Text(
              'Product Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),

            const SizedBox(height: 14),

            // MATERIAL
            _infoCard(
              Icons.spa_outlined,
              'Material',
              material,
            ),

            const SizedBox(height: 12),

            // DESCRIPTION
            _infoCard(
              Icons.description_outlined,
              'Description',
              description,
            ),

            const SizedBox(height: 28),

            // EDIT PRODUCT BUTTON
            SizedBox(
              height: 54,

              child: ElevatedButton.icon(
                onPressed: () {

                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (context) => AddProductScreen(

                        // Existing values
                        initialName: productName,
                        initialPrice: price,

                        initialCategory: category,

                        initialDescription: description,
                        initialMaterial: material,

                        isEditing: true,

                        // Updated values
                        onProductAdded: (
                          name,
                          newPrice,
                          newCategory,
                          newDescription,
                          newMaterial,
                        ) {

                          // Send updated data back
                          onProductUpdated(
                            name,
                            newPrice,
                            newCategory,
                            newDescription,
                            newMaterial,
                          );

                          // Go back to Product Details
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Product updated successfully!',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },

                icon: const Icon(
                  Icons.edit_outlined,
                ),

                label: const Text(
                  'Edit Product',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ENHANCE PHOTO
            SizedBox(
              height: 54,

              child: OutlinedButton.icon(
                onPressed: () {

                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (context) =>
                          const ImageStudioScreen(),
                    ),
                  );
                },

                icon: const Icon(
                  Icons.auto_awesome_outlined,
                ),

                label: const Text(
                  'Enhance Product Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryPurple,

                  side: const BorderSide(
                    color: primaryPurple,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: lightLavender,
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(
              icon,
              color: primaryPurple,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,

                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}