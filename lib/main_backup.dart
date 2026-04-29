import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'attributes.dart';
import 'tflite_helper.dart';

void main() => runApp(const SkyeApp());

class SkyeApp extends StatefulWidget {
  const SkyeApp({super.key});
  @override
  State<SkyeApp> createState() => _SkyeAppState();
}

class _SkyeAppState extends State<SkyeApp> {
  final helper = TFLiteHelper();
  File? _image;
  List<dynamic>? _results;
  bool _isModelLoaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    helper
        .loadModel()
        .then((_) {
          if (mounted) {
            setState(() => _isModelLoaded = true);
            debugPrint('Model loaded successfully');
          }
        })
        .catchError((e) {
          debugPrint('Error loading model: $e');
          if (mounted) {
            setState(() => _error = 'Failed to load model: $e');
          }
        });
  }

  @override
  void dispose() {
    helper.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (!_isModelLoaded) return;

    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _image = File(picked.path));
        debugPrint('Image selected: ${picked.path}');
        final res = await helper.runInference(picked.path);
        if (mounted) {
          setState(() {
            _results = res;
            _error = null;
            if (res == null || res.isEmpty) {
              debugPrint('No detections returned from model');
            }
          });
        }
      } else {
        debugPrint('No image selected');
      }
    } catch (e) {
      debugPrint('Error picking/processing image: $e');
      if (mounted) {
        setState(() => _error = 'Error: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Skye – Product Detector')),
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (!_isModelLoaded) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isModelLoaded ? _pickImage : null,
                child: const Text('Select Image'),
              ),
              const SizedBox(height: 16),
              if (_image != null)
                Image.file(_image!, height: 300, fit: BoxFit.contain),
              if (_results != null && _results!.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No products detected. Try a clearer angle.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              if (_results != null && _results!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Found ${_results!.length} product(s)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              if (_results != null)
                ..._results!.map<Widget>((r) {
                  // Object detection (YOLO/SSD) uses 'detectedClass' and 'confidenceInClass'
                  // We use the ?? operator to fall back to 'label'/'confidence' for compatibility
                  final label =
                      (r['detectedClass'] ?? r['label'])?.toString() ??
                      'Unknown';
                  final confidence =
                      ((r['confidenceInClass'] ?? r['confidence']) as num? ??
                          0.0) *
                      100;
                  final attr = ProductAttributes.getByName(label);

                  return ListTile(
                    title: Text(label),
                    subtitle: Text(
                      'Confidence: ${confidence.toStringAsFixed(2)}%',
                    ),
                    onTap: () => showDialog(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: Text(label),
                          content: Text(
                            attr != null
                                ? 'Brand: ${attr['brand']}\nVariant: ${attr['variant']}\nPrice: ${attr['price']}\nExpiry: ${attr['expiry']}\n\nConfidence: ${confidence.toStringAsFixed(2)}%'
                                : 'Attributes: $label detected with ${confidence.toStringAsFixed(2)}% confidence.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Close'),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
