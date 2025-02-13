import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'dart:io';

class SymptomAnalyzer {
  late Map<String, dynamic> _metadata;
  Map<String, Interpreter> _interpreters = {};
  bool _isInitialized = false;

  // Add severity levels for symptoms
  final Map<String, int> _symptomSeverity = {
    'fever': 3,
    'difficulty_breathing': 4,
    'seizures': 5,
    'severe_bleeding': 5,
    'collapse': 5,
    'unconsciousness': 5,
    'severe_pain': 4,
    'poisoning': 5,
    'trauma': 4,
    'prolonged_labor': 5,
  };

  Future<void> loadModel() async {
    if (_isInitialized) {
      print('Models already initialized');
      return;
    }

    try {
      print('Starting symptom analyzer initialization...');
      print('Current directory context: ${Directory.current.path}');

      // Load metadata first
      print('Loading metadata...');
      try {
        final jsonString =
            await rootBundle.loadString('assets/models/symptoms_metadata.json');
        print('Loaded metadata JSON successfully');
        _metadata = json.decode(jsonString);
        print('Parsed metadata: ${_metadata.keys.toList()}');
      } catch (e, stackTrace) {
        print('❌ Error loading metadata: $e');
        print('Stack trace: $stackTrace');
        throw Exception('Failed to load symptoms metadata: $e');
      }

      // Load models for each animal type
      for (final animalType in ['dog', 'cat']) {
        print('Loading model for $animalType...');
        try {
          final interpreterOptions = InterpreterOptions()..threads = 4;

          _interpreters[animalType] = await Interpreter.fromAsset(
            'assets/models/symptoms_${animalType}_model.tflite',
            options: interpreterOptions,
          );
          print('✓ TFLite model loaded successfully for $animalType');
        } catch (e, stackTrace) {
          print('❌ Error loading TFLite model for $animalType: $e');
          print('Stack trace: $stackTrace');
          throw Exception('Failed to load TFLite model for $animalType: $e');
        }
      }

      _isInitialized = true;
      print('✓ All models initialized successfully');
    } catch (e, stackTrace) {
      print('❌ Error in loadModel: $e');
      print('Stack trace: $stackTrace');
      _isInitialized = false;
      rethrow;
    }
  }

  List<String> getSymptoms(String animalType) {
    if (!_isInitialized) {
      throw Exception('Symptom analyzer not initialized');
    }
    if (!_metadata.containsKey('symptoms') ||
        !_metadata['symptoms'].containsKey(animalType)) {
      throw Exception('No symptoms found for $animalType');
    }
    return List<String>.from(_metadata['symptoms'][animalType]);
  }

