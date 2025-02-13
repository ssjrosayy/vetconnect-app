import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class SkinDiseaseDetector {
  late Interpreter _interpreter;
  late Map<String, dynamic> _metadata;
  static const int inputSize = 224;
  static const double _minimumConfidenceThreshold =
      0.15; // 15% minimum confidence

  Future<void> loadModel() async {
    try {
      // Load the TFLite model
      _interpreter = await Interpreter.fromAsset(
          'assets/models/skin_disease_model.tflite');

      // Load disease metadata
      final String metadataStr = await rootBundle
          .loadString('assets/models/skin_disease_metadata.json');
      _metadata = json.decode(metadataStr);
    } catch (e) {
      throw Exception('Failed to load skin disease model: $e');
    }
  }

  Future<String> detectDisease(File imageFile, String animalType) async {
    try {
      if (!['dog', 'cat'].contains(animalType.toLowerCase())) {
        throw Exception('Only dog and cat skin diseases are supported');
      }

      // Load and preprocess the image
      final image = img.decodeImage(await imageFile.readAsBytes())!;

      // Validate image content
      if (!_isValidImage(image)) {
        return '''
Invalid Image Detected

The uploaded image does not appear to be a clear photo of a pet's skin condition.

Please ensure:
• The image shows a clear view of the affected skin area
• The image is well-lit and in focus
• The image is taken close enough to show the skin condition details
• The image contains a pet's skin/fur and not other objects

Try uploading a different photo that clearly shows the skin condition you want to analyze.''';
      }

      final processedImage = _preprocessImage(image);

      // Run inference
      final output = List<double>.filled(_getDiseaseCount(animalType), 0)
          .reshape([1, _getDiseaseCount(animalType)]);

      _interpreter.run(processedImage, output);

      // Check if any prediction has sufficient confidence
      if (!_hasValidPredictions(output[0])) {
        return '''
No Skin Condition Detected

The model could not identify any known skin conditions in this image with sufficient confidence.

This might be because:
• The image doesn't show a clear skin condition
• The image shows a different type of subject (like a wall or object)
• The skin condition is not one of the known conditions
• The image quality is too low for accurate analysis

Please try:
• Taking a clearer, closer photo of the affected area
• Ensuring good lighting when taking the photo
• Making sure the skin condition is clearly visible
• Confirming the photo shows a pet's skin condition''';
      }

      // Process results
      return _processResults(output[0], animalType);
    } catch (e) {
      throw Exception('Error detecting skin disease: $e');
    }
  }

  bool _isValidImage(img.Image image) {
    // Check image dimensions
    if (image.width < 100 || image.height < 100) {
      return false;
    }

    // Check if image is too blurry
    if (_calculateBlurriness(image) > 100) {
      return false;
    }

    // Check if image has enough color variation (not just a solid wall)
    if (!_hasEnoughColorVariation(image)) {
      return false;
    }

    return true;
  }

  double _calculateBlurriness(img.Image image) {
    // Convert to grayscale for blur detection
    var grayscale = img.grayscale(image);
    var sum = 0.0;

    // Calculate Laplacian variance (measure of image sharpness)
    for (var y = 1; y < grayscale.height - 1; y++) {
      for (var x = 1; x < grayscale.width - 1; x++) {
        var pixel = grayscale.getPixel(x, y);
        // Convert Pixel to grayscale value (0-255)
        var center = (pixel.r + pixel.g + pixel.b) ~/ 3;
        var right = (grayscale.getPixel(x + 1, y).r +
                grayscale.getPixel(x + 1, y).g +
                grayscale.getPixel(x + 1, y).b) ~/
            3;
        var left = (grayscale.getPixel(x - 1, y).r +
                grayscale.getPixel(x - 1, y).g +
                grayscale.getPixel(x - 1, y).b) ~/
            3;
        var top = (grayscale.getPixel(x, y + 1).r +
                grayscale.getPixel(x, y + 1).g +
                grayscale.getPixel(x, y + 1).b) ~/
            3;
        var bottom = (grayscale.getPixel(x, y - 1).r +
                grayscale.getPixel(x, y - 1).g +
                grayscale.getPixel(x, y - 1).b) ~/
            3;

        var laplacian = -4 * center + right + left + top + bottom;
        sum += laplacian * laplacian;
      }
    }
    return sum / (image.width * image.height);
  }

  bool _hasEnoughColorVariation(img.Image image) {
    var histogram = List.filled(256, 0);
    var totalPixels = image.width * image.height;

    // Calculate grayscale histogram
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        var pixel = image.getPixel(x, y);
        // Convert RGB to grayscale value (0-255)
        var gray = (pixel.r + pixel.g + pixel.b) ~/ 3;
        histogram[gray]++;
      }
    }

    // Check if any single color value dominates (>80% of pixels)
    for (var count in histogram) {
      if (count / totalPixels > 0.8) {
        return false; // Image is likely a solid color (like a wall)
      }
    }

    return true;
  }

  bool _hasValidPredictions(List<double> predictions) {
    // Check if any prediction exceeds the minimum confidence threshold
    return predictions
        .any((confidence) => confidence > _minimumConfidenceThreshold);
  }

  List _preprocessImage(img.Image image) {
    // Resize image to model input size
    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
    );

    // Convert to float array and normalize
    var imageArray = List.generate(
      1,
      (index) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) => List.generate(
            3,
            (c) => resized.getPixel(x, y)[c] / 255.0,
          ),
        ),
      ),
    );

    return imageArray;
  }

  int _getDiseaseCount(String animalType) {
    final diseases = _metadata['diseases'][animalType] as List;
    return diseases.length;
  }

  String _processResults(List<double> predictions, String animalType) {
    // Get diseases for the specific animal type
    final diseases = _metadata['diseases'][animalType] as List;

    // Create list of disease-confidence pairs
    var results = List<MapEntry<String, double>>.generate(
      diseases.length,
      (index) => MapEntry(
        diseases[index]['name'] as String,
        predictions[index],
      ),
    );

    // Sort by confidence (highest first)
    results.sort((a, b) => b.value.compareTo(a.value));

    // Format results
    final buffer = StringBuffer();
    buffer.writeln('Skin Disease Analysis Results:');
    buffer.writeln('');

    // Add top 3 predictions with confidence scores
    for (var i = 0; i < 3 && i < results.length; i++) {
      final confidence = (results[i].value * 100).toStringAsFixed(1);
      buffer.writeln('${i + 1}. ${results[i].key}: $confidence%');

      // Add disease patterns for additional context
      final disease = diseases.firstWhere(
        (d) => d['name'] == results[i].key,
        orElse: () => null,
      );
      if (disease != null) {
        buffer.writeln(
            '   Common patterns: ${(disease['patterns'] as List).join(', ')}');
      }
      buffer.writeln('');
    }

    // Add warning message
    buffer.writeln('\n⚠️ Important:');
    buffer.writeln(
        'This is an AI-based analysis and should not replace professional veterinary diagnosis.');
    buffer.writeln(
        'Please consult with a veterinarian for proper diagnosis and treatment.');

    // Add severity warning if confidence is high
    if (results.isNotEmpty && results.first.value > 0.8) {
      buffer.writeln('\n🚨 High confidence detection:');
      buffer.writeln('Immediate veterinary consultation is recommended.');
    }

    return buffer.toString();
  }

  void dispose() {
    _interpreter.close();
  }
}
