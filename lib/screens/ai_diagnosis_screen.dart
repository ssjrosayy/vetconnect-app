import 'package:flutter/material.dart';
import '../ml/model_manager.dart';

import 'package:image_picker/image_picker.dart';

import 'breed_detection_screen.dart';
import 'skin_disease_screen.dart';
import 'symptom_analyzer_screen.dart';

class AIDiagnosisScreen extends StatefulWidget {
  const AIDiagnosisScreen({Key? key}) : super(key: key);

  @override
  State<AIDiagnosisScreen> createState() => _AIDiagnosisScreenState();
}

class _AIDiagnosisScreenState extends State<AIDiagnosisScreen> {
  final ModelManager _modelManager = ModelManager();
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeModels();
  }

  Future<void> _initializeModels() async {
    try {
      await _modelManager.initializeModels();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize AI models: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(child: Text(_errorMessage)),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI Pet Diagnosis'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Skin Disease'),
              Tab(text: 'Symptom Analysis'),
              Tab(text: 'Breed Detection'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SkinDiseaseScreen(),
            SymptomAnalyzerScreen(),
            BreedDetectionScreen(),
          ],
        ),
      ),
    );
  }
}