  Future<Map<String, dynamic>> analyzeSymptoms(
      String animalType, Map<String, bool> selectedSymptoms) async {
    if (!_isInitialized) {
      throw Exception('Symptom analyzer not initialized');
    }

    try {
      print('Analyzing symptoms for $animalType');
      print('Selected symptoms: $selectedSymptoms');

      // Check for emergency conditions first
      final emergencyResult = _checkEmergencyConditions(selectedSymptoms);
      if (emergencyResult != null) {
        print('Emergency condition detected!');
        return {
          'disease': 'EMERGENCY CONDITION',
          'risk': 'CRITICAL',
          'confidence': 1.0,
          'details': emergencyResult
        };
      }

      if (!_interpreters.containsKey(animalType)) {
        throw Exception('No model found for $animalType');
      }

      // Get list of all possible symptoms for this animal type
      final symptoms = _metadata['symptoms'][animalType] as List<dynamic>;
      print('Processing symptoms for $animalType: $symptoms');

      // Get tensor shapes
      final interpreter = _interpreters[animalType]!;
      final inputTensor = interpreter.getInputTensor(0);
      final outputTensor = interpreter.getOutputTensor(0);

      print('Input tensor shape: ${inputTensor.shape}');
      print('Output tensor shape: ${outputTensor.shape}');

      // Create input vector with correct size
      final inputShape = inputTensor.shape;
      print('Input tensor shape: $inputShape');
      print('Number of symptoms: ${symptoms.length}');

      // Create input vector with the correct size (12)
      var reshapedInput = List<double>.filled(12, 0.0);

      // Map selected symptoms to the first 12 positions
      var selectedSymptomsList = selectedSymptoms.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      for (int i = 0; i < selectedSymptomsList.length && i < 12; i++) {
        final symptomIndex = symptoms.indexOf(selectedSymptomsList[i]);
        if (symptomIndex != -1 && symptomIndex < 12) {
          reshapedInput[symptomIndex] = 1.0;
        }
      }

      print('Input data: $reshapedInput');
      print('Input vector length: ${reshapedInput.length}');

      // Validate input shape
      if (reshapedInput.length != inputShape[1]) {
        throw ArgumentError(
            'Input shape mismatch: got ${reshapedInput.length}, expected ${inputShape[1]}');
      }

      // Create output buffer with proper shape [1, 12]
      var outputShape = outputTensor.shape;
      print('Creating output buffer with shape: $outputShape');
      if (outputShape[1] != 12) {
        throw ArgumentError(
            'Unexpected output shape: got $outputShape, expected [1, 12]');
      }
      var outputBuffer = List.filled(outputShape[1], 0.0);

      // Prepare inputs and outputs
      final inputs = {
        0: [reshapedInput]
      };
      final outputs = {
        0: [outputBuffer]
      };

      // Run inference
      print('Running model inference...');
      try {
        interpreter.run(inputs, outputs);
        print('Inference completed successfully');
      } catch (e) {
        print('Error during inference: $e');
        rethrow;
      }
      print('Model output shape: ${outputs[0]!.length}');
      print('Model output raw: ${outputs[0]}');

      // Get diseases for this animal type
      final diseases = _metadata['diseases'][animalType] as List<dynamic>;
      print(
          'Available diseases for $animalType: ${diseases.map((d) => d['name']).toList()}');

      // Process the output probabilities
      var probabilities = outputs[0]![0];
      print('Probabilities: $probabilities');

      // Find the highest probability and its index
      var maxProb = double.negativeInfinity;
      var maxIndex = 0;
      for (var i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
        print('Disease $i probability: ${probabilities[i]}');
      }

      // Sort diseases by number of matching symptoms and probability
      var diseasePredictions = <Map<String, dynamic>>[];

      for (var disease in diseases) {
        final diseaseSymptoms = disease['symptoms'] as List<dynamic>;
        final matchedSymptoms = selectedSymptoms.entries
            .where((e) => e.value && diseaseSymptoms.contains(e.key))
            .map((e) => e.key)
            .toList();

        if (matchedSymptoms.isNotEmpty) {
          final matchScore = matchedSymptoms.length / diseaseSymptoms.length;
          diseasePredictions.add({
            'disease': disease,
            'matchedSymptoms': matchedSymptoms,
            'matchScore': matchScore,
          });
        }
      }

      // Sort by match score in descending order
      diseasePredictions
          .sort((a, b) => b['matchScore'].compareTo(a['matchScore']));

      // Take top 3 predictions
      final topPredictions = diseasePredictions.take(3).toList();

      if (topPredictions.isEmpty) {
        return {
          'disease': 'Unknown',
          'risk': 'LOW',
          'confidence': 0.0,
          'details': 'No matching diseases found for the given symptoms.'
        };
      }

      // Format the detailed results
      final primaryDisease = topPredictions.first['disease'];
      final diseaseName = primaryDisease['name'] as String;
      final risk = primaryDisease['risk'] as String;

      final details = '''
Primary Condition: $diseaseName
Risk Level: $risk
Confidence: ${(topPredictions.first['matchScore'] * 100).toStringAsFixed(1)}%

Selected Symptoms:
${selectedSymptoms.entries.where((e) => e.value).map((e) => '- ${e.key.replaceAll('_', ' ').toUpperCase()}').join('\n')}

Possible Conditions:
${topPredictions.map((pred) {
        final disease = pred['disease'];
        final matchedSymps = pred['matchedSymptoms'] as List<String>;
        return '''
${disease['name']} (${disease['risk']})
Matching Symptoms:
${matchedSymps.map((s) => '  - ${s.replaceAll('_', ' ').toUpperCase()}').join('\n')}
Confidence: ${(pred['matchScore'] * 100).toStringAsFixed(1)}%
''';
      }).join('\n')}

Note: This is an AI-based prediction. Please consult with a veterinarian for confirmation.
''';

      return {
        'disease': diseaseName,
        'risk': risk,
        'confidence': topPredictions.first['matchScore'],
        'details': details
      };
    } catch (e, stackTrace) {
      print('Error analyzing symptoms: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  String? _checkEmergencyConditions(Map<String, bool> symptoms) {
    final emergencySymptoms = symptoms.entries
        .where((e) => e.value && (_symptomSeverity[e.key] ?? 0) >= 5)
        .map((e) => e.key.replaceAll('_', ' '))
        .toList();

    if (emergencySymptoms.isNotEmpty) {
      return '''
⚠️ EMERGENCY CONDITION DETECTED ⚠️

Critical symptoms found:
${emergencySymptoms.map((s) => '- ${s.toUpperCase()}').join('\n')}

IMMEDIATE VETERINARY ATTENTION REQUIRED
Please contact your nearest emergency veterinary clinic immediately.
''';
    }
    return null;
  }
}
