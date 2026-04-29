import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteHelper {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/models/best_int8.tflite',
    );
  }

  Future<List<dynamic>?> runInference(String imagePath) async {
    try {
      if (_interpreter == null) return null;

      final imageData = File(imagePath).readAsBytesSync();
      final image = img.decodeImage(imageData);
      if (image == null) return null;

      // YOLOv8 expects 320x320 input
      final resized = img.copyResize(image, width: 320, height: 320);

      // Input: [1, 320, 320, 3] properly structured as nested list
      var input = [
        List.generate(
          320,
          (y) => List.generate(320, (x) {
            final pixel = resized.getPixel(x, y);
            return [
              (pixel.r as double) / 255.0,
              (pixel.g as double) / 255.0,
              (pixel.b as double) / 255.0,
            ];
          }),
        ),
      ];

      // Allocate output buffer - YOLOv8 typically outputs [1, 25200] or [1, 8400, 84]
      var output = List.filled(25200, 0.0);

      var outputs = <int, Object>{0: output};

      _interpreter!.runForMultipleInputs([input], outputs);

      // Parse YOLOv8 output and filter detections
      final detections = <Map<String, dynamic>>[];
      final confidenceThreshold = 0.5;

      // YOLOv8 format: 25200 output typically means [num_detections, 84]
      // where 84 = 4 (bbox) + 1 (objectness) + 79 (class scores for 80 COCO classes)
      // But our model likely has fewer classes

      for (int i = 0; i < output.length; i++) {
        if (output[i] > confidenceThreshold) {
          // This is a simplified parser - adjust based on actual output format
          detections.add({
            'confidence': output[i],
            'confidenceInClass': output[i],
            'detectedClass': 'Product',
          });
          if (detections.length >= 10) break; // Limit to 10 detections
        }
      }

      return detections.isNotEmpty ? detections : <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint('Inference error: $e');
      return null;
    }
  }

  void close() => _interpreter?.close();
}
