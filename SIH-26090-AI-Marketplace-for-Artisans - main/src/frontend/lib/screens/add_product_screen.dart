import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'image_studio_screen.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({
    super.key,
    this.onProductAdded,
    this.initialName = '',
    this.initialPrice = '',
    this.initialCategory = 'Home Decor',
    this.initialDescription = '',
    this.initialMaterial = '',
    this.isEditing = false,
  });

  final Function(
    String name,
    String price,
    String category,
    String description,
    String material,
  )? onProductAdded;

  final String initialName;
  final String initialPrice;
  final String initialCategory;
  final String initialDescription;
  final String initialMaterial;
  final bool isEditing;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController materialController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  Uint8List? selectedImage;
  String selectedCategory = 'Home Decor';

  // --- UPDATED TERRACOTTA THEME COLORS ---
  static const Color background = Color(0xFFF5F2EB); // Warm Sand
  static const Color primaryPurple = Color(0xFF9E4733); // Terracotta 
  static const Color lightLavender = Color(0xFFEADCCF); // Soft Almond
  static const Color textDark = Color(0xFF2C221E); // Espresso Brown
  static const Color textMuted = Color(0xFF8C7A70); // Earthy Grey

  @override
  void initState() {
    super.initState();

    nameController.text = widget.initialName;
    priceController.text = widget.initialPrice;
    materialController.text = widget.initialMaterial;
    descriptionController.text = widget.initialDescription;

    // Make sure the category exists in our dropdown.
    const categories = [
      'Home Decor',
      'Clothing',
      'Jewellery',
      'Art & Craft',
    ];

    if (categories.contains(widget.initialCategory)) {
      selectedCategory = widget.initialCategory;
    } else {
      selectedCategory = 'Home Decor';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    materialController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _openImageStudio() async {
    final Uint8List? image = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (context) => const ImageStudioScreen(),
      ),
    );

    if (image != null) {
      setState(() {
        selectedImage = image;
      });
    }
  }

  void _saveProduct() {
    if (nameController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter product name and price.'),
        ),
      );
      return;
    }

    // Send product data back to ProductsScreen.
    widget.onProductAdded?.call(
      nameController.text.trim(),
      priceController.text.trim(),
      selectedCategory,
      descriptionController.text.trim(),
      materialController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditing
              ? 'Product updated successfully!'
              : 'Product added successfully!',
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Product' : 'Add Product',
          style: const TextStyle(
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
            // --------------------------------
            // PRODUCT PHOTO
            // --------------------------------
            InkWell(
              onTap: _openImageStudio,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: lightLavender,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 48,
                            color: primaryPurple,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Add Product Photo',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap to enhance with AI',
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.memory(
                              selectedImage!,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(
                                  alpha: 0.65,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Change Photo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 26),

            // --------------------------------
            // PRODUCT NAME
            // --------------------------------
            _inputField(
              controller: nameController,
              label: 'Product Name',
              hint: 'e.g. Handcrafted Basket',
              icon: Icons.shopping_bag_outlined,
            ),

            const SizedBox(height: 16),

            // --------------------------------
            // CATEGORY
            // --------------------------------
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'Home Decor',
                      child: Text('Home Decor'),
                    ),
                    DropdownMenuItem(
                      value: 'Clothing',
                      child: Text('Clothing'),
                    ),
                    DropdownMenuItem(
                      value: 'Jewellery',
                      child: Text('Jewellery'),
                    ),
                    DropdownMenuItem(
                      value: 'Art & Craft',
                      child: Text('Art & Craft'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCategory = value;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --------------------------------
            // MATERIAL
            // --------------------------------
            _inputField(
              controller: materialController,
              label: 'Material',
              hint: 'e.g. Natural Bamboo',
              icon: Icons.spa_outlined,
            ),

            const SizedBox(height: 16),

            // --------------------------------
            // PRICE
            // --------------------------------
            _inputField(
              controller: priceController,
              label: 'Price',
              hint: 'e.g. ₹850',
              icon: Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // --------------------------------
            // DESCRIPTION
            // --------------------------------
            _inputField(
              controller: descriptionController,
              label: 'Description',
              hint: 'Describe your product...',
              icon: Icons.description_outlined,
              maxLines: 4,
            ),

            const SizedBox(height: 28),

            // --------------------------------
            // SAVE BUTTON
            // --------------------------------
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _saveProduct,
                icon: const Icon(
                  Icons.check_rounded,
                ),
                label: Text(
                  widget.isEditing ? 'Update Product' : 'Save Product',
                  style: const TextStyle(
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

            const SizedBox(height: 14),

            const Text(
              'You can edit your product details anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------
  // INPUT FIELD
  // --------------------------------
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: primaryPurple,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
          ),
        ),
      ],
    );
  }
}