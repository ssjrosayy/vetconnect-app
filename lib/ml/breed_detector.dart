import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'model_manager.dart';

class BreedDetector {
  late final Interpreter _interpreter;
  late final Map<String, dynamic> _metadata;
  late final Map<String, dynamic> _breeds;
  late final Map<int, String> _labelMapping;
  late final List<int> _inputShape;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      print('Breed detector already initialized');
      return;
    }

    try {
      print('Starting breed detector initialization...');

      final modelManager = ModelManager();
      if (!modelManager.isInitialized) {
        print('ModelManager not initialized, initializing now...');
        await modelManager.initializeModels();
        if (!modelManager.isInitialized) {
          throw Exception('Failed to initialize ModelManager');
        }
      }

      print('Getting breed model from ModelManager...');
      _interpreter = modelManager.breedModel;

      print('Getting breed metadata from ModelManager...');
      _metadata = modelManager.breedMetadata;

      // Configure interpreter
      print('Configuring interpreter...');
      _interpreter.allocateTensors();

      final inputTensor = _interpreter.getInputTensor(0);
      final outputTensor = _interpreter.getOutputTensor(0);

      print('Input tensor shape: ${inputTensor.shape}');
      print('Output tensor shape: ${outputTensor.shape}');

      // Process metadata
      print('Processing metadata...');
      _breeds = _metadata['breeds'] as Map<String, dynamic>;
      print('Available breeds for dogs: ${(_breeds['dog'] as List).length}');
      print('Available breeds for cats: ${(_breeds['cat'] as List).length}');

      // Process label mapping
      _labelMapping = {};
      final labelMap = _metadata['label_mapping'] as Map<String, dynamic>;
      labelMap.forEach((key, value) {
        _labelMapping[int.parse(key)] = value.toString();
      });
      print('Label mapping processed: ${_labelMapping.length} labels');

      _inputShape = List<int>.from(_metadata['input_shape']);
      print('Input shape from metadata: $_inputShape');

      _isInitialized = true;
      print('✓ Breed detector initialized successfully');
    } catch (e, stackTrace) {
      print('❌ Error initializing breed detector: $e');
      print('Stack trace: $stackTrace');
      _isInitialized = false;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> detectBreed(File imageFile) async {
    try {
      if (!_isInitialized) {
        throw Exception('Breed detector not initialized');
      }

      // Load and preprocess image
      final image = img.decodeImage(await imageFile.readAsBytes())!;
      final resized = img.copyResize(image, width: 224, height: 224);

      // Get shapes and create buffers
      final inputTensor = _interpreter.getInputTensor(0);
      final outputTensor = _interpreter.getOutputTensor(0);

      print('Input tensor shape: ${inputTensor.shape}');
      print('Output tensor shape: ${outputTensor.shape}');

      // Convert to float32 and normalize
      final inputBuffer = Float32List(1 * 224 * 224 * 3);
      var pixel = 0;

      for (var y = 0; y < resized.height; y++) {
        for (var x = 0; x < resized.width; x++) {
          final p = resized.getPixel(x, y);
          inputBuffer[pixel * 3] = p.r / 255.0;
          inputBuffer[pixel * 3 + 1] = p.g / 255.0;
          inputBuffer[pixel * 3 + 2] = p.b / 255.0;
          pixel++;
        }
      }

      // Create output buffer with exact shape
      final outputShape = outputTensor.shape;
      print('Creating output buffer with shape: $outputShape');
      final outputSize =
          outputShape.reduce((a, b) => a * b); // Calculate total size
      final outputBuffer = Float32List(outputSize);

      // Run inference
      print('Running inference...');
      try {
        final inputs = {
          0: inputBuffer.reshape([1, 224, 224, 3])
        };
        final outputs = {0: outputBuffer};

        _interpreter.runForMultipleInputs(inputs.values.toList(), outputs);
        print('Inference completed successfully');
      } catch (e) {
        print('Error during inference: $e');
        rethrow;
      }

      print('Raw output: $outputBuffer');

      // Apply softmax to get proper probabilities
      final probabilities = _applySoftmax(List<double>.from(outputBuffer));
      print('Softmax probabilities: $probabilities');

      // Get top 3 predictions
      final predictions = <Map<String, dynamic>>[];
      var tempProbs = List<double>.from(probabilities);

      for (var i = 0; i < 3 && i < tempProbs.length; i++) {
        final maxValue = tempProbs.reduce((a, b) => a > b ? a : b);
        final maxIndex = tempProbs.indexOf(maxValue);

        if (maxIndex >= _labelMapping.length) {
          print('Warning: Invalid label index $maxIndex');
          continue;
        }

        final label = _labelMapping[maxIndex]!;
        final parts = label.split('_');

        predictions.add({
          'animal_type': parts[0],
          'breed': parts[1],
          'confidence': maxValue
        });

        tempProbs[maxIndex] = double.negativeInfinity;
      }

      return {
        'primary_prediction': predictions.isNotEmpty ? predictions.first : null,
        'possible_predictions':
            predictions.length > 1 ? predictions.sublist(1) : [],
        'debug_info': {
          'input_shape': inputTensor.shape,
          'output_shape': outputTensor.shape,
          'number_of_breeds': _labelMapping.length,
          'output_size': outputBuffer.length
        }
      };
    } catch (e, stackTrace) {
      print('Error during breed detection: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  void dispose() {
    _interpreter.close();
  }

  // Apply softmax to get proper probabilities
  List<double> _applySoftmax(List<double> logits) {
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);
    final expValues = logits.map((x) => _exp(x - maxLogit)).toList();
    final sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((x) => x / sumExp).toList();
  }

  // Safe exponential function
  double _exp(double x) {
    if (x > 88.0) return double.maxFinite;
    if (x < -88.0) return 0.0;
    double sum = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 10; i++) {
      term *= x / i;
      sum += term;
    }
    return sum;
  }
}
