import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class EditPetDetailsScreen extends StatefulWidget {
  final String imageUrl;
  final String petName;
  final String petCategory;
  final String petAge;
  final String petGender;
  final String petWeight;
  final String petWeightUnit;
  final String petColor;
  final String petBreed;
  final String id;

  const EditPetDetailsScreen({super.key, 
    required this.imageUrl,
    required this.petName,
    required this.petCategory,
    required this.petAge,
    required this.petGender,
    required this.petWeight,
    required this.petWeightUnit,
    required this.petColor,
    required this.petBreed,
    required this.id,
  });

  @override
  _EditPetDetailsScreenState createState() => _EditPetDetailsScreenState();
}

class _EditPetDetailsScreenState extends State<EditPetDetailsScreen> {
  File? _image;
  final picker = ImagePicker();
  final _petEditDetailFormKey = GlobalKey<FormState>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
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

    _nameController.text = widget.petName;
    _category = widget.petCategory;
    _ageController.text = widget.petAge;
    _gender = widget.petGender;
    _weightController.text = widget.petWeight;
    _weightUnit = widget.petWeightUnit;
    _colorController.text = widget.petColor;
    _breedController.text = widget.petBreed;
    _isOtherCategory = true;
    if (_isOtherCategory) {
      _typeController.text = widget.petCategory;
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
        title: const Text('Pet Edit Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _petEditDetailFormKey,
          child: ListView(
            children: [
              if (widget.imageUrl != '' && _image == null)
                Image.network(widget.imageUrl),
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
                onPressed: () async {
                  if (_petEditDetailFormKey.currentState!.validate()) {
                    if (_image == null) {
                      await firestore.collection('pets').doc(widget.id).update(
                        {
                          'petName': _nameController.text,
                          'petCategory': _isOtherCategory
                              ? _typeController.text
                              : _category,
                          'petAge': _ageController.text,
                          'petGender': _gender,
                          'petWeight': _weightController.text,
                          'petWeightUnit': _weightUnit,
                          'petColor': _colorController.text,
                          'petBreed': _breedController.text,
                        },
                      ).then((value) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Updated Pet',
                            ),
                          ),
                        );
                      }).onError((error, stackTrace) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                            error.toString(),
                          )),
                        );
                      });
                    } else {
                      firebase_storage.Reference ref = firebase_storage
                          .FirebaseStorage.instance
                          .ref('/petImage');
                      firebase_storage.UploadTask uploadTask =
                          ref.putFile(_image!.absolute);
                      await Future.value(uploadTask).then((value) async {
                        var newUrl = await ref.getDownloadURL();
                        await firestore
                            .collection('pets')
                            .doc(widget.id)
                            .update(
                          {
                            'petName': _nameController.text,
                            'petCategory': _isOtherCategory
                                ? _typeController.text
                                : _category,
                            'petAge': _ageController.text,
                            'petGender': _gender,
                            'petWeight': _weightController.text,
                            'petWeightUnit': _weightUnit,
                            'petColor': _colorController.text,
                            'petBreed': _breedController.text,
                            'imagePath': newUrl,
                          },
                        ).then((value) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Updated Pet',
                              ),
                            ),
                          );
                        }).onError((error, stackTrace) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error.toString(),
                              ),
                            ),
                          );
                        });
                      });
                    }
                  }
                },
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
