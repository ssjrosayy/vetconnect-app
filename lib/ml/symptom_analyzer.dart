import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:io';

class SymptomAnalyzer {
  late Map<String, dynamic> _metadata;
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

      // Load metadata
      print('Loading metadata...');
      try {
        final jsonString =
            await rootBundle.loadString('assets/models/symptoms_metadata.json');
        print('Loaded metadata JSON successfully');
        _metadata = json.decode(jsonString);
        print('Parsed metadata: ${_metadata.keys.toList()}');
        _isInitialized = true;
        print('✓ Initialization completed successfully');
      } catch (e, stackTrace) {
        print('❌ Error loading metadata: $e');
        print('Stack trace: $stackTrace');
        throw Exception('Failed to load symptoms metadata: $e');
      }
    } catch (e, stackTrace) {
      print('❌ Error in initialization: $e');
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

      // Get the selected symptom list
      final selectedSymptomsList = selectedSymptoms.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      if (selectedSymptomsList.isEmpty) {
        return {
          'disease': 'Unknown',
          'risk': 'LOW',
          'confidence': 0.0,
          'details': 'Please select at least one symptom.'
        };
      }

      // Get diseases for this animal type
      final diseases = _metadata['diseases'][animalType] as List<dynamic>;
      var diseasePredictions = <Map<String, dynamic>>[];

      // Calculate match score for each disease
      for (var disease in diseases) {
        final diseaseSymptoms = disease['symptoms'] as List<dynamic>;
        final matchedSymptoms = selectedSymptomsList
            .where((symptom) => diseaseSymptoms.contains(symptom))
            .toList();

        // Calculate different scores
        final matchScore = matchedSymptoms.length / diseaseSymptoms.length;
        final coverageScore =
            matchedSymptoms.length / selectedSymptomsList.length;

        // Combined score gives weight to both matching disease symptoms and covering selected symptoms
        final combinedScore = (matchScore * 0.7) + (coverageScore * 0.3);

        if (matchedSymptoms.isNotEmpty) {
          diseasePredictions.add({
            'disease': disease,
            'matchedSymptoms': matchedSymptoms,
            'unmatchedSymptoms': selectedSymptomsList
                .where((s) => !matchedSymptoms.contains(s))
                .toList(),
            'matchScore': combinedScore,
            'coverage': coverageScore,
          });
        }
      }

      // Sort by combined match score in descending order
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
${selectedSymptomsList.map((s) => '- ${s.replaceAll('_', ' ').toUpperCase()}').join('\n')}

Possible Conditions:
${topPredictions.map((pred) {
        final disease = pred['disease'];
        final matchedSymps = pred['matchedSymptoms'] as List<String>;
        final unmatchedSymps = pred['unmatchedSymptoms'] as List<String>;
        return '''
${disease['name']} (${disease['risk']})
Matching Symptoms:
${matchedSymps.map((s) => '  - ${s.replaceAll('_', ' ').toUpperCase()}').join('\n')}
${unmatchedSymps.isNotEmpty ? '\nUnmatched Symptoms:\n${unmatchedSymps.map((s) => '  - ${s.replaceAll('_', ' ').toUpperCase()}').join('\n')}' : ''}
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
