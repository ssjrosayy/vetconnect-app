import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../ml/skin_disease_detector.dart';

class SkinDiseaseScreen extends StatefulWidget {
  const SkinDiseaseScreen({Key? key}) : super(key: key);

  @override
  State<SkinDiseaseScreen> createState() => _SkinDiseaseScreenState();
}

class _SkinDiseaseScreenState extends State<SkinDiseaseScreen> {
  File? _image;
  String _result = '';
  final _skinDiseaseDetector = SkinDiseaseDetector();
  String _selectedAnimal = 'dog';
  bool _isAnalyzing = false;

  final List<String> _animals = ['dog', 'cat', 'cattle'];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null) return;

      setState(() {
        _image = File(image.path);
        _result = '';
        _isAnalyzing = true;
      });

      // Analyze the image
      final result = await _skinDiseaseDetector.detectDisease(
        _image!,
        _selectedAnimal,
      );

      setState(() {
        _result = result;
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
          DropdownButton<String>(
            value: _selectedAnimal,
            items: _animals.map((String animal) {
              return DropdownMenuItem(
                value: animal,
                child: Text(animal.toUpperCase()),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedAnimal = newValue!;
                _result = '';
              });
            },
          ),
          const SizedBox(height: 20),
          if (_image != null) ...[
            Image.file(_image!),
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
          const SizedBox(height: 20),
          if (_isAnalyzing)
            const CircularProgressIndicator()
          else if (_result.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Diagnosis Result:',
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
