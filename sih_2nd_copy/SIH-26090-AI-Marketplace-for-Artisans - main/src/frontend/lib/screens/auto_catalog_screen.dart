import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

import 'products_screen.dart';
import '../api.dart';
import '../auth.dart'; 

class AutoCatalogScreen extends StatefulWidget {
  // Receives the enhanced image from the Studio screen
  final Uint8List imageBytes;

  const AutoCatalogScreen({super.key, required this.imageBytes});
  
  @override
  State<AutoCatalogScreen> createState() => _AutoCatalogScreenState();
}

class _AutoCatalogScreenState extends State<AutoCatalogScreen> {
  // --- TERRACOTTA THEME COLORS ---
  static const Color background = Color(0xFFF5F2EB); 
  static const Color primaryPurple = Color(0xFF9E4733); 
  static const Color lightLavender = Color(0xFFEADCCF); 
  static const Color textDark = Color(0xFF2C221E); 
  static const Color textMuted = Color(0xFF8C7A70); 

  String selectedLanguage = 'English';
  String targetLanguage = 'Hindi';

  // --- BACKEND LOGIC VARIABLES ---
  final TextEditingController _costController = TextEditingController(text: "150");
  XFile? _audioFile;
  bool _isProcessing = false;
  
  // Variables to hold Groq's response
  String? _titleEn;
  String? _titleHi;
  String? _descEn;
  String? _descHi;
  String? _titleRegional;
  String? _descRegional;
  String? _material;
  String? _craftTechnique;
  double? _suggestedPrice;
  String? _pricingExplanation;
  bool _isSaving = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Uint8List? _audioBytes;

