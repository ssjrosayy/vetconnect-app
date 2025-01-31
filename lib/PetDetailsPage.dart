
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class PetDetailsPage extends StatefulWidget {
  final Map<String, String> pet;
  final void Function(Map<String, String> pet) onSave;

  const PetDetailsPage({super.key, required this.pet, required this.onSave});

  @override
  _PetDetailsPageState createState() => _PetDetailsPageState();
}

class _PetDetailsPageState extends State<PetDetailsPage> {
  File? _image;
  final picker = ImagePicker();
  final _petDetailFormKey = GlobalKey<FormState>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();
  final _breedController = TextEditingController();

  String _category = 'Cat';
  String _gender = 'Male';
  String _weightUnit = 'kg';
  bool _isOtherCategory = false;
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    if (widget.pet['imagePath'] != null &&
        widget.pet['imagePath']!.isNotEmpty) {
      _image = File(widget.pet['imagePath']!);
    }
    _nameController.text = widget.pet['name'] ?? '';
    _category = widget.pet['type'] ?? 'Cat';
    _ageController.text = widget.pet['age'] ?? '';
    _gender = widget.pet['gender'] ?? 'Male';
    _weightController.text = widget.pet['weight'] ?? '';
    _weightUnit = widget.pet['weightUnit'] ?? 'kg';
    _colorController.text = widget.pet['color'] ?? '';
    _breedController.text = widget.pet['breed'] ?? '';
    _isOtherCategory = _category == 'Other';
    if (_isOtherCategory) {
      _typeController.text = widget.pet['type'] ?? '';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _savePet() async {
    if (_petDetailFormKey.currentState!.validate()) {
      // Get the current user's UID
      final User? user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save pet details.')),
        );
        return;
      }

      // Upload the image to Firebase Storage
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image.')),
        );
        return;
      }

      try {
        firebase_storage.Reference ref =
            firebase_storage.FirebaseStorage.instance.ref('/petImages/${DateTime.now().microsecondsSinceEpoch}');
        firebase_storage.UploadTask uploadTask = ref.putFile(_image!.absolute);
        await Future.value(uploadTask);
        String imageUrl = await ref.getDownloadURL();

        // Save the pet details to Firestore
        final String id = DateTime.now().microsecondsSinceEpoch.toString();
        await firestore.collection('pets').doc(id).set(
          {
            'uid': user.uid, // Store the user's UID
            'petName': _nameController.text,
            'petCategory': _isOtherCategory ? _typeController.text : _category,
            'petAge': _ageController.text,
            'petGender': _gender,
            'petWeight': _weightController.text,
            'petWeightUnit': _weightUnit,
            'petColor': _colorController.text,
            'petBreed': _breedController.text,
            'imagePath': imageUrl,
            'id': id,
          },
        );

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added New Pet')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving pet: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePet,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _petDetailFormKey,
          child: ListView(
            children: [
              if (_image != null) Image.file(_image!),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    child: const Icon(Icons.photo_library),
                  ),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    child: const Icon(Icons.camera_alt),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: <String>['Cat', 'Dog', 'Bird', 'Other']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _category = newValue!;
                    _isOtherCategory = _category == 'Other';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              if (_isOtherCategory)
                TextFormField(
                  controller: _typeController,
                  decoration: const InputDecoration(labelText: 'Specify Category'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please specify the category';
                    }
                    return null;
                  },
                ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an age';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: <String>['Male', 'Female']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _gender = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a gender';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Weight'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a weight';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _weightUnit,
                decoration: const InputDecoration(labelText: 'Weight Unit'),
                items: <String>['kg', 'lbs']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _weightUnit = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a weight unit';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a color';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(labelText: 'Breed'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a breed';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _savePet,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
