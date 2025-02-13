import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../ml/breed_detector.dart';
import 'dart:async';

class BreedDetectionScreen extends StatefulWidget {
  const BreedDetectionScreen({Key? key}) : super(key: key);

  @override
  State<BreedDetectionScreen> createState() => _BreedDetectionScreenState();
}

class _BreedDetectionScreenState extends State<BreedDetectionScreen> {
  File? _image;
  String _result = '';
  final _breedDetector = BreedDetector();
  String _selectedAnimal = 'dog';
  bool _isAnalyzing = false;
  bool _isInitialized = false;
  bool _isInitializing = true;

  final List<String> _animals = ['dog', 'cat', 'cattle'];

  @override
  void initState() {
    super.initState();
    _initializeDetector();
  }

  Future<void> _initializeDetector() async {
    try {
      final stopwatch = Stopwatch()..start();
      await _breedDetector.initialize();
      print(
          'Breed detector initialization took: ${stopwatch.elapsed.inMilliseconds}ms');
      setState(() {
        _isInitialized = true;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error initializing detector: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!_isInitialized) {
      setState(() {
        _result = 'Please wait for detector to initialize';
      });
      return;
    }

    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 100,
      );

      if (image == null) return;

      setState(() {
        _image = File(image.path);
        _result = '';
        _isAnalyzing = true;
      });

      final result = await _breedDetector.detectBreed(_image!);

      setState(() {
        _result = 'Primary breed: ${result['primary_prediction']['breed']}\n'
            'Confidence: ${(result['primary_prediction']['confidence'] * 100).toStringAsFixed(1)}%';
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_isInitializing)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing breed detector...'),
                ],
              ),
            ),
          DropdownButton<String>(
            value: _selectedAnimal,
            items: _animals.map((String animal) {
              return DropdownMenuItem(
                value: animal,
                child: Text(animal.toUpperCase()),
              );
            }).toList(),
            onChanged: _isInitializing
                ? null
                : (String? newValue) {
                    setState(() {
                      _selectedAnimal = newValue!;
                      _result = '';
                    });
                  },
          ),
          const SizedBox(height: 20),
          if (_image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                _image!,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ],
          ),
          if (_isAnalyzing)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            )
          else if (_result.isNotEmpty)
            Card(
              margin: const EdgeInsets.only(top: 20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Analysis Result:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_result),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
