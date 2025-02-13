import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:convert';

class ModelManager {
  static final ModelManager _instance = ModelManager._internal();
  bool _initialized = false;
  late Map<String, dynamic> _breedMetadata;
  late Map<String, dynamic> _skinDiseaseMetadata;
  late Map<String, dynamic> _symptomsMetadata;

  late Interpreter _breedModel;
  late Interpreter _skinDiseaseModel;
  Map<String, Interpreter> _symptomModels = {};

  factory ModelManager() {
    return _instance;
  }

  ModelManager._internal();

  bool get isInitialized => _initialized;

  Future<void> initializeModels() async {
    if (_initialized) {
      print('ModelManager already initialized');
      return;
    }

    try {
      print('Starting ModelManager initialization...');

      // Load breed model first
      print('Loading breed detection model...');
      try {
        final interpreterOptions = InterpreterOptions()..threads = 4;
        _breedModel = await Interpreter.fromAsset(
          'assets/models/breed_model.tflite',
          options: interpreterOptions,
        );
        print('✓ Breed model loaded successfully');
      } catch (e) {
        print('❌ Error loading breed model: $e');
        rethrow;
      }

      // Load breed metadata
      print('Loading breed metadata...');
      try {
        final String jsonString =
            await rootBundle.loadString('assets/models/breed_metadata.json');
        _breedMetadata = json.decode(jsonString);
        print('✓ Breed metadata loaded successfully');
      } catch (e) {
        print('❌ Error loading breed metadata: $e');
        rethrow;
      }

      // Load skin disease model
      print('Loading skin disease model...');
      try {
        final interpreterOptions = InterpreterOptions()..threads = 4;
        _skinDiseaseModel = await Interpreter.fromAsset(
          'assets/models/skin_disease_model.tflite',
          options: interpreterOptions,
        );
        print('✓ Skin disease model loaded successfully');
      } catch (e) {
        print('❌ Error loading skin disease model: $e');
        rethrow;
      }

      // Load skin disease metadata
      print('Loading skin disease metadata...');
      try {
        _skinDiseaseMetadata = json.decode(await rootBundle
            .loadString('assets/models/skin_disease_metadata.json'));
        print('✓ Skin disease metadata loaded successfully');
      } catch (e) {
        print('❌ Error loading skin disease metadata: $e');
        rethrow;
      }

      // Load symptoms metadata
      print('Loading symptoms metadata...');
      try {
        _symptomsMetadata = json.decode(await rootBundle
            .loadString('assets/models/symptoms_metadata.json'));
        print('✓ Symptoms metadata loaded successfully');
      } catch (e) {
        print('❌ Error loading symptoms metadata: $e');
        rethrow;
      }

      // Load symptom models for each animal type
      print('Loading symptom models...');
      try {
        for (String animal in ['dog', 'cat']) {
          final interpreterOptions = InterpreterOptions()..threads = 4;
          _symptomModels[animal] = await Interpreter.fromAsset(
            'assets/models/symptoms_${animal}_model.tflite',
            options: interpreterOptions,
          );
          print('✓ ${animal.toUpperCase()} symptom model loaded successfully');
        }
      } catch (e) {
        print('❌ Error loading symptom models: $e');
        rethrow;
      }

      _initialized = true;
      print('✓ ModelManager initialization completed successfully');
    } catch (e, stackTrace) {
      print('❌ Error initializing ModelManager: $e');
      print('Stack trace: $stackTrace');
      _initialized = false;
      throw Exception('Failed to initialize ML models: $e');
    }
  }

  Interpreter get breedModel {
    if (!_initialized) throw Exception('ModelManager not initialized');
    return _breedModel;
  }

  Interpreter get skinDiseaseModel {
    if (!_initialized) throw Exception('ModelManager not initialized');
    return _skinDiseaseModel;
  }

  Interpreter getSymptomModel(String animalType) {
    if (!_initialized) throw Exception('ModelManager not initialized');
    if (!_symptomModels.containsKey(animalType)) {
      throw Exception('No symptom model found for $animalType');
    }
    return _symptomModels[animalType]!;
  }

  Map<String, dynamic> get breedMetadata {
    if (!_initialized) throw Exception('ModelManager not initialized');
    return _breedMetadata;
  }

  Map<String, dynamic> get skinDiseaseMetadata {
    if (!_initialized) throw Exception('ModelManager not initialized');
    return _skinDiseaseMetadata;
  }

  Map<String, dynamic> get symptomsMetadata {
    if (!_initialized) throw Exception('ModelManager not initialized');
    return _symptomsMetadata;
  }

  void dispose() {
    if (_initialized) {
      _breedModel.close();
      _skinDiseaseModel.close();
      _symptomModels.values.forEach((model) => model.close());
      _initialized = false;
    }
  }
}
