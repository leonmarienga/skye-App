import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

Future<void> inspectModel() async {
  final interpreter = await Interpreter.fromAsset(
    'assets/models/best_int8.tflite',
  );

  debugPrint('=== Model Input Details ===');
  for (int i = 0; i < interpreter.getInputTensors().length; i++) {
    final tensor = interpreter.getInputTensors()[i];
    debugPrint('Input $i:');
    debugPrint('  Shape: ${tensor.shape}');
    debugPrint('  Type: ${tensor.type}');
    debugPrint('  ElementCount: ${_calculateElements(tensor.shape)}');
  }

  debugPrint('\n=== Model Output Details ===');
  for (int i = 0; i < interpreter.getOutputTensors().length; i++) {
    final tensor = interpreter.getOutputTensors()[i];
    debugPrint('Output $i:');
    debugPrint('  Shape: ${tensor.shape}');
    debugPrint('  Type: ${tensor.type}');
    debugPrint('  ElementCount: ${_calculateElements(tensor.shape)}');
  }

  interpreter.close();
}

int _calculateElements(List<int> shape) {
  int count = 1;
  for (int dim in shape) {
    count *= dim;
  }
  return count;
}

void main() {
  inspectModel();
}
