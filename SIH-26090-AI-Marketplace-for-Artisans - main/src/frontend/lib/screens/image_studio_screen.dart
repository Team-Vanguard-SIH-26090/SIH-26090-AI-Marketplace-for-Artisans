import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'auto_catalog_screen.dart';
import '../api_config.dart';
import '../auth.dart';

class ImageStudioScreen extends StatefulWidget {
  const ImageStudioScreen({super.key});

  @override
  State<ImageStudioScreen> createState() => _ImageStudioScreenState();
}

class _ImageStudioScreenState extends State<ImageStudioScreen> {
  // --- UPDATED TERRACOTTA THEME COLORS ---
  static const Color background = Color(0xFFF5F2EB); // Warm Sand
  static const Color primaryPurple = Color(0xFF9E4733); // Terracotta 
  static const Color lightLavender = Color(0xFFEADCCF); // Soft Almond
  static const Color cardLavender = Color(0xFFF2EAE1); // Warm Off-White
  static const Color textDark = Color(0xFF2C221E); // Espresso Brown
  static const Color textMuted = Color(0xFF8C7A70); // Earthy Grey

  Uint8List? selectedImage;

  bool isEnhancing = false;
  bool imageEnhanced = false;

  bool removeBackground = false;
  bool improveLighting = false;
  bool smartCrop = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      final Uint8List imageBytes = await image.readAsBytes();

      setState(() {
        selectedImage = imageBytes;
        imageEnhanced = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo selected successfully!'),
        ),
      );
    }
  }

  Future<void> _captureImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (mounted) {
      setState(() {
        selectedImage = bytes;
        imageEnhanced = false;
      });
    }
  }

  Future<void> _enhanceImage() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product photo first.'),
        ),
      );
      return;
    }

    setState(() {
      isEnhancing = true;
    });

    try {
      // Uses the dynamic base URL from api_config.dart automatically
      var uri = Uri.parse('$apiBaseUrl/enhance-image/');

      var request = http.MultipartRequest('POST', uri);
      if (Auth.artisanId != null) request.fields['artisan_id'] = Auth.artisanId!;

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          selectedImage!,
          filename: 'upload.jpg',
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final contentType = response.headers['content-type']?.toLowerCase() ?? '';

      if (response.statusCode == 200 &&
          contentType.startsWith('image/') &&
          response.bodyBytes.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          selectedImage = response.bodyBytes;
          isEnhancing = false;
          imageEnhanced = true;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo enhanced successfully by AI backend!'),
          ),
        );
      } else {
        throw Exception(
          response.statusCode == 200
              ? 'The backend returned an invalid enhanced image.'
              : 'Failed to enhance image on server (${response.statusCode}).',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isEnhancing = false;
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to backend: $e'),
        ),
      );
    }
  }

  void _useEnhancedPhoto() {
    if (selectedImage == null) return;
  
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutoCatalogScreen(imageBytes: selectedImage!),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        title: const Text(
          'AI Image Studio',
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

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              const Text(
                'Make your product photos marketplace-ready.',
                style: TextStyle(
                  fontSize: 15,
                  color: textMuted,
                ),
              ),

              const SizedBox(height: 24),

               Column(
                 children: [
                   InkWell(
                     onTap: _pickImage,
                     borderRadius: BorderRadius.circular(24),
                     child: Container(
                       width: double.infinity,
                       padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                       decoration: BoxDecoration(
                         color: lightLavender,
                         borderRadius: BorderRadius.circular(24),
                         border: Border.all(color: primaryPurple.withValues(alpha: 0.25), width: 1.5),
                       ),
                       child: selectedImage == null
                      ? Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 40,
                                color: primaryPurple,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Add Product Photo',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Upload an image to get started',
                              style: TextStyle(
                                fontSize: 13,
                                color: textMuted,
                              ),
                            ),
                          ],
                        )
                       : Column(
                          children: [
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(18),
                              child: Image.memory(
                                selectedImage!,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  height: 220,
                                  child: Center(
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Tap to change photo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: primaryPurple,
                              ),
                            ),
                          ],
                         ),
                     ),
                   ),
                   if (selectedImage == null)
                     Padding(
                       padding: const EdgeInsets.only(top: 12),
                       child: OutlinedButton.icon(
                         onPressed: _captureImage,
                         icon: const Icon(Icons.camera_alt_outlined),
                         label: const Text('Capture with camera'),
                         style: OutlinedButton.styleFrom(foregroundColor: primaryPurple),
                       ),
                     ),
                 ],
               ),

              const SizedBox(height: 30),

              const Text(
                'AI Enhancements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          removeBackground = !removeBackground;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: _featureCard(
                        Icons.layers_clear_outlined,
                        'Remove Background',
                        selected: removeBackground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          improveLighting = !improveLighting;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: _featureCard(
                        Icons.wb_sunny_outlined,
                        'Improve Lighting',
                        selected: improveLighting,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          smartCrop = !smartCrop;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: _featureCard(
                        Icons.crop_outlined,
                        'Smart Crop',
                        selected: smartCrop,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: isEnhancing ? null : _enhanceImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    disabledBackgroundColor:
                        primaryPurple.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isEnhancing
                      ? const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 22,
                              width: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Enhancing...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          imageEnhanced
                              ? 'Photo Enhanced'
                              : 'Enhance with AI',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),

              if (removeBackground ||
                  improveLighting ||
                  smartCrop) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardLavender,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected enhancements',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (removeBackground)
                        const Text(
                          '✓ Remove Background',
                          style: TextStyle(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                      if (improveLighting)
                        const Text(
                          '✓ Improve Lighting',
                          style: TextStyle(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                      if (smartCrop)
                        const Text(
                          '✓ Smart Crop',
                          style: TextStyle(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              const Text(
                'AI will automatically optimize your product image for online selling.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              if (imageEnhanced)
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _useEnhancedPhoto,
                    icon: const Icon(
                      Icons.check_circle_outline,
                    ),
                    label: const Text(
                      'Use Enhanced Photo',
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
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

              if (imageEnhanced)
                const SizedBox(height: 20),

              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (selectedImage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select an image first.')),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AutoCatalogScreen(imageBytes: selectedImage!),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.auto_awesome_outlined,
                  ),
                  label: const Text(
                    'Create Product Listing',
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
      ),
    );
  }

  Widget _featureCard(
    IconData icon,
    String title, {
    bool selected = false,
  }) {
    return Container(
      height: 125,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
            selected ? lightLavender : cardLavender,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? primaryPurple
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected
                ? primaryPurple
                : primaryPurple.withValues(
                    alpha: 0.7,
                  ),
            size: 27,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }
}