  // Pick a voice note (Using video picker as a workaround for easy file picking on Web)
  Future<void> _pickAudioFile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? media = await picker.pickVideo(source: ImageSource.gallery);
    if (media != null) {
      setState(() {
        _audioFile = media;
      });
      _audioBytes = await media.readAsBytes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice note attached successfully!')),
      );
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      if (path != null) {
        final file = XFile(path);
        setState(() {
          _audioFile = file;
          _isRecording = false;
        });
        _audioBytes = await file.readAsBytes();
      }
      return;
    }
    if (!await _recorder.hasPermission()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission is required.')));
      return;
    }
    final path = 'craftconnect_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    setState(() => _isRecording = true);
  }

  Future<void> _playAudio() async {
    if (_audioBytes == null) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(BytesSource(_audioBytes!));
      setState(() => _isPlaying = true);
    }
  }

  // Send Image + Audio + Cost to FastAPI
  Future<void> _generateListing() async {
    if (_audioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach a voice note describing the product first.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Pointing to your local FastAPI backend
      var uri = Uri.parse('$apiBaseUrl/process-product-listing/');
      var request = http.MultipartRequest('POST', uri);

      // 1. Attach the image
      request.files.add(
        http.MultipartFile.fromBytes('image', widget.imageBytes, filename: 'product.jpg')
      );

      // 2. Attach the audio file
      var audioBytes = await _audioFile!.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('audio', audioBytes, filename: _audioFile!.name)
      );

      // 3. Attach the material cost
      request.fields['material_cost'] = _costController.text;
      request.fields['target_language'] = targetLanguage;

      // Send to FastAPI!
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Decode the JSON response from Groq
        var data = jsonDecode(utf8.decode(response.bodyBytes));
        
        setState(() {
          _titleEn = data['product_title_en'];
          _descEn = data['description_en'];
          _titleHi = data['product_title_hi'];
          _descHi = data['description_hi'];
           _titleRegional = data['product_title_regional'] ?? data['product_title_hi'];
           _descRegional = data['description_regional'] ?? data['description_hi'];
           _material = data['material'];
           _craftTechnique = data['craft_technique'];
          _suggestedPrice = data['pricing']['suggested_price_inr'];
          _pricingExplanation = data['pricing']['pricing_explanation'];
          _isProcessing = false;
        });
      } else {
        throw Exception('Server failed to process listing: ${response.statusCode}');
      }
    } catch (e) {
      setState(() { _isProcessing = false; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to backend: $e')),
      );
    }
  }

  Future<void> _saveToCatalog() async {
    if (_titleEn == null || _audioFile == null) { return; }
    if (Auth.artisanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to save products.')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/products/save'));
      request.fields['artisan_id'] = Auth.artisanId!;
      request.fields['listing_data'] = jsonEncode({
        'product_title_en': _titleEn,
        'description_en': _descEn,
        'product_title_hi': _titleHi,
        'description_hi': _descHi,
         'product_title_regional': _titleRegional,
         'description_regional': _descRegional,
         'regional_language': targetLanguage,
         'material': _material,
         'craft_technique': _craftTechnique,
        'pricing': {
          'suggested_price_inr': _suggestedPrice,
          'pricing_explanation': _pricingExplanation,
        },
        'material_cost': double.tryParse(_costController.text) ?? 0,
      });
      request.files.add(http.MultipartFile.fromBytes('image', widget.imageBytes, filename: 'product.jpg'));
      request.files.add(http.MultipartFile.fromBytes('audio', await _audioFile!.readAsBytes(), filename: _audioFile!.name));
      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode != 200) throw Exception(_error(response.body));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product saved successfully.')));
       // Keep the existing navigation stack so My Products always has a
       // working back button. Removing every route made it the app root.
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProductsScreen()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioPlayer.dispose();
    _costController.dispose();
    super.dispose();
  }

  String _error(String body) {
    try { return jsonDecode(body)['detail'].toString(); } catch (_) { return 'Could not save product'; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Auto Catalog',
          style: TextStyle(fontWeight: FontWeight.w600, color: textDark),
        ),
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // Image Preview (Carried over from Studio)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                widget.imageBytes, 
                height: 180, 
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 180,
                  child: Center(
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Turn your craft into a professional product listing.',
              style: TextStyle(fontSize: 15, color: textMuted),
            ),
            const SizedBox(height: 24),

            // Material Cost Input
            TextField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Raw Material Cost (₹)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.currency_rupee, color: primaryPurple),
              ),
            ),
            const SizedBox(height: 24),

            // Voice Input Card
             Container(
               padding: const EdgeInsets.all(22),
               decoration: BoxDecoration(
                 color: _audioFile != null ? Colors.green.withOpacity(0.1) : lightLavender,
                 borderRadius: BorderRadius.circular(22),
                 border: Border.all(
                   color: _audioFile != null ? Colors.green : Colors.transparent,
                   width: 2,
                 ),
               ),
               child: Column(
                 children: [
                   InkWell(
                     onTap: _pickAudioFile,
                     borderRadius: BorderRadius.circular(22),
                     child: Column(
                       children: [
                         Container(
                           padding: const EdgeInsets.all(18),
                           decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                           child: Icon(_audioFile != null ? Icons.check_circle_rounded : Icons.mic_none_rounded, size: 38, color: _audioFile != null ? Colors.green : primaryPurple),
                         ),
                         const SizedBox(height: 16),
                         Text(_audioFile != null ? 'Voice Note Attached' : 'Describe your product', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textDark)),
                         const SizedBox(height: 7),
                         Text(_audioFile != null ? 'Ready for AI processing' : 'Choose an audio file or record a voice note.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: textMuted)),
                       ],
                     ),
                   ),
                   const SizedBox(height: 14),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       OutlinedButton.icon(onPressed: _isRecording ? _toggleRecording : _pickAudioFile, icon: Icon(_isRecording ? Icons.stop : Icons.audio_file_outlined), label: Text(_isRecording ? 'Stop recording' : 'Choose audio')),
                       const SizedBox(width: 10),
                       ElevatedButton.icon(onPressed: _toggleRecording, icon: Icon(_isRecording ? Icons.stop_circle_outlined : Icons.mic), label: Text(_isRecording ? 'Stop' : 'Record')),
                       if (_audioFile != null) ...[
                         const SizedBox(width: 10),
                         IconButton(onPressed: _playAudio, icon: Icon(_isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline, color: primaryPurple), tooltip: _isPlaying ? 'Pause preview' : 'Play preview'),
                       ],
                     ],
                   ),
                 ],
               ),
             ),
            
             const SizedBox(height: 18),

             DropdownButtonFormField<String>(
               value: targetLanguage,
               decoration: InputDecoration(labelText: 'Regional listing language', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
               items: const [
                 DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
                 DropdownMenuItem(value: 'Marathi', child: Text('Marathi')),
                 DropdownMenuItem(value: 'Tamil', child: Text('Tamil')),
                 DropdownMenuItem(value: 'Bengali', child: Text('Bengali')),
               ],
               onChanged: (value) => setState(() => targetLanguage = value ?? 'Hindi'),
             ),
             const SizedBox(height: 24),

            // Generate Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _generateListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isProcessing 
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20, width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                        ),
                        SizedBox(width: 12),
                        Text('Analyzing Product...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    )
                  : const Text(
                      'Generate Listing & Pricing',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
              ),
            ),

            const SizedBox(height: 32),

            // Generated Results Display
            if (_titleEn != null) ...[
              const Text(
                'Generated Listing',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
              ),
              const SizedBox(height: 14),

              // Language Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedLanguage,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'English', child: Text('English')),
                      DropdownMenuItem(value: 'Regional', child: Text('Regional language')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedLanguage = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Dynamic Info Cards
              _infoCard(
                icon: Icons.shopping_bag_outlined,
                title: 'Product Title',
                   value: selectedLanguage == 'English' ? _titleEn! : (_titleRegional ?? _titleHi!),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _tag(_material ?? 'Material not specified', Icons.spa_outlined),
                  _tag(_craftTechnique ?? 'Technique not specified', Icons.handyman_outlined),
                ],
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Side-by-side language view', style: TextStyle(fontWeight: FontWeight.w600, color: textDark)),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _languageColumn('English', _titleEn!, _descEn!)),
                      const SizedBox(width: 10),
                      Expanded(child: _languageColumn(targetLanguage, _titleRegional ?? _titleHi!, _descRegional ?? _descHi!)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _priceBreakdown(),
              const SizedBox(height: 12),

              _infoCard(
                icon: Icons.currency_rupee_outlined,
                title: 'Suggested Retail Price',
                value: '₹$_suggestedPrice',
              ),
              const SizedBox(height: 12),

              _infoCard(
                icon: Icons.analytics_outlined,
                title: 'AI Pricing Analysis',
                value: _pricingExplanation!,
              ),
              const SizedBox(height: 12),

              _infoCard(
                icon: Icons.description_outlined,
                title: 'Description',
                   value: selectedLanguage == 'English' ? _descEn! : (_descRegional ?? _descHi!),
              ),
              
              const SizedBox(height: 28),

              // Save to Catalog Button
              SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _saveToCatalog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryPurple,
                    side: const BorderSide(color: primaryPurple, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text(
                    'Save to Catalog',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // UI Component for the results
  Widget _infoCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryPurple, size: 25),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: textMuted)),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, IconData icon) => Chip(
        avatar: Icon(icon, size: 16, color: primaryPurple),
        label: Text(label),
        backgroundColor: lightLavender,
        labelStyle: const TextStyle(color: textDark, fontWeight: FontWeight.w500),
      );

  Widget _languageColumn(String label, String title, String description) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: primaryPurple, fontWeight: FontWeight.bold)),
          const SizedBox(height: 7),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: textDark)),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(fontSize: 12, color: textMuted, height: 1.35)),
        ]),
      );

  Widget _priceBreakdown() {
    final materialCost = double.tryParse(_costController.text) ?? 0;
    final suggested = _suggestedPrice ?? 0;
    final margin = suggested - materialCost;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Price breakdown', style: TextStyle(fontWeight: FontWeight.w600, color: textDark)),
        const SizedBox(height: 10),
        _priceRow('Material cost', materialCost),
        _priceRow('Artisan margin & craft value', margin < 0 ? 0 : margin),
        const Divider(),
        _priceRow('Suggested retail price', suggested, emphasize: true),
      ]),
    );
  }

  Widget _priceRow(String label, double value, {bool emphasize = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: emphasize ? textDark : textMuted, fontWeight: emphasize ? FontWeight.w600 : FontWeight.normal)),
          Text('₹${value.toStringAsFixed(0)}', style: TextStyle(color: emphasize ? primaryPurple : textDark, fontWeight: FontWeight.w600)),
        ],
      );
}