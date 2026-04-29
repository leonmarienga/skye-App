import 'package:tflite_plus/tflite_plus.dart';

class TFLiteHelper {
  Future<void> loadModel() async {
    await TflitePlus.loadModel(
      model: "assets/models/model.tflite",
      labels: "assets/models/labels.txt",
    );
  }

  // 👇 Object detection instead of classification
  Future<List<dynamic>?> runInference(String imagePath) async {
    try {
      // TflitePlus.detectObjectOnImage is the correct method for object detection.
      // Ensure your model type (e.g., "SSDMobileNet", "YOLO") matches your actual model.
      return await TflitePlus.detectObjectOnImage(
        path: imagePath,
        model: "SSDMobileNet",
        threshold: 0.4, // Lowered slightly to capture more potential matches
        numResultsPerClass: 1,
        imageMean: 127.5,
        imageStd: 127.5,
      );
    } catch (_) {
      return null;
    }
  }

  void close() => TflitePlus.close();
}
