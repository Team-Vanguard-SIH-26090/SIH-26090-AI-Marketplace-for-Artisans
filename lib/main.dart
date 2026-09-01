import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIH Image Processor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const ImageProcessorPage(),
    );
  }
}

class ImageProcessorPage extends StatefulWidget {
  
  const ImageProcessorPage({super.key});

  @override
  State<ImageProcessorPage> createState() => _ImageProcessorPageState();
}

class _ImageProcessorPageState extends State<ImageProcessorPage> {
  late stt.SpeechToText speech;
bool isListening = false;
String spokenText = '';
  final ImagePicker picker = ImagePicker();

  Uint8List? originalImage;
  Uint8List? processedImage;

  bool loading = false;
  String message = 'Select or capture an image to begin';

  // =========================
  // GALLERY
  // =========================
  Future<void> selectImage() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      setState(() {
        originalImage = bytes;
        processedImage = null;
        loading = true;
        message = 'Processing image...';
      });

      await sendToBackend(image);
    } catch (e) {
      setState(() {
        loading = false;
        message = 'Could not select image: $e';
      });
    }
  }

  // =========================
  // CAMERA
  // =========================
  Future<void> takePhoto() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      setState(() {
        originalImage = bytes;
        processedImage = null;
        loading = true;
        message = 'Processing captured photo...';
      });

      await sendToBackend(image);
    } catch (e) {
      setState(() {
        loading = false;
        message = 'Could not access camera: $e';
      });
    }
  }

  // =========================
  // SEND IMAGE TO PYTHON
  // =========================
  Future<void> sendToBackend(XFile image) async {
    try {
      final url = Uri.parse(
        'http://127.0.0.1:8000/remove-background',
      );

      final request = http.MultipartRequest(
        'POST',
        url,
      );

      final bytes = await image.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: image.name,
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final result = await response.stream.toBytes();

        setState(() {
          processedImage = result;
          loading = false;
          message = 'Background removed successfully!';
        });
      } else {
        setState(() {
          loading = false;
          message = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        message = 'Connection error: $e';
      });
    }
  }

  // =========================
  // UI
  // =========================
  @override
void initState() {
  super.initState();
  speech = stt.SpeechToText();
}
Future<void> startListening() async {
  final available = await speech.initialize();

  if (!available) {
    setState(() {
      message = 'Speech recognition is not available';
    });
    return;
  }

  setState(() {
    isListening = true;
    message = 'Listening...';
  });

  await speech.listen(
    onResult: (result) {
      setState(() {
        spokenText = result.recognizedWords;
      });
    },
  );
}

Future<void> stopListening() async {
  await speech.stop();

  setState(() {
    isListening = false;
    message = spokenText.isEmpty
        ? 'No speech detected'
        : 'Speech captured successfully!';
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Image Processor'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Icon(
              Icons.auto_fix_high,
              size: 70,
            ),

            const SizedBox(height: 15),

            const Text(
              'AI Background Remover',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              message,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // ORIGINAL IMAGE
            if (originalImage != null) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Original Image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Image.memory(
                originalImage!,
                height: 250,
              ),

              const SizedBox(height: 30),
            ],

            // LOADING
            if (loading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
            ],

            // PROCESSED IMAGE
            if (processedImage != null) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Processed Image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Image.memory(
                processedImage!,
                height: 300,
              ),

              const SizedBox(height: 30),
            ],

            // BUTTONS
            if (spokenText.isNotEmpty) ...[
  const SizedBox(height: 20),
  Text(
    'You said: $spokenText',
    textAlign: TextAlign.center,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
    ),
  ),
  const SizedBox(height: 20),
],

ElevatedButton.icon(
  onPressed: isListening ? stopListening : startListening,
  icon: Icon(
    isListening ? Icons.stop : Icons.mic,
  ),
  label: Text(
    isListening ? 'Stop Listening' : 'Speak',
  ),
),

const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : selectImage,
                    icon: const Icon(Icons.photo),
                    label: const Text('Gallery'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